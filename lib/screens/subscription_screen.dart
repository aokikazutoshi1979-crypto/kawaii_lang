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
  Package? package; // ←ここでフィールドを用意
  bool _isPurchasing = false;

  @override
  void initState() {
    super.initState();
    SubscriptionService.instance.subscriptionActiveNotifier.addListener(
      _handleSubscriptionStateChanged,
    );
    _loadOfferings();
  }

  @override
  void dispose() {
    SubscriptionService.instance.subscriptionActiveNotifier.removeListener(
      _handleSubscriptionStateChanged,
    );
    super.dispose();
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

  String _planName(AppLocalizations loc, Package? pkg) {
    return loc.basicPlan;
  }

  String _mainCtaText(AppLocalizations loc) => loc.trialStartButton;

  String _trialCopy(AppLocalizations loc) => loc.trialCopyText;

  List<String> _benefits(AppLocalizations loc) => [
        loc.subscriptionBenefitAllCategories,
        loc.subscriptionBenefitUnlimited,
        loc.benefitNoCreditCard,
        loc.subscriptionBenefitCancelAnytime,
        loc.benefitRenewalNotice,
        loc.benefitAppleRefund,
      ];

  String _iosCancelGuide(AppLocalizations loc) => loc.iosCancelGuideText;

  void _handleSubscriptionStateChanged() {
    if (!mounted) return;
    final active =
        SubscriptionService.instance.subscriptionActiveNotifier.value;
    if (hasSubOnDevice == active && !(_isPurchasing && active)) return;
    setState(() {
      hasSubOnDevice = active;
      if (active) {
        _isPurchasing = false;
      }
    });
  }

  Future<void> _retrySubscriptionRefreshAfterPurchase() async {
    const maxAttempts = 5;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      await refreshSubscriptionStatus();
      if (!mounted) return;
      if (hasSubOnDevice ||
          SubscriptionService.instance.subscriptionActiveNotifier.value) {
        return;
      }
      if (attempt < maxAttempts - 1) {
        await Future.delayed(const Duration(seconds: 1));
      }
    }
  }

  Future<void> _purchase(Package pkg) async {
    if (_isPurchasing) return;
    final wasSubscribed = hasSubOnDevice ||
        SubscriptionService.instance.subscriptionActiveNotifier.value;
    setState(() => _isPurchasing = true);
    try {
      final purchased = await SubscriptionService.instance.purchasePackage(pkg);
      if (!purchased) {
        if (!mounted) return;
        setState(() => _isPurchasing = false);
        return;
      }
      await _retrySubscriptionRefreshAfterPurchase();
      if (!mounted) return;
      final isNowSubscribed = hasSubOnDevice ||
          SubscriptionService.instance.subscriptionActiveNotifier.value;
      setState(() => _isPurchasing = false);
      if (!wasSubscribed && isNowSubscribed) {
        final loc = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.subscriptionActivated)),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isPurchasing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchase failed. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final bool hasSub = hasSubOnDevice ||
        SubscriptionService.instance.subscriptionActiveNotifier.value;

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

    final priceText = pkg == null
        ? (loc.localeName.startsWith('ja') ? '価格を読み込み中...' : 'Loading price...')
        : '${pkg.storeProduct.priceString}${loc.subscriptionPriceTaxSuffix}';

    final planName = _planName(loc, pkg);
    final benefits = _benefits(loc);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F8),
      appBar: AppBar(title: Text(loc.subscriptionTitle)),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontal = constraints.maxWidth >= 520 ? 24.0 : 14.0;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 24),
                  children: [
                    Card(
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 46,
                                  height: 46,
                                  child: Image.asset(
                                    'assets/images/icon/basic_plan002.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    planName,
                                    style: const TextStyle(
                                      fontSize: 21,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              priceText,
                              style: const TextStyle(
                                fontSize: 27,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _trialCopy(loc),
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF334155),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 14),
                            ...benefits.map(
                              (line) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      size: 18,
                                      color: Color(0xFF16A34A),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        line,
                                        style: const TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1F2937),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (!hasSub)
                      Card(
                        elevation: 0,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ElevatedButton(
                                onPressed: (pkg == null || _isPurchasing)
                                    ? null
                                    : () => _purchase(pkg),
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  backgroundColor: const Color(0xFFFC5B7D),
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  _isPurchasing
                                      ? loc.restoringPurchase
                                      : _mainCtaText(loc),
                                  style: TextStyle(
                                    fontSize: _isPurchasing ? 14.5 : 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              if (_isPurchasing) ...[
                                const SizedBox(height: 8),
                                const Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    if (hasSub) ...[
                      Card(
                        elevation: 0,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                loc.subscriptionCurrentStatusTitle,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                loc.subscriptionStatus,
                                style: const TextStyle(
                                  color: Color(0xFF334155),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () => _launchUrl(_manageUrl),
                                child: Text(loc.subscriptionManageButton),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Card(
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: RestorePurchaseSection(
                          onRestored: () async {
                            await refreshSubscriptionStatus();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          TextButton(
                            onPressed: () => _launchUrl(_eulaUrl),
                            child: Text(loc.viewTerms),
                          ),
                          TextButton(
                            onPressed: () => _launchUrl(_privacyUrl),
                            child: Text(loc.viewPrivacyPolicy),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                            child: Text(
                              _iosCancelGuide(loc),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
