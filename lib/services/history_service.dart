// lib/services/history_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class DailyCorrectStats {
  final int todayCorrect;
  final int streakDays;
  const DailyCorrectStats({
    required this.todayCorrect,
    required this.streakDays,
  });
}

class ProfileStats {
  final int todayCorrect;
  final int streakDays;
  final int totalCorrect;
  final int uniqueCorrect;
  final Map<String, int> correctByScene;
  const ProfileStats({
    required this.todayCorrect,
    required this.streakDays,
    required this.totalCorrect,
    required this.uniqueCorrect,
    required this.correctByScene,
  });
}

class HistoryService {
  HistoryService._();
  static final instance = HistoryService._();

  final _db = FirebaseFirestore.instance;
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  Future<DailyCorrectStats> getTodayCorrectAndStreak({int lookbackDays = 365}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const DailyCorrectStats(todayCorrect: 0, streakDays: 0);
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final cutoff = today.subtract(Duration(days: lookbackDays));

    final snap = await _db
        .collection('users')
        .doc(_uid)
        .collection('history')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
        .orderBy('timestamp', descending: true)
        .get();

    final Map<int, int> correctByDay = {};
    for (final doc in snap.docs) {
      final data = doc.data();
      if (data['isCorrect'] != true) continue;
      final ts = data['timestamp'];
      if (ts is! Timestamp) continue;
      final local = ts.toDate().toLocal();
      final dayKey = DateTime(local.year, local.month, local.day).millisecondsSinceEpoch;
      correctByDay[dayKey] = (correctByDay[dayKey] ?? 0) + 1;
    }

    final todayKey = today.millisecondsSinceEpoch;
    final todayCorrect = correctByDay[todayKey] ?? 0;

    var streak = 0;
    for (var i = 0; i <= lookbackDays; i++) {
      final day = today.subtract(Duration(days: i));
      final key = DateTime(day.year, day.month, day.day).millisecondsSinceEpoch;
      if ((correctByDay[key] ?? 0) > 0) {
        streak++;
      } else {
        break;
      }
    }

    return DailyCorrectStats(todayCorrect: todayCorrect, streakDays: streak);
  }

  Future<ProfileStats> getProfileStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const ProfileStats(
        todayCorrect: 0,
        streakDays: 0,
        totalCorrect: 0,
        uniqueCorrect: 0,
        correctByScene: <String, int>{},
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayKey = today.millisecondsSinceEpoch;

    final snap = await _db
        .collection('users')
        .doc(_uid)
        .collection('history')
        .where('isCorrect', isEqualTo: true)
        .get();

    final Map<int, int> correctByDay = {};
    final Map<String, int> correctByScene = {};
    var totalCorrect = 0;
    final Set<String> uniqueQuestionIds = {};

    for (final doc in snap.docs) {
      final data = doc.data();
      totalCorrect++;
      final qid = (data['questionId'] ?? '').toString();
      if (qid.isNotEmpty) uniqueQuestionIds.add(qid);

      final scene = (data['scene'] ?? '').toString();
      if (scene.isNotEmpty) {
        correctByScene[scene] = (correctByScene[scene] ?? 0) + 1;
      }

      final ts = data['timestamp'];
      if (ts is! Timestamp) continue;
      final local = ts.toDate().toLocal();
      final dayKey = DateTime(local.year, local.month, local.day).millisecondsSinceEpoch;
      correctByDay[dayKey] = (correctByDay[dayKey] ?? 0) + 1;
    }

    final todayCorrect = correctByDay[todayKey] ?? 0;
    var streak = 0;
    for (var i = 0; ; i++) {
      final day = today.subtract(Duration(days: i));
      final key = DateTime(day.year, day.month, day.day).millisecondsSinceEpoch;
      if ((correctByDay[key] ?? 0) > 0) {
        streak++;
      } else {
        break;
      }
    }

    return ProfileStats(
      todayCorrect: todayCorrect,
      streakDays: streak,
      totalCorrect: totalCorrect,
      uniqueCorrect: uniqueQuestionIds.length,
      correctByScene: correctByScene,
    );
  }

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
