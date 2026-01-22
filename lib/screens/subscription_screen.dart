import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kawaii_lang/services/subscription_service.dart';
import 'package:kawaii_lang/l10n/app_localizations.dart';
import '../widgets/restore_purchase_section.dart';
import '../services/subscription_state.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  _SubscriptionScreenState createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends SubscriptionState<SubscriptionScreen> {
  // Apple サブスクリ管理画面の URL
  static const _manageUrl = 'https://apps.apple.com/account/subscriptions';

  // 各種URL
  final String _eulaUrl = 'https://kawaiilang.com/terms.html';
  final String _privacyUrl = 'https://kawaiilang.com/privacy.html';

  Offerings? offerings;
  Package? package;  // ←ここでフィールドを用意

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    offerings = await SubscriptionService.instance.getOfferings();
    // シングルトンから取ってきた Offerings を元に package をセット
    package = offerings?.current?.monthly;
    setState(() {});
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open URL: $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final bool hasSub = hasSubOnDevice;

    // ←ここで「サービスのプロパティ」ではなく「Stateのフィールド」を使う
    final pkg = offerings?.current?.monthly;

    // ▼ 追加：表示＆ログ出力用のデバッグ文字列
    final String rcDebugLine = (pkg != null)
        ? 'pkg id=${pkg.storeProduct.identifier} '
          'price=${pkg.storeProduct.price} '
          'priceString=${pkg.storeProduct.priceString} '
          'currency=${pkg.storeProduct.currencyCode}'
        : 'pkg: null (Offerings 未取得 or 月額プランなし)';

    // コンソールにも出す
    debugPrint('[RevenueCat] $rcDebugLine');

    return Scaffold(
      appBar: AppBar(title: Text(loc.subscriptionTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // プラン説明
          Text(
            loc.subscriptionPlanTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(loc.subscriptionPlanMonthly),
          Text(loc.subscriptionPlanPeriod),
          Text(loc.subscriptionPlanPrice),
          Text(loc.subscriptionPlanTrial),
          Text(loc.subscriptionStatusSubscribed),
          const SizedBox(height: 24),

          // ◆ 現在の加入状態表示
          Text(
            loc.subscriptionCurrentStatusTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            hasSub ? loc.subscriptionStatus : loc.subscriptionStatusTrial,
          ),
          const SizedBox(height: 24),
          
          // ◆ サブスク未加入かつ pkg があるときだけ購入タイルを表示
          if (!hasSub && pkg != null)
            ListTile(
              leading: SizedBox(
                width: 60,
                height: 60,
                child: Image.asset(
                  'assets/images/icon/basic_plan002.png',
                  fit: BoxFit.contain,
                ),
              ),
              title: Text(loc.subscribeNow),
              subtitle: Text(
                '${pkg.storeProduct.priceString}${loc.subscriptionPriceTaxSuffix}',
              ),
              trailing: ElevatedButton(
                onPressed: () async {
                  await SubscriptionService.instance.purchasePackage(pkg);
                  await refreshSubscriptionStatus();
                },
                child: Text(loc.subscribe),
              ),
            ),

          // 管理ボタン（加入済みの場合）
          if (hasSub)
            ElevatedButton(
              onPressed: () => _launchUrl(_manageUrl),
              child: Text(loc.subscriptionManageButton),
            ),

          // 利用規約 (EULA) へのリンク
          TextButton(
            onPressed: () => _launchUrl(_eulaUrl),
            child: Text(loc.viewTerms),
          ),

          // プライバシーポリシーへのリンク
          TextButton(
            onPressed: () => _launchUrl(_privacyUrl),
            child: Text(loc.viewPrivacyPolicy),
          ),

          const SizedBox(height: 12),
          Text(
            loc.subscriptionManageNote,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          // 復元ボタンは別コンポーネントで
          RestorePurchaseSection(onRestored: () async {
            await refreshSubscriptionStatus();
          }),
          const Divider(height: 32),
        ],
      ),
    );
  }
}
