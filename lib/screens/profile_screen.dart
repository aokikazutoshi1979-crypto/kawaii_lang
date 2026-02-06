// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:kawaii_lang/l10n/app_localizations.dart';
import '../services/history_service.dart';
import '../common/scene_label.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = true;
  ProfileStats? _stats;

  static const List<Map<String, Object>> _ranks = [
    {'name': 'Starter', 'threshold': 0},
    {'name': 'Explorer', 'threshold': 25},
    {'name': 'Speaker', 'threshold': 100},
    {'name': 'Fluent', 'threshold': 300},
    {'name': 'Pro', 'threshold': 600},
    {'name': 'Master', 'threshold': 1000},
  ];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await HistoryService.instance.getProfileStats();
    if (!mounted) return;
    setState(() {
      _stats = stats;
      _loading = false;
    });
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
      final filled = (ratio * 10).floor();
      final bar = _progressBar(filled);
      final shown = uniqueCorrect.clamp(0, nextThreshold);
      final remaining = (nextThreshold - uniqueCorrect).clamp(0, nextThreshold);

      lines.addAll([
        const SizedBox(height: 6),
        Text(
          '${loc.progressToRank(nextName)}  $bar  $shown/$nextThreshold',
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
