import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kawaii_lang/l10n/app_localizations.dart';

class TargetLanguageSelectionScreen extends StatefulWidget {
  const TargetLanguageSelectionScreen({Key? key}) : super(key: key);

  @override
  _TargetLanguageSelectionScreenState createState() =>
      _TargetLanguageSelectionScreenState();
}

class _TargetLanguageSelectionScreenState
    extends State<TargetLanguageSelectionScreen> {
  String? selectedLang;
  String? _nativeLang;

  final List<Map<String, String>> _languages = [
    {'label': '日本語',            'code': 'ja'},
    {'label': 'English',          'code': 'en'},
    {'label': '中文(简化)',        'code': 'zh'},
    {'label': '台灣(繁體)',        'code': 'zh_TW'},
    {'label': '한국어',            'code': 'ko'},
    {'label': 'Español',          'code': 'es'},
    {'label': 'Français',         'code': 'fr'},
    {'label': 'Deutsch',          'code': 'de'},
    {'label': 'Tiếng Việt',       'code': 'vi'},
    {'label': 'Bahasa Indonesia', 'code': 'id'},
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialLanguage();
  }

  Future<void> _loadInitialLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nativeLang = prefs.getString('user_language') ?? 'ja';
      selectedLang = prefs.getString('target_language');
    });
  }

  Future<void> _selectLanguage(String code) async {
    if (code == _nativeLang) {
      final loc = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.selectPrompt)),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('target_language', code);

    setState(() {
      selectedLang = code;
    });

    Navigator.pushReplacementNamed(context, '/category');
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final native = _nativeLang;
    final languages = native == null
        ? _languages
        : _languages.where((l) => l['code'] != native).toList();

    return Scaffold(
      appBar: AppBar(title: Text(loc.targetLanguage)),
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
