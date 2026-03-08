import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../services/character_asset_service.dart';
import 'character_selection_screen.dart';
import 'home_screen.dart';

class LevelSelectionScreen extends StatefulWidget {
  final bool isOnboarding;

  const LevelSelectionScreen({
    super.key,
    this.isOnboarding = false,
  });

  @override
  State<LevelSelectionScreen> createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen> {
  String _selectedCharacter = CharacterAssetService.defaultCharacter;

  @override
  void initState() {
    super.initState();
    _loadCharacter();
  }

  Future<void> _loadCharacter() async {
    final prefs = await SharedPreferences.getInstance();
    final character = CharacterAssetService.normalize(
      prefs.getString(CharacterAssetService.prefKey),
    );
    if (mounted) setState(() => _selectedCharacter = character);
  }

  Future<void> _selectLevel(String level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_level', level);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => widget.isOnboarding
            ? const CharacterSelectionScreen()
            : const HomeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final avatarPath = CharacterAssetService.chatAvatar(_selectedCharacter);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              // キャラクターアバター＋吹き出し
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundImage: AssetImage(avatarPath),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        loc.levelSelectQuestion,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              // レベル選択ボタン3つ
              _LevelCard(
                icon: '🌱',
                title: loc.levelSelectOptionStarterTitle,
                subtitle: loc.levelSelectOptionStarterSub,
                onTap: () => _selectLevel('starter'),
              ),
              const SizedBox(height: 16),
              _LevelCard(
                icon: '🎌',
                title: loc.levelSelectOptionBeginnerTitle,
                subtitle: loc.levelSelectOptionBeginnerSub,
                onTap: () => _selectLevel('beginner'),
              ),
              const SizedBox(height: 16),
              _LevelCard(
                icon: '📚',
                title: loc.levelSelectOptionIntermediateTitle,
                subtitle: loc.levelSelectOptionIntermediateSub,
                onTap: () => _selectLevel('intermediate'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _LevelCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
