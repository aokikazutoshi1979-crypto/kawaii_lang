// keyboard_guide_button.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kawaii_lang/l10n/app_localizations.dart';
import 'keyboard_guide_modal.dart';
import '../utils/lang_utils.dart';

class KeyboardGuideButton extends StatefulWidget {
  final String targetLanguage;
  final bool alwaysVisible; // 設定画面用に常時表示するかどうか

  const KeyboardGuideButton({
    Key? key,
    required this.targetLanguage,
    this.alwaysVisible = false,
  }) : super(key: key);

  @override
  _KeyboardGuideButtonState createState() => _KeyboardGuideButtonState();
}

class _KeyboardGuideButtonState extends State<KeyboardGuideButton> {
  bool _shouldShow = true;

  @override
  void initState() {
    super.initState();
    if (!widget.alwaysVisible) _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getBool('keyboardGuideShown') ?? false;
    if (shown) {
      setState(() => _shouldShow = false);
    }
  }

  Future<void> _handleTap(BuildContext context) async {
    KeyboardGuideModal.show(context, language: widget.targetLanguage);

    if (!widget.alwaysVisible) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('keyboardGuideShown', true);
      setState(() => _shouldShow = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    if (!_shouldShow && !widget.alwaysVisible) return SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextButton(
        onPressed: () => _handleTap(context),
        child: Text(
          AppLocalizations.of(context)!
              .keyboardGuideButton
              .replaceAll('〇〇', getLangLabel(widget.targetLanguage)),
          style: const TextStyle(color: Colors.blue),
        ),
      ),
    );
  }
}
