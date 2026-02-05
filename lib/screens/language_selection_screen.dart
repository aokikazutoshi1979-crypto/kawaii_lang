import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart'; // MyApp.setLocale を使うため
import 'package:kawaii_lang/l10n/app_localizations.dart';
import 'target_language_selection_screen.dart';

class LanguageSelectionScreen extends StatefulWidget {
  @override
  _LanguageSelectionScreenState createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String? selectedLang;

  final List<Map<String, String>> languages = [
    {'label': '日本語',                'code': 'ja'},
    {'label': 'English',              'code': 'en'},
    {'label': '中文(简化)',                  'code': 'zh'},
    {'label': '台灣(繁體)',     'code': 'zh_TW'},
    {'label': '한국어',                'code': 'ko'},
    {'label': 'Español',              'code': 'es'},
    {'label': 'Français',             'code': 'fr'},
    {'label': 'Deutsch',              'code': 'de'},
    {'label': 'Tiếng Việt',           'code': 'vi'},
    {'label': 'Bahasa Indonesia',     'code': 'id'}
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialLanguage();
  }

  /// 保存済み言語がなければOS言語を初期選択とする
  Future<void> _loadInitialLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    String? code = prefs.getString('user_language');
    if (code == null) {
      // OS言語コードを取得（例: 'en-US' → 'en'）
      code = WidgetsBinding.instance.window.locale.languageCode;
    }
    setState(() {
      selectedLang = code;
    });
  }

  Future<void> _selectLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_language', code);
    await prefs.remove('target_language');

    setState(() {
      selectedLang = code;
    });

    // アプリ全体に新しい言語を適用
    MyApp.setLocale(context, Locale(code));

    // 次の画面へ（学びたい言語の選択画面）
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const TargetLanguageSelectionScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(loc.languageSelectionTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              loc.languageSelectionDescription,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            ...languages.map((lang) {
              return Card(
                child: ListTile(
                  title: Text(lang['label']!),
                  trailing: selectedLang == lang['code']
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () => _selectLanguage(lang['code']!),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
