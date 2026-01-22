// lib/services/history_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class HistoryService {
  HistoryService._();
  static final instance = HistoryService._();

  final _db = FirebaseFirestore.instance;
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  Future<void> recordAnswer({
    required String questionId,
    required bool isCorrect,
    required String scene,
    required String subScene,
    required String level,
    required String mode,
    required String targetLang,  // ★追加
    required String nativeLang,  // ★追加
    required String targetCode,  // ★追加
    required String nativeCode,  // ★追加
  }) {
    final path = 'users/$_uid/history';
    debugPrint('→ write path: $path');

    final docRef = _db
      .collection('users')
      .doc(_uid)
      .collection('history')
      .doc(); // 自動ID
    return docRef.set({
      'questionId': questionId,
      'isCorrect':   isCorrect,
      'scene':       scene,
      'subScene':    subScene,
      'level':       level,
      'mode':       mode, // 追加したいなら引数拡張
      'targetLang': targetLang,  // ★追加
      'nativeLang': nativeLang,  // ★追加
      'targetCode': targetCode,   // 例: "en", "zh_tw"
      'nativeCode': nativeCode,   // 例: "ja"
      'timestamp':   FieldValue.serverTimestamp(),
    });
  }

  /// ✅ 判定用：ユーザーが既に正解した questionId 一覧を取得
  Future<Set<String>> getClearedQuestions({
    required String targetLang,
    required String nativeLang,
  }) async {
    final snapshot = await _db
        .collection('users')
        .doc(_uid)
        .collection('history')
        .where('isCorrect', isEqualTo: true)
        .where('targetLang', isEqualTo: targetLang)
        .where('nativeLang', isEqualTo: nativeLang)
        .get();

    return snapshot.docs.map((doc) => doc['questionId'] as String).toSet();
  }

  Future<Set<String>> getClearedQuestionsByCode({
    required String targetCode,  // 例: "en", "zh_tw"
    required String nativeCode,  // 例: "ja"
    String? scene,               // 任意: 画面ごとに絞るなら
    String? subScene,            // 任意
  }) async {
    Query<Map<String, dynamic>> q = _db
        .collection('users').doc(_uid)
        .collection('history')
        .where('isCorrect', isEqualTo: true)
        .where('targetCode', isEqualTo: targetCode)
        .where('nativeCode', isEqualTo: nativeCode);

    if (scene != null)   q = q.where('scene', isEqualTo: scene);
    if (subScene != null) q = q.where('subScene', isEqualTo: subScene);

    final snap = await q.get();
    return snap.docs.map((d) => d['questionId'] as String).toSet();
  }
}
