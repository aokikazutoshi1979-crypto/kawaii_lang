import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'package:kawaii_lang/services/subscription_state.dart';
import 'package:kawaii_lang/services/device_service.dart';

/// サブスクリプション機能全般を管理するサービスクラス
class SubscriptionService {
  SubscriptionService._();
  static final SubscriptionService instance = SubscriptionService._();

  /// 他端末ログイン判定結果
  bool isSessionMismatch = false;

  /// 初期化が走っている/完了したことを保証する “門番”
  Future<void>? _initFuture;
  String? _initializedUid;
  bool _isConfigured = false;

  /// 直近の CustomerInfo
  CustomerInfo? _customerInfo;

  /// あなたの有効化 Entitlement ID（必要に応じて合わせてください）
  static const String entitlementId = 'KawaiiLang_Subscription';

  // --------------------------
  // 初期化（必ず一度だけ）
  // --------------------------
  Future<void> init() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      // 未ログイン時に完了済み future を固定しない（後続で再初期化できるようにする）
      _initFuture = null;
      _initializedUid = null;
      isSessionMismatch = false;
      return Future.value();
    }

    if (_initFuture == null || _initializedUid != uid) {
      _initializedUid = uid;
      _initFuture = _initImpl(uid).catchError((Object e, StackTrace st) {
        // 初期化失敗時は次回リトライ可能にする
        _initFuture = null;
        _initializedUid = null;
        throw e;
      });
    }
    return _initFuture!;
  }

  Future<void> _initImpl(String uid) async {
    // 毎回再評価前に false に戻す（一度 true になったまま残る誤検知を防ぐ）
    isSessionMismatch = false;
    // 1) 端末ミスマッチ判定（今のロジックを活かす）
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get(const GetOptions(source: Source.server));

      final data = doc.data();
      final storedDeviceId = (data?['lastLoginDeviceId'] as String?)?.trim() ?? '';
      final currentDeviceId = (await DeviceService.getDeviceId()).trim();

      // 端末IDが空文字の場合は「未確定データ」とみなして不一致判定しない
      if (storedDeviceId.isNotEmpty &&
          currentDeviceId.isNotEmpty &&
          storedDeviceId != currentDeviceId) {
        isSessionMismatch = true;
        return; // 以降スキップ
      }

      // 初回などでFirestore側が未設定なら、現在端末IDで補完して誤検知を防ぐ
      if (storedDeviceId.isEmpty && currentDeviceId.isNotEmpty) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'lastLoginDeviceId': currentDeviceId,
          'lastLoginAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e, st) {
      FirebaseCrashlytics.instance
          .recordError(e, st, reason: 'Device mismatch check failed');
      // 失敗しても初期化自体は続ける
      isSessionMismatch = false;
    }

    // 2) RevenueCat 構成
    try {
      await Purchases.setLogLevel(LogLevel.debug); // 9系のログ設定

      final cfg = PurchasesConfiguration('appl_dEZMvMgsqmnwhWGCcICYJlBjgwe');
      // ※ 9系では observerMode / usesStoreKit2IfAvailable の setter はありません。
      //   - observerMode=false（＝購入をSDKが完了） はデフォルト
      //   - StoreKit2 は自動選択（必要なら下の1行を使って明示的に指定）

      // もし StoreKit を明示したい場合（SDKが対応しているときのみ有効）
      // cfg.storeKitVersion = StoreKitVersion.automatic;   // 既定
      // cfg.storeKitVersion = StoreKitVersion.storeKit1;   // SK1 を強制
      // cfg.storeKitVersion = StoreKitVersion.storeKit2;   // SK2 を強制

      await Purchases.configure(cfg);
      _isConfigured = true;

      Purchases.addCustomerInfoUpdateListener(_onCustomerInfo);

      try {
        final info = await Purchases.getCustomerInfo();
        _onCustomerInfo(info);
      } catch (e, st) {
        FirebaseCrashlytics.instance
            .recordError(e, st, reason: 'getCustomerInfo (first)');
      }
    } catch (e, st) {
      _isConfigured = false;
      FirebaseCrashlytics.instance
          .recordError(e, st, reason: 'Purchases.configure failed');
      rethrow;
    }
  }

  // --------------------------
  // リスナー（Firestore 反映も安全化）
  // --------------------------
  Future<void> _onCustomerInfo(CustomerInfo info) async {
    _customerInfo = info;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final historyRef = userRef.collection('subscriptionHistory');
    final now = FieldValue.serverTimestamp();

    final entMap = info.entitlements.active;
    final hasActive = entMap.isNotEmpty;
    final entitlement = hasActive ? entMap.values.first : null;

    DateTime? purchaseDate;
    DateTime? expirationDate;

    if (entitlement != null) {
      try {
        purchaseDate = DateTime.tryParse(entitlement.originalPurchaseDate?.toString() ?? '');
      } catch (_) {}
      try {
        expirationDate = DateTime.tryParse(entitlement.expirationDate?.toString() ?? '');
      } catch (_) {}
    }

    try {
      await userRef.set({
        'hasSubscription': hasActive,
        'subscriptionPlan': entitlement?.productIdentifier ?? '',
        'purchasedAt': purchaseDate != null ? Timestamp.fromDate(purchaseDate) : null,
        'expirationDate': expirationDate != null ? Timestamp.fromDate(expirationDate) : null,
        'latestSessionId': info.originalAppUserId,
        'updatedAt': now,
      }, SetOptions(merge: true));

      await historyRef.add({
        'event': hasActive ? 'purchaseOrRenewal' : 'expired',
        'planId': entitlement?.productIdentifier,
        'purchaseDate': purchaseDate,
        'expirationDate': expirationDate,
        'timestamp': now,
      });
    } catch (e, st) {
      // Firestore 失敗は致命ではない
      FirebaseCrashlytics.instance
          .recordError(e, st, reason: 'Firestore write (customer info)');
    }

    debugPrint('▶️ サブスク更新: active=$hasActive, plan=${entitlement?.productIdentifier}');
  }

  // --------------------------
  // ユーティリティ（常に初期化を待つ）
  // --------------------------
  Future<CustomerInfo?> _safeCustomerInfo() async {
    await init();
    if (!_isConfigured) return null;
    try {
      return await Purchases.getCustomerInfo();
    } catch (e, st) {
      FirebaseCrashlytics.instance
          .recordError(e, st, reason: 'getCustomerInfo');
      return null;
    }
  }

  Future<bool> checkSubscriptionOnDevice() async {
    final info = await _safeCustomerInfo();
    if (info == null) return false;

    final raw = info.entitlements.active[entitlementId]?.expirationDate;
    if (raw == null) return false;

    final exp = DateTime.tryParse(raw.toString());
    if (exp == null) return false;

    return exp.isAfter(DateTime.now());
  }

  // --------------------------
  // 購入/復元/オファリング
  // --------------------------
  Future<void> purchasePackage(Package package) async {
    await init();
    if (!_isConfigured) return;

    try {
      await Purchases.purchasePackage(package);
    } on PlatformException catch (e, st) {
      // キャンセル等のコードを取り出して分岐
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) return;
      FirebaseCrashlytics.instance
          .recordError(e, st, reason: 'purchasePackage platform error');
      rethrow;
    } catch (e, st) {
      FirebaseCrashlytics.instance
          .recordError(e, st, reason: 'purchasePackage unknown error');
      rethrow;
    }

    // 直後の最新情報反映（例外は握りつぶし）
    try {
      final info = await Purchases.getCustomerInfo();
      await _onCustomerInfo(info);
    } catch (e, st) {
      FirebaseCrashlytics.instance
          .recordError(e, st, reason: 'post-purchase getCustomerInfo');
    }
  }

  Future<void> restorePurchases() async {
    await init();
    if (!_isConfigured) return;

    try {
      final info = await Purchases.restorePurchases();
      await _onCustomerInfo(info);
    } catch (e, st) {
      FirebaseCrashlytics.instance
          .recordError(e, st, reason: 'restorePurchases');
      rethrow;
    }
  }

  Future<Offerings?> getOfferings() async {
    await init();
    if (!_isConfigured) return null;

    try {
      return await Purchases.getOfferings();
    } catch (e, st) {
      FirebaseCrashlytics.instance
          .recordError(e, st, reason: 'getOfferings');
      return null;
    }
  }
}
