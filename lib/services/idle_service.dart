// lib/services/idle_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class IdleService {
  static const _exitTimeKey = 'last_exit_time';
  static const _idleLimitMinutes = 1;

  // ⭐ 追加：main()で呼び出す初期化処理（現在は何も処理しない）
  static Future<void> ensureInitialized() async {
    // 必要ならここでSharedPreferencesを事前読み込みなどできる
    // final prefs = await SharedPreferences.getInstance();
    // debugPrint('IdleService initialized');
  }

  static Future<void> saveExitTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_exitTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<bool> isIdleTooLong() async {
    final prefs = await SharedPreferences.getInstance();
    final lastExitMillis = prefs.getInt(_exitTimeKey);
    if (lastExitMillis == null) return false;

    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = now - lastExitMillis;
    return diff > (_idleLimitMinutes * 60 * 1000);
  }

  static Future<int> getIdleMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    final lastExitMillis = prefs.getInt(_exitTimeKey);
    if (lastExitMillis == null) return 0;

    final now = DateTime.now().millisecondsSinceEpoch;
    final diffMillis = now - lastExitMillis;
    return (diffMillis / 1000 / 60).floor();
  }
}
