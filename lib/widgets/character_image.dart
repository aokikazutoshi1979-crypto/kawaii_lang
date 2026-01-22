import 'package:flutter/material.dart';

class CharacterImage extends StatelessWidget {
  final String langName;

  const CharacterImage({required this.langName, Key? key}) : super(key: key);

  String getImagePath(String lang) {
    const base = 'assets/images/characters';
    switch (lang) {
      case 'Japanese':
        return '$base/Japanese_girl.png';
      case 'English':
        return '$base/English_girl.png';
      case 'Chinese (Simplified)':
        return '$base/Chinese_simplified_girl.png';
      case 'Chinese (Traditional, Taiwan)':
        return '$base/Chinese_traditional_girl.png';
      case 'Korean':
        return '$base/Korean_girl.png';
      case 'Spanish':
        return '$base/Spanish_girl.png';
      case 'French':
        return '$base/French_girl.png';
      case 'German':
        return '$base/German_girl.png';
      case 'Vietnamese':
        return '$base/Vietnamese_girl.png';
      case 'Indonesian':
        return '$base/Indonesian_girl.png';
      default:
        return '$base/English_girl.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      getImagePath(langName),
      width: double.infinity,
      height: 250,
      fit: BoxFit.cover,
    );
  }
}
