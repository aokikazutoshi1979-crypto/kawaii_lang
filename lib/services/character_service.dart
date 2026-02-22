import 'package:shared_preferences/shared_preferences.dart';

class CharacterService {
  CharacterService._();

  static const String prefKey = 'selected_character';
  static const String tsumugi = 'tsumugi';
  static const String kasumi = 'kasumi';
  static const String defaultCharacter = tsumugi;

  static const List<String> supportedCharacters = <String>[tsumugi, kasumi];

  static String normalize(String? value) {
    if (value == kasumi) return kasumi;
    if (value == 'tumugi') return tsumugi; // legacy id fallback
    return tsumugi;
  }

  static Future<String> getSelectedCharacter() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(prefKey);
    final normalized = normalize(saved);
    if (saved != normalized) {
      await prefs.setString(prefKey, normalized);
    }
    return normalized;
  }

  static Future<void> setSelectedCharacter(String characterId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefKey, normalize(characterId));
  }

  static String menuPath(String selectedCharacter) {
    final character = normalize(selectedCharacter);
    return 'assets/images/characters/$character/menu.png';
  }

  static String questionsPath(String selectedCharacter) {
    final character = normalize(selectedCharacter);
    return 'assets/images/characters/$character/questions.png';
  }

  static String chatPath(String selectedCharacter) {
    final character = normalize(selectedCharacter);
    return 'assets/images/characters/$character/chat.png';
  }

  static String avatarPath(String selectedCharacter) {
    final character = normalize(selectedCharacter);
    return 'assets/images/characters/$character/01.png';
  }

  static String mainPath(String selectedCharacter) {
    final character = normalize(selectedCharacter);
    return 'assets/images/characters/$character/main.png';
  }
}
