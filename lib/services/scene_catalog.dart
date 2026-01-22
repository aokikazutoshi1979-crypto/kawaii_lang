// lib/services/scene_catalog.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';

class SceneCatalog with ChangeNotifier {
  SceneCatalog._();
  static final SceneCatalog instance = SceneCatalog._();

  bool _loaded = false;

  /// subSceneId → { 'ja': '挨拶', 'en': 'Greeting', ... }
  final Map<String, Map<String, String>> _subsceneLabels = {};

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final raw = await rootBundle.loadString('assets/questions/scenes.json');
    final List<dynamic> arr = json.decode(raw) as List<dynamic>;

    // 各 scene の subScenes を走査して辞書を作る
    for (final s in arr) {
      final subScenes = (s['subScenes'] as List<dynamic>? ?? []);
      for (final ss in subScenes) {
        final id = ss['id']?.toString() ?? '';
        final label = (ss['label'] as Map?)?.map(
              (k, v) => MapEntry(k.toString(), v.toString()),
            ) ??
            const <String, String>{};
        if (id.isNotEmpty && label.isNotEmpty) {
          _subsceneLabels[id] = label.cast<String, String>();
        }
      }
    }

    _loaded = true;
    notifyListeners();
  }

  /// ロケールに合うラベルを返す（なければフォールバック）
  String? labelForSubscene(String subSceneId, Locale locale) {
    final map = _subsceneLabels[subSceneId];
    if (map == null) return null;

    final key = _localeKey(locale);
    return map[key] ??
        map[locale.languageCode] ??
        map['en'] ??
        (map.isNotEmpty ? map.values.first : null);
  }

  // JSONのキーに合わせてロケール→キーへ正規化
  String _localeKey(Locale loc) {
    // 例: zh-Hant-TW / zh_TW / zh-TW → zh_TW に寄せる
    if (loc.languageCode == 'zh') {
      final cc = (loc.countryCode ?? '').toUpperCase();
      final sc = (loc.scriptCode ?? '').toLowerCase();
      if (cc == 'TW' || cc == 'HK' || cc == 'MO' || sc == 'hant') {
        return 'zh_TW';
      }
      return 'zh';
    }
    // 通常は言語コード（ja, en, ko, es, fr, de, vi, id）
    return loc.languageCode;
  }
}
