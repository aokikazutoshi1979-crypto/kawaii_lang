// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:kawaii_lang/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import '../services/history_service.dart';
import '../common/scene_label.dart';
import 'chat_screen.dart';
import '../models/quiz_mode.dart';
import '../models/language.dart';

class _RecentItem {
  final String scene;
  final String questionId;
  final int index;
  final String displayText;
  final String selectedQuestionText;
  final String correctAnswerText;
  final List<Map<String, String>> questionList;
  final String nativeLang;
  final String targetLang;

  const _RecentItem({
    required this.scene,
    required this.questionId,
    required this.index,
    required this.displayText,
    required this.selectedQuestionText,
    required this.correctAnswerText,
    required this.questionList,
    required this.nativeLang,
    required this.targetLang,
  });
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = true;
  ProfileStats? _stats;
  List<_RecentItem> _recentItems = [];
  String? _nativeLang;
  String? _targetLang;

  static const List<Map<String, Object>> _ranks = [
    {'name': 'Starter', 'threshold': 0},
    {'name': 'Explorer', 'threshold': 25},
    {'name': 'Speaker', 'threshold': 100},
    {'name': 'Fluent', 'threshold': 300},
    {'name': 'Pro', 'threshold': 600},
    {'name': 'Master', 'threshold': 1000},
  ];

  static const int _recentLimit = 20;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    _nativeLang = prefs.getString('user_language') ?? 'ja';
    _targetLang = prefs.getString('target_language');

    final stats = await HistoryService.instance.getProfileStats();
    final recentEntries = await HistoryService.instance.getRecentCorrectQuestions(
      limit: _recentLimit,
    );
    final recentItems = await _buildRecentItems(
      recentEntries,
      _nativeLang ?? 'ja',
      _targetLang,
    );
    if (!mounted) return;
    setState(() {
      _stats = stats;
      _recentItems = recentItems;
      _loading = false;
    });
  }

  Future<List<_RecentItem>> _buildRecentItems(
    List<RecentQuestionEntry> entries,
    String nativeLang,
    String? targetLang,
  ) async {
    if (entries.isEmpty) return const [];

    final Map<String, List<Question>> questionsByScene = {};
    final Map<String, List<Map<String, String>>> questionListByKey = {};
    final Map<String, Map<String, int>> indexByKey = {};

    Future<List<Question>> loadQuestions(String scene) async {
      if (questionsByScene.containsKey(scene)) return questionsByScene[scene]!;
      try {
        final raw = await rootBundle.loadString('assets/questions/$scene.json');
        final arr = jsonDecode(raw) as List<dynamic>;
        final list = arr
            .map((e) => Question.fromJson(e as Map<String, dynamic>))
            .toList();
        questionsByScene[scene] = list;
        return list;
      } catch (_) {
        questionsByScene[scene] = const [];
        return const [];
      }
    }

    for (final entry in entries) {
      final target = entry.targetCode.isNotEmpty ? entry.targetCode : (targetLang ?? 'en');
      final key = '${entry.scene}|$target';
      if (!questionListByKey.containsKey(key)) {
        final questions = await loadQuestions(entry.scene);
        final questionList = questions.map((qq) {
          return {
            'id': qq.id,
            'scene': qq.scene,
            'subScene': qq.subScene,
            'level': qq.level,
            nativeLang: qq.getText(nativeLang),
            target: qq.getText(target),
          };
        }).toList();
        final Map<String, int> indexMap = {};
        for (var i = 0; i < questions.length; i++) {
          indexMap[questions[i].id] = i;
        }
        questionListByKey[key] = questionList;
        indexByKey[key] = indexMap;
      }
    }

    final List<_RecentItem> items = [];
    for (final entry in entries) {
      final target = entry.targetCode.isNotEmpty ? entry.targetCode : (targetLang ?? 'en');
      final key = '${entry.scene}|$target';
      final questionList = questionListByKey[key];
      final indexMap = indexByKey[key];
      final questions = questionsByScene[entry.scene];
      if (questionList == null || indexMap == null || questions == null) continue;
      final idx = indexMap[entry.questionId];
      if (idx == null || idx < 0 || idx >= questions.length) continue;
      final q = questions[idx];
      items.add(_RecentItem(
        scene: entry.scene,
        questionId: entry.questionId,
        index: idx,
        displayText: q.getText(nativeLang),
        selectedQuestionText: q.getText(nativeLang),
        correctAnswerText: q.getText(target),
        questionList: questionList,
        nativeLang: nativeLang,
        targetLang: target,
      ));
    }

    return items;
  }

  Widget _statCard(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.pink.shade100),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        textAlign: TextAlign.center,
      ),
    );
  }

  Map<String, Object> _currentRankFor(int total) {
    var current = _ranks.first;
    for (final r in _ranks) {
      final threshold = r['threshold'] as int;
      if (total >= threshold) {
        current = r;
      } else {
        break;
      }
    }
    return current;
  }

  String _progressBar(int filledCount) {
    final filled = filledCount.clamp(0, 10);
    return List.generate(10, (i) => i < filled ? '▓' : '░').join();
  }

  Widget _rankSection(ProfileStats stats, AppLocalizations loc) {
    final uniqueCorrect = stats.uniqueCorrect;
    final current = _currentRankFor(uniqueCorrect);
    final currentIndex = _ranks.indexOf(current);
    final hasNext = currentIndex >= 0 && currentIndex < _ranks.length - 1;

    final currentName = current['name'] as String;

    final List<Widget> lines = [
      Text(
        loc.currentRank(currentName),
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ];

    if (hasNext) {
      final next = _ranks[currentIndex + 1];
      final nextName = next['name'] as String;
      final nextThreshold = next['threshold'] as int;
      final ratio = (uniqueCorrect / nextThreshold).clamp(0.0, 1.0);
      final shown = uniqueCorrect.clamp(0, nextThreshold);
      final remaining = (nextThreshold - uniqueCorrect).clamp(0, nextThreshold);

      final filled = (ratio * 10).floor();
      final bar = _progressBar(filled);

      lines.addAll([
        const SizedBox(height: 6),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '${loc.progressToRank(nextName)}  '),
              TextSpan(
                text: bar,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
              TextSpan(text: '  $shown/$nextThreshold'),
            ],
          ),
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          loc.nextRankIn(remaining),
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
        ),
      ]);
    } else {
      lines.addAll([
        const SizedBox(height: 6),
        Text(
          loc.maxRankAchieved,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
        ),
      ]);
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.pink.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines,
      ),
    );
  }

  void _openRecentItem(_RecentItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          nativeLang: item.nativeLang,
          targetLang: item.targetLang,
          scene: item.scene,
          promptLang: item.nativeLang,
          isNativePrompt: true,
          selectedQuestionText: item.selectedQuestionText,
          correctAnswerText: item.correctAnswerText,
          questionList: item.questionList,
          selectedIndex: item.index,
          mode: QuizMode.reading,
        ),
      ),
    ).then((_) => _loadStats());
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.profileTitle),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _rankSection(_stats!, loc),
                const SizedBox(height: 12),
                _statCard(loc.todayCorrectCount(_stats?.todayCorrect ?? 0)),
                const SizedBox(height: 8),
                _statCard(loc.streakDaysCount(_stats?.streakDays ?? 0)),
                const SizedBox(height: 8),
                _statCard(loc.totalCorrectCount(_stats?.totalCorrect ?? 0)),
                const SizedBox(height: 8),
                ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                  title: Text(
                    loc.recentQuestionsTitle(_recentLimit),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  children: [
                    if (_recentItems.isEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Text(
                          loc.noHistoryData,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    else
                      ..._recentItems.map((item) {
                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: ListTile(
                            title: Text(
                              item.displayText,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(sceneLabel(item.scene, loc)),
                            trailing: ElevatedButton(
                              onPressed: () => _openRecentItem(item),
                              child: Text(loc.startQuestionButton),
                            ),
                          ),
                        );
                      }).toList(),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  loc.categoryCorrectHeader,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if ((_stats?.correctByScene ?? {}).isEmpty)
                  Text(
                    loc.noHistoryData,
                    style: TextStyle(color: Colors.grey.shade600),
                  )
                else
                  ...(_stats!.correctByScene.entries.toList()
                        ..sort((a, b) => b.value.compareTo(a.value)))
                      .map((entry) {
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        title: Text(sceneLabel(entry.key, loc)),
                        trailing: Text(
                          entry.value.toString(),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    );
                  }).toList(),
              ],
            ),
    );
  }
}
