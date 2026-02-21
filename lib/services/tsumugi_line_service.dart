import 'dart:math';

import 'package:kawaii_lang/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TsumugiLineBucket { normal, free, night }

class TsumugiLineService {
  TsumugiLineService._();

  static final TsumugiLineService instance = TsumugiLineService._();
  static final Random _rand = Random();

  static const String _lastDateKey = 'lastTsumugiLineDate';
  static const String _lineIndexKey = 'todayTsumugiLineIndex';
  static const String _lineKeyKey = 'todayTsumugiLineKey';
  static const String _lineBucketKey = 'todayTsumugiLineBucket';

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

  Future<String> getLine({
    required AppLocalizations loc,
    required bool hasSubscription,
    DateTime? now,
  }) async {
    final DateTime current = now ?? DateTime.now();
    final String today =
        '${current.year.toString().padLeft(4, '0')}-${current.month.toString().padLeft(2, '0')}-${current.day.toString().padLeft(2, '0')}';
    final prefs = await SharedPreferences.getInstance();

    final savedDate = prefs.getString(_lastDateKey);
    if (savedDate == today) {
      final savedKey = prefs.getString(_lineKeyKey);
      if (savedKey != null && savedKey.isNotEmpty) {
        return _textByKey(loc, savedKey);
      }

      final savedBucket = prefs.getString(_lineBucketKey);
      final savedIndex = prefs.getInt(_lineIndexKey) ?? 0;
      final fallbackKeys = _keysForBucket(_bucketFromString(savedBucket));
      if (fallbackKeys.isNotEmpty) {
        final normalized = savedIndex.clamp(0, fallbackKeys.length - 1);
        return _textByKey(loc, fallbackKeys[normalized]);
      }
    }

    final bucket =
        _resolveBucket(now: current, hasSubscription: hasSubscription);
    final keys = _keysForBucket(bucket);
    final index = _rand.nextInt(keys.length);
    final key = keys[index];

    await prefs.setString(_lastDateKey, today);
    await prefs.setInt(_lineIndexKey, index);
    await prefs.setString(_lineKeyKey, key);
    await prefs.setString(_lineBucketKey, bucket.name);

    return _textByKey(loc, key);
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

  TsumugiLineBucket _bucketFromString(String? value) {
    switch (value) {
      case 'night':
        return TsumugiLineBucket.night;
      case 'free':
        return TsumugiLineBucket.free;
      case 'normal':
      default:
        return TsumugiLineBucket.normal;
    }
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
        return loc.tsumugiLineFree2;
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
}
