import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DailyPracticeService {
  DailyPracticeService._();
  static final DailyPracticeService instance = DailyPracticeService._();

  static const _keyDate = 'daily_practice_date';
  static const _keyQuestionId = 'daily_practice_question_id';
  static const _keyDoneIds = 'daily_practice_done_ids';
  static const _keyCountDate = 'daily_practice_count_date';
  static const _keyCount = 'daily_practice_count';

  // Today's Practice で使用するファイル（allowlist方式）
  static const _allowedFile = 'assets/questions/daily_featured.json';

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// 今日の練習フレーズを返す。同じ日に呼ぶと同じフレーズを返す。
  /// 戻り値：フレーズのMap（nullなら取得失敗）
  Future<Map<String, dynamic>?> getTodaysQuestion({
    required String userLevel,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayString();

    // 同じ日なら保存済みIDのフレーズを返す
    final savedDate = prefs.getString(_keyDate);
    final savedId = prefs.getString(_keyQuestionId);
    if (savedDate == today && savedId != null) {
      final allQuestions = await _loadAllQuestions();
      final found = allQuestions.where((q) => q['id'] == savedId).firstOrNull;
      if (found != null) return found;
    }

    // 日付が変わった or 初回 → 新しいフレーズを選択
    final allQuestions = await _loadAllQuestions();

    // userLevel に応じてフィルタ
    final filtered = allQuestions.where((q) {
      final level = q['level'] as String? ?? '';
      return _levelMatches(userLevel, level);
    }).toList();

    if (filtered.isEmpty) return null;

    // 練習済みIDを取得
    List<String> doneIds = _parseDoneIds(prefs.getString(_keyDoneIds));

    // 未練習のフレーズに絞る
    List<Map<String, dynamic>> candidates =
        filtered.where((q) => !doneIds.contains(q['id'] as String)).toList();

    // 全部練習済みならリセット
    if (candidates.isEmpty) {
      doneIds = [];
      await prefs.remove(_keyDoneIds);
      candidates = filtered;
    }

    // ランダムに1つ選んで保存
    final selected = candidates[Random().nextInt(candidates.length)];
    final selectedId = selected['id'] as String;

    await prefs.setString(_keyDate, today);
    await prefs.setString(_keyQuestionId, selectedId);

    return selected;
  }

  /// 練習済みとしてIDを記録する
  Future<void> markAsCompleted(String questionId) async {
    final prefs = await SharedPreferences.getInstance();
    final doneIds = _parseDoneIds(prefs.getString(_keyDoneIds));
    if (!doneIds.contains(questionId)) {
      doneIds.add(questionId);
      await prefs.setString(_keyDoneIds, jsonEncode(doneIds));
    }
  }

  /// 今日の練習回数を返す
  Future<int> getTodaysPracticeCount() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayString();
    final countDate = prefs.getString(_keyCountDate);
    if (countDate != today) return 0;
    return prefs.getInt(_keyCount) ?? 0;
  }

  /// 今日のフレーズキャッシュをクリアして次回呼び出し時に新しいフレーズを選ぶ
  Future<void> clearCurrentQuestion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyQuestionId);
  }

  /// 練習回数をインクリメントする
  Future<void> incrementPracticeCount() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayString();
    final countDate = prefs.getString(_keyCountDate);
    final current = (countDate == today) ? (prefs.getInt(_keyCount) ?? 0) : 0;
    await prefs.setString(_keyCountDate, today);
    await prefs.setInt(_keyCount, current + 1);
  }

  // ---- private helpers ----

  Future<List<Map<String, dynamic>>> _loadAllQuestions() async {
    final List<Map<String, dynamic>> all = [];
    try {
      final raw = await rootBundle.loadString(_allowedFile);
      final list = jsonDecode(raw) as List<dynamic>;
      for (final item in list) {
        if (item is Map<String, dynamic>) all.add(item);
      }
    } catch (_) {
      // 読み込み失敗は無視
    }
    return all;
  }

  bool _levelMatches(String userLevel, String questionLevel) {
    switch (userLevel) {
      case 'starter':
        return questionLevel == 'starter';
      case 'beginner':
        return questionLevel == 'starter' || questionLevel == 'beginner';
      case 'intermediate':
        return questionLevel == 'beginner' || questionLevel == 'intermediate';
      case 'advanced':
        return true;
      default:
        return true;
    }
  }

  List<String> _parseDoneIds(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List<dynamic>).cast<String>();
    } catch (_) {
      return [];
    }
  }
}
