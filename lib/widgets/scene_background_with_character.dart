import 'package:flutter/material.dart';

class SceneBackgroundWithCharacter extends StatelessWidget {
  final String langName;
  final String sceneName;

  const SceneBackgroundWithCharacter({
    required this.langName,
    required this.sceneName,
    Key? key,
  }) : super(key: key);

  String getCharacterPath(String lang) {
    const base = 'assets/images/characters';
    switch (lang) {
      case 'ja':
        return '$base/Japanese_girl.png';
      case 'en':
        return '$base/English_girl.png';
      case 'zh':
        return '$base/Chinese_simplified_girl.png';
      case 'zh_TW':
        return '$base/Chinese_traditional_girl.png';
      case 'ko':
        return '$base/Korean_girl.png';
      case 'es':
        return '$base/Spanish_girl.png';
      case 'fr':
        return '$base/French_girl.png';
      case 'de':
        return '$base/German_girl.png';
      case 'vi':
        return '$base/Vietnamese_girl.png';
      case 'id':
        return '$base/Indonesian_girl.png';
      default:
        return '$base/English_girl.png';
    }
  }

  String getBackgroundPath(String scene) {
    switch (scene) {
      case 'trial':
        return 'assets/images/backgrounds/trial.png';
      case 'vocabulary':
        return 'assets/images/backgrounds/vocabulary.png';
      case 'greeting':
        return 'assets/images/backgrounds/greeting.png';
      case 'travel':
        return 'assets/images/backgrounds/travel.png';
      case 'restaurant':
        return 'assets/images/backgrounds/restaurant.png';
      case 'shopping':
        return 'assets/images/backgrounds/shopping.png';
      case 'dating':
        return 'assets/images/backgrounds/dating.png';
      case 'culture_entertainment':
        return 'assets/images/backgrounds/culture_entertainment.png';
      case 'community_life':
        return 'assets/images/backgrounds/community_life.png';
      case 'work':
        return 'assets/images/backgrounds/work.png';
      case 'Social_interactions_hobbies':
        return 'assets/images/backgrounds/Social_interactions_hobbies.png';
      default:
        return 'assets/images/backgrounds/default.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            getBackgroundPath(sceneName),
            fit: BoxFit.fitWidth,
            alignment: Alignment.center,
          ),
          // Image.asset(
          //   getCharacterPath(langName),
          //   fit: BoxFit.contain,
          // ),
        ],
      ),
    );
  }
}
