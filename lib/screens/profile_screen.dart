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
