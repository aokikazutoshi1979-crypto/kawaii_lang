import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;
  final FirebaseFirestore _fs = FirebaseFirestore.instance;

  /// 🔹 新規ユーザー作成
  Future<void> createUser(UserModel user) =>
      _db.collection('users').doc(user.uid).set(user.toMap());

  /// 🔹 Firestore からユーザーモデル取得
  Future<UserModel?> getUser(String uid) async {
    final snap = await _db.collection('users').doc(uid).get();
    if (!snap.exists) return null;
    return UserModel.fromMap(snap.data()!);
  }

  /// 🔹 Firestore からユーザーの生データ（Map）を取得
  Future<Map<String, dynamic>?> getUserDoc(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists ? doc.data() : null;
  }

  /// 🔹 Firestore にユーザーセッションを保存
  Future<void> updateUserSession(String uid, String sessionId) async {
    await _db.collection('users').doc(uid).set({
      'latestSessionId': sessionId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 🆕 🔹 任意のフィールドをFirestoreに上書き保存（マージ形式）
  Future<void> updateUserFields(String uid, Map<String, dynamic> fields) async {
    await _db.collection('users').doc(uid).set(fields, SetOptions(merge: true));
  }

  /// ユーザードキュメントのみを削除
  Future<void> deleteUserDoc(String uid) {
    return _fs.collection('users').doc(uid).delete();
  }

  /// history サブコレクションも含めて完全削除したい場合
  Future<void> deleteAllUserData(String uid) async {
    // 1) history 一括取得
    final histCol = _fs.collection('users').doc(uid).collection('history');
    final snaps = await histCol.get();

    // 2) バッチで history を削除
    final batch = _fs.batch();
    for (var doc in snaps.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    // 3) 親ドキュメントを削除
    await deleteUserDoc(uid);
  }
}
