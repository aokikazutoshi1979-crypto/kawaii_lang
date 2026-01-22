// subscription_state.dart
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'subscription_service.dart';

/// 画面ごとの State クラス継承用の抽象クラス
abstract class SubscriptionState<T extends StatefulWidget> extends State<T> {
  bool hasSubOnDevice = false;

  @override
  void initState() {
    super.initState();

    // ① サービスの init() で SDK 設定＋リスナー登録
    SubscriptionService.instance.init();

    // ② 画面のフラグを起動時に一度だけ取得
    refreshSubscriptionStatus();
  }

  /// 端末上のサブスク契約を問い合わせてフラグ更新
  Future<void> refreshSubscriptionStatus() async {
    final active =
      await SubscriptionService.instance.checkSubscriptionOnDevice();
    setState(() => hasSubOnDevice = active);
  }
}
