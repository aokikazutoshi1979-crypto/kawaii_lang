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
    return 'assets/images/characters/$c/${c}_menu.png';
  }

  static String questionBackground(String character) {
    final c = normalize(character);
    return 'assets/images/characters/$c/${c}_questions.png';
  }

  static String chatBackground(String character) {
    final c = normalize(character);
    return 'assets/images/characters/$c/${c}_chat.png';
  }

  static String chatAvatar(String character) {
    final c = normalize(character);
    return 'assets/images/characters/$c/${c}_01.png';
  }
}
