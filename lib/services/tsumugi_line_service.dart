import 'dart:math';

import 'package:kawaii_lang/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TsumugiLineBucket { normal, free, night }

class TsumugiLineService {
  TsumugiLineService._();

  static final TsumugiLineService instance = TsumugiLineService._();
  static final Random _rand = Random();

  static const String _recentHistoryPrefix = 'tsumugiRecentLineHistory';
  static const int _repeatGap = 3;

  static const List<String> _normalKeys = [
    'tsumugiLineNormal1',
    'tsumugiLineNormal2',
    'tsumugiLineNormal3',
  ];
  static const List<String> _freeKeys = [
    'tsumugiLineFree1',
    'tsumugiLineFree2',
    'tsumugiLineFree3',
  ];
  static const List<String> _nightKeys = [
    'tsumugiLineNight1',
    'tsumugiLineNight2',
    'tsumugiLineNight3',
  ];
  static const Map<String, String> _freeLine2ByLang = {
    'ja': 'まずは気軽にやってみよう。続けたくなったら、いつでもおいで。',
    'en': 'Start with something easy. If you want to keep going, come back anytime.',
    'zh': '先轻松试试吧。想继续的时候，随时再来。',
    'zh_tw': '先輕鬆試試吧。想繼續的時候，隨時再來。',
    'ko': '일단 가볍게 시작해 봐. 더 하고 싶어지면 언제든 다시 와.',
    'es': 'Empieza con algo sencillo. Si te apetece seguir, vuelve cuando quieras.',
    'fr': 'Commence en douceur. Si tu veux continuer, reviens quand tu veux.',
    'de': 'Starte ganz locker. Wenn du weitermachen willst, komm jederzeit wieder.',
    'vi': 'Cứ bắt đầu nhẹ nhàng thôi. Khi muốn học tiếp, quay lại lúc nào cũng được.',
    'id': 'Mulai dari yang ringan dulu. Kalau mau lanjut, balik kapan saja.',
  };

  Future<String> getLine({
    required AppLocalizations loc,
    required bool hasSubscription,
    DateTime? now,
  }) async {
    final DateTime current = now ?? DateTime.now();
    final bucket =
        _resolveBucket(now: current, hasSubscription: hasSubscription);
    final keys = _keysForBucket(bucket);

    final prefs = await SharedPreferences.getInstance();
    final historyKey = '$_recentHistoryPrefix:${bucket.name}';
    final recent = _loadRecentIndices(
      prefs.getString(historyKey),
      candidateCount: keys.length,
    );
    final pickedIndex = _pickIndexWithGap(
      candidateCount: keys.length,
      recent: recent,
    );
    final updated = <int>[...recent, pickedIndex];
    final maxKeep = _repeatGap * 2;
    final trimmed = updated.length > maxKeep
        ? updated.sublist(updated.length - maxKeep)
        : updated;
    await prefs.setString(
      historyKey,
      trimmed.map((e) => e.toString()).join(','),
    );

    return _textByKey(loc, keys[pickedIndex]);
  }

  TsumugiLineBucket _resolveBucket({
    required DateTime now,
    required bool hasSubscription,
  }) {
    if (now.hour >= 21) return TsumugiLineBucket.night;
    if (!hasSubscription) return TsumugiLineBucket.free;
    return TsumugiLineBucket.normal;
  }

  List<String> _keysForBucket(TsumugiLineBucket bucket) {
    switch (bucket) {
      case TsumugiLineBucket.night:
        return _nightKeys;
      case TsumugiLineBucket.free:
        return _freeKeys;
      case TsumugiLineBucket.normal:
        return _normalKeys;
    }
  }

  List<int> _loadRecentIndices(String? raw, {required int candidateCount}) {
    if (raw == null || raw.isEmpty) return const [];
    return raw
        .split(',')
        .map((s) => int.tryParse(s))
        .whereType<int>()
        .where((i) => i >= 0 && i < candidateCount)
        .toList();
  }

  int _pickIndexWithGap({
    required int candidateCount,
    required List<int> recent,
  }) {
    if (candidateCount <= 1) return 0;

    final recentWindow = recent.length <= _repeatGap
        ? recent
        : recent.sublist(recent.length - _repeatGap);
    final blocked = <int>{};
    if (candidateCount > _repeatGap) {
      blocked.addAll(recentWindow);
    } else if (recentWindow.isNotEmpty) {
      // 候補数 <= _repeatGap の場合は candidateCount-1 個をブロックして
      // 全候補を一巡してから繰り返すようにする。
      final blockCount = min(recentWindow.length, candidateCount - 1);
      blocked.addAll(recentWindow.sublist(recentWindow.length - blockCount));
    }

    var pool = <int>[
      for (var i = 0; i < candidateCount; i++)
        if (!blocked.contains(i)) i,
    ];
    if (pool.isEmpty) {
      final last = recentWindow.isNotEmpty ? recentWindow.last : -1;
      pool = <int>[
        for (var i = 0; i < candidateCount; i++)
          if (i != last) i,
      ];
      if (pool.isEmpty) return 0;
    }
    return pool[_rand.nextInt(pool.length)];
  }

  String _textByKey(AppLocalizations loc, String key) {
    switch (key) {
      case 'tsumugiLineNormal1':
        return loc.tsumugiLineNormal1;
      case 'tsumugiLineNormal2':
        return loc.tsumugiLineNormal2;
      case 'tsumugiLineNormal3':
        return loc.tsumugiLineNormal3;
      case 'tsumugiLineFree1':
        return loc.tsumugiLineFree1;
      case 'tsumugiLineFree2':
        return _localizedFreeLine2(loc);
      case 'tsumugiLineFree3':
        return loc.tsumugiLineFree3;
      case 'tsumugiLineNight1':
        return loc.tsumugiLineNight1;
      case 'tsumugiLineNight2':
        return loc.tsumugiLineNight2;
      case 'tsumugiLineNight3':
        return loc.tsumugiLineNight3;
      default:
        return loc.tsumugiLineNormal2;
    }
  }

  String _localizedFreeLine2(AppLocalizations loc) {
    final locale = loc.localeName.replaceAll('-', '_').toLowerCase();
    final text = _freeLine2ByLang[locale];
    if (text != null && text.isNotEmpty) return text;
    final base = locale.split('_').first;
    return _freeLine2ByLang[base] ?? loc.tsumugiLineFree2;
  }
}
