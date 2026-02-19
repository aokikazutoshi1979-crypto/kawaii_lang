import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kawaii_lang/l10n/app_localizations.dart';
import 'package:kawaii_lang/services/language_catalog.dart';
import 'user_name_screen.dart';

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
  bool _languageCatalogReady = false;

  final List<String> _languageCodes = const [
    'ja',
    'en',
    'zh',
    'zh_TW',
    'ko',
    'es',
    'fr',
    'de',
    'vi',
    'id',
  ];

  String _displayLangCode(BuildContext context) {
    final native = _nativeLang;
    if (native != null && native.isNotEmpty) return native;
    final locale = Localizations.localeOf(context);
    if (locale.languageCode == 'zh' && locale.countryCode?.toUpperCase() == 'TW') {
      return 'zh_TW';
    }
    return locale.languageCode;
  }

  String _labelForLangCode(String code, BuildContext context) {
    if (!_languageCatalogReady) return code;
    return LanguageCatalog.instance.labelFor(
      code,
      displayLang: _displayLangCode(context),
    );
  }

  Future<void> _loadLanguageCatalog() async {
    await LanguageCatalog.instance.ensureLoaded();
    if (!mounted) return;
    setState(() => _languageCatalogReady = true);
  }

  @override
  void initState() {
    super.initState();
    _loadInitialLanguage();
    _loadLanguageCatalog();
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

    final savedName = prefs.getString('user_display_name')?.trim();
    if (savedName == null || savedName.isEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const UserNameScreen(isOnboarding: true),
        ),
      );
    } else {
      Navigator.pushReplacementNamed(context, '/category');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final native = _nativeLang;
    final languages = native == null
        ? _languageCodes
        : _languageCodes.where((code) => code != native).toList();

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
            ...languages.map((code) {
              return Card(
                child: ListTile(
                  title: Text(_labelForLangCode(code, context)),
                  trailing: selectedLang == code
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () => _selectLanguage(code),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
