import 'package:flutter/material.dart';
import 'package:kawaii_lang/l10n/app_localizations.dart';
import 'package:kawaii_lang/services/character_asset_service.dart';

class TsumugiWelcomeDialog extends StatelessWidget {
  final VoidCallback onStart;
  final VoidCallback onWhoIs;
  final VoidCallback onLater;
  final String character;

  const TsumugiWelcomeDialog({
    super.key,
    required this.onStart,
    required this.onWhoIs,
    required this.onLater,
    this.character = CharacterAssetService.defaultCharacter,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isKasumi = character == CharacterAssetService.kasumi;
    final title = isKasumi ? loc.kasumiIntroTitle : loc.tsumugiIntroTitle;
    final body = isKasumi ? loc.kasumiIntroBody : loc.tsumugiIntroBody;
    final whoIsLabel = isKasumi ? loc.kasumiIntroWhoIsButton : loc.tsumugiIntroWhoIsButton;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.5,
                    color: Color(0xFF334155),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onStart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFC5B7D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    loc.tsumugiIntroStartButton,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: onWhoIs,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF374151),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    whoIsLabel,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onLater,
                  child: Text(loc.tsumugiIntroLaterButton),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
