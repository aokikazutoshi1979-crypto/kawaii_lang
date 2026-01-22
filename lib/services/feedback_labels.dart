import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class FeedbackLabels {
  static Map<String, Map<String, String>> _labels = {};

  static Future<void> load() async {
    final String data = await rootBundle.loadString('assets/feedback/feedback_labels.json');
    _labels = Map<String, Map<String, String>>.from(
      json.decode(data).map((key, value) => MapEntry(key, Map<String, String>.from(value))),
    );
  }

  static String getLabel(String key, String langCode) {
    return _labels[key]?[langCode] ?? '（未設定）';
  }
}
