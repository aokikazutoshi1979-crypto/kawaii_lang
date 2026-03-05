import 'package:shared_preferences/shared_preferences.dart';

class CharacterAssetService {
  CharacterAssetService._();

  static const String prefKey = 'selected_character';
  static const String tumugi = 'tumugi';
  static const String kasumi = 'kasumi';
  static const String defaultCharacter = tumugi;

  static const List<String> supportedCharacters = [tumugi, kasumi];

  static String normalize(String? value) {
    if (value == kasumi) return kasumi;
    return tumugi;
  }

  static Future<String> loadSelectedCharacter() async {
    final prefs = await SharedPreferences.getInstance();
    return normalize(prefs.getString(prefKey));
  }

  static Future<void> saveSelectedCharacter(String character) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefKey, normalize(character));
  }

  static String menuBackground(String character) {
    final c = normalize(character);
    return 'assets/images/characters/$c/menu.png';
  }

  static String questionBackground(String character) {
    final c = normalize(character);
    return 'assets/images/characters/$c/questions.png';
  }

  static String chatBackground(String character) {
    final c = normalize(character);
    return 'assets/images/characters/$c/chat.png';
  }

  static String chatAvatar(String character) {
    final c = normalize(character);
    return 'assets/images/characters/$c/01.png';
  }

  /// 「今日の練習」画面用のキャラクター画像パス
  /// 画像ファイルは assets/images/characters/[character]/daily.png
  static String dailyPracticeImage(String character) {
    final c = normalize(character);
    return 'assets/images/characters/$c/daily.png';
  }

  /// キャラクター表示名を言語コードに応じて返す
  static String characterDisplayName(String character, String langCode) {
    final c = normalize(character);
    final lang = langCode.replaceAll('-', '_').toLowerCase();
    if (c == tumugi) {
      switch (lang) {
        case 'ja':
        case 'zh':
        case 'zh_tw':
          return '紬';
        case 'ko':
          return '쓰무기';
        default:
          return 'Tsumugi';
      }
    } else {
      switch (lang) {
        case 'ja':
        case 'zh':
        case 'zh_tw':
          return '香澄';
        case 'ko':
          return '카스미';
        default:
          return 'Kasumi';
      }
    }
  }
}
