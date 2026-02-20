import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/device_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _fs = FirebaseFirestore.instance;
  final FirestoreService _firestore = FirestoreService();

  Stream<User?> get authState => _auth.authStateChanges();

  /// 🔐 匿名ログイン（起動時に一度だけ呼ぶ）
  static Future<void> signInAnonymouslyIfNeeded({ bool force = false }) async {
    final auth = FirebaseAuth.instance;

    // ⚠️ テスト時だけ、端末に残る認証情報をクリア
    if (force || auth.currentUser == null) {
      // 既に currentUser がいるなら一度クリア
      if (auth.currentUser != null) {
        await auth.signOut();
      }
      // 匿名サインイン
      final cred = await auth.signInAnonymously();
      debugPrint('▶️ 匿名サインイン完了: uid= {cred.user?.uid}');
    } else {
      debugPrint('▶️ 既存ユーザー: uid= {auth.currentUser!.uid}');
    }

    // ② Firestore に自分のドキュメントを作成 or マージ
    final u = auth.currentUser!;
    final userRef = FirebaseFirestore.instance.collection('users').doc(u.uid);
    try {
      await userRef.set({
        'uid': u.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'hasSubscription': false,
      }, SetOptions(merge: true));
      debugPrint('▶️ Firestore ユーザードキュメント作成／更新完了');

      // ↓ ここから「端末ID」を書き込む ↓
      final deviceId = await DeviceService.getDeviceId();
      if (deviceId.trim().isNotEmpty) {
        await userRef.set({
          'lastLoginDeviceId': deviceId,
          'lastLoginAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('▶️ lastLoginDeviceId 書き込み完了: $deviceId');
      } else {
        debugPrint('⚠️ lastLoginDeviceId が空のため書き込みをスキップ');
      }
    } catch (e) {
      debugPrint('⚠️ Firestore 書き込み失敗: $e');
    }
  }

  /// メール／パスワード登録＋匿名アカウントの昇格＆Firestoreにマージ更新
  Future<UserCredential?> registerWithEmail(
    String email,
    String password,
  ) async {
    try {
      // 1) Firebase Authentication でメールアドレス登録（匿名ユーザーにリンク）
      final UserCredential cred = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      final user = cred.user;
      if (user == null) {
        debugPrint('🚨 登録失敗: user が null');
        return null;
      }

      // 2) Firestore に必要なフィールドだけマージ更新で追加
      await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

      return cred;
    } on FirebaseAuthException catch (e) {
      debugPrint('🚨 FirebaseAuth エラー: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('🚨 不明なエラー: $e');
      return null;
    }
  }

  /// 🔓 メールでログイン＋セッション保存
  Future<UserCredential?> loginWithEmail(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = cred.user;
      if (user != null) {
        final sessionId = const Uuid().v4();
        await _firestore.updateUserSession(user.uid, sessionId);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('sessionId', sessionId);

        // ↓ ここから追加 ↓
        final deviceId = await DeviceService.getDeviceId();
        if (deviceId.trim().isNotEmpty) {
          await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
              'lastLoginDeviceId': deviceId,
              'lastLoginAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
        }
        // ↑ ここまで追加 ↑
      }
      return cred;
    } catch (e) {
      print('ログインエラー: $e');
      return null;
    }
  }

  /// 匿名→メールパス昇格＋Firestoreに必要項目をマージ更新
  Future<UserCredential?> upgradeAnonymousToEmail(
    String email,
    String password,
  ) async {
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;
    if (user == null) {
      debugPrint('🚨 昇格失敗: 匿名ユーザーが存在しません');
      return null;
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    try {
      // ① まずは匿名アカウントにリンクを試みる
      final userCred = await user.linkWithCredential(credential);
      debugPrint('✅ 匿名→メール昇格(link) 成功: ${userCred.user!.uid}');

      // ② Firestore に４項目をマージ更新
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCred.user!.uid)
          .set({
            'uid': userCred.user!.uid,
            'email': email,
            'displayName': userCred.user!.displayName ?? '',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      return userCred;
    } on FirebaseAuthException catch (e) {
      // user-not-found はリンク失敗時のフェールバック処理
      if (e.code == 'user-not-found') {
        debugPrint('🔄 user-not-found なのでフェールバックで新規作成');
        // ① 新規メールユーザーを作成
        final newCred = await auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        final newUid = newCred.user!.uid;
        final oldUid = user.uid;

        // ② 古い匿名ユーザーのドキュメントをコピー（マージ）して、
        //    さらに昇格情報を追加
        final oldDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(oldUid)
            .get();
        if (oldDoc.exists) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(newUid)
              .set(oldDoc.data()!, SetOptions(merge: true));
        }
        // ③ 昇格後の共通フィールドをマージ更新
        await FirebaseFirestore.instance
            .collection('users')
            .doc(newUid)
            .set({
              'uid': newUid,
              'email': email,
              'displayName': newCred.user!.displayName ?? '',
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));

        // ④ 匿名ユーザーをサインアウト→新ユーザーでサインイン
        await auth.signOut();
        await auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        debugPrint('✅ フェールバックで昇格完了: $oldUid → $newUid');
        return newCred;
      }

      debugPrint('🚨 昇格失敗: code=${e.code} message=${e.message}');
      return null;
    } catch (e) {
      debugPrint('🔴 想定外エラー: $e');
      return null;
    }
  }

  /// 🚪 ログアウト
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// 👤 現在のユーザー取得
  User? get currentUser => _auth.currentUser;

  /// 🆔 現在のUID取得
  String? get currentUid => _auth.currentUser?.uid;

  /// 🔄 現在のユーザー情報を Firestore から読み込む
  Future<UserModel?> fetchCurrentUser() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Future.value(null);
    return _firestore.getUser(uid);
  }

  /// 🔐 課金状態をFirestoreに保存（true or false）
  Future<void> updateSubscriptionStatus(bool isSubscribed) async {
    final uid = currentUser?.uid;
    if (uid == null) return;

    await _firestore.updateUserFields(uid, {
      'hasSubscription': isSubscribed,
      'subscriptionPlan': isSubscribed ? 'starter' : null,
    });
  }

  /// 🔎 Firestore から課金ステータスを取得（true/false）
  Future<bool> checkSubscriptionStatus() async {
    final uid = currentUser?.uid;
    if (uid == null) return false;

    final doc = await _firestore.getUserDoc(uid);
    return doc?['hasSubscription'] == true;
  }

  /// 🔐 認証ユーザーのアカウントと Firestore データを削除
  Future<void> deleteUserAccount({
    required String password, // パスワード再入力用
  }) async {
    final user = _auth.currentUser!;
    // 1) 再認証
    final cred = EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );
    await user.reauthenticateWithCredential(cred);

    // 2) Firestore 側ドキュメント削除
    // → FirestoreService に集中させる場合はこちらを使う
    await _firestore.deleteUserDoc(user.uid);

    // 3) Auth アカウント削除
    await user.delete();
  }

  /// 匿名ユーザーのデータだけ初期化
  Future<void> resetAnonymousData() async {
    final user = _auth.currentUser!;
    // Firestore のドキュメントを削除
    await _firestore.deleteUserDoc(user.uid).catchError((_) {});
    // SharedPreferences もクリア
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    // 匿名で再ログイン
    await _auth.signInAnonymously();
  }
}
