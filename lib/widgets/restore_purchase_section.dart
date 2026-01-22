// lib/widgets/restore_purchase_section.dart

import 'package:flutter/material.dart';
import 'package:kawaii_lang/l10n/app_localizations.dart';
import 'package:kawaii_lang/services/subscription_service.dart';

/// 親から onRestored を受け取り、
/// 押下後にそれを呼び出すようにする
class RestorePurchaseSection extends StatelessWidget {
  final Future<void> Function()? onRestored;

  const RestorePurchaseSection({Key? key, this.onRestored}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;  // now works because we imported it
    return ListTile(
      leading: const Icon(Icons.restore),
      title: Text(loc.restoreSubscription),
      onTap: () async {
        // 1) 実際の復元処理／Firestore更新
        await SubscriptionService.instance.restorePurchases();
        // 2) 親画面に「復元完了！」を通知してUIを更新
        if (onRestored != null) {
          await onRestored!();
        }
      },
    );
  }
}
