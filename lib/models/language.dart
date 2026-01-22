// lib/models/language.dart
import 'package:flutter/foundation.dart';

class Language {
  final String id;
  final Map<String,String> label;
  Language({required this.id, required this.label});
  factory Language.fromJson(Map<String,dynamic> json) => Language(
    id: json['id'],
    label: Map<String,String>.from(json['label']),
  );
}

// lib/models/scene.dart
class SubScene {
  final String id;
  final Map<String,String> label;
  SubScene({required this.id, required this.label});
  factory SubScene.fromJson(Map<String,dynamic> j) => SubScene(
    id: j['id'],
    label: Map<String,String>.from(j['label']),
  );
}

class Scene {
  final String id;
  final Map<String,String> label;
  final List<SubScene> subScenes;
  Scene({required this.id, required this.label, required this.subScenes});
  factory Scene.fromJson(Map<String,dynamic> json) => Scene(
    id: json['id'],
    label: Map<String,String>.from(json['label']),
    subScenes: (json['subScenes'] as List)
      .map((e) => SubScene.fromJson(e as Map<String,dynamic>))
      .toList(),
  );
}

// lib/models/language.dart か question.dart にある Question クラスを次のように修正

class Question {
  final String id;
  final String scene;
  final String subScene;
  final String level;
  final List<String> tags;
  final Map<String, String> translations;

  Question({
    required this.id,
    required this.scene,
    required this.subScene,
    required this.level,
    required this.tags,
    required this.translations,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id:           json['id'] as String,
      scene:        json['scene'] as String,
      subScene:     json['subScene'] as String,
      level:        json['level'] as String,
      tags:         List<String>.from(json['tags'] as List<dynamic>),
      translations: Map<String, String>.from(json['translations'] as Map),
    );
  }

  /// 指定した言語コードのテキストを返す
  String getText(String code) =>
    translations[code] ?? translations.values.last;
}
