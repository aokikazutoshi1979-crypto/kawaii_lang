import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class LanguageCatalog {
  LanguageCatalog._();
  static final instance = LanguageCatalog._();

  Map<String, Map<String, String>> _labels = {};
  bool _loaded = false;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final raw = await rootBundle.loadString('assets/questions/languages.json');
    final List<dynamic> arr = jsonDecode(raw);
    _labels = {
      for (final e in arr)
        (e['id'] as String): Map<String, String>.from(e['label'] as Map)
    };
    _loaded = true;
  }

  /// 例: labelFor('en', displayLang: 'ja') -> "英語"
  String labelFor(String id, {required String displayLang}) {
    final code = _norm(id);
    final disp = _norm(displayLang);
    final map = _labels[code];
    if (map == null) return code.toUpperCase();
    return map[disp] ?? map['en'] ?? map.values.first;
  }

  String _norm(String s) => s.replaceAll('-', '_');
}
