import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/character_asset_service.dart';
import 'home_screen.dart';

class CharacterSelectionScreen extends StatelessWidget {
  const CharacterSelectionScreen({super.key});

  Future<void> _selectCharacter(BuildContext context, String character) async {
    await CharacterAssetService.saveSelectedCharacter(character);
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              // タイトル
              Text(
                loc.characterSelectQuestion,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 32),

              // キャラクターカード2枚（縦並び）
              _CharacterCard(
                character: CharacterAssetService.tumugi,
                name: CharacterAssetService.characterDisplayName(
                  CharacterAssetService.tumugi,
                  Localizations.localeOf(context).languageCode,
                ),
                description: loc.characterSelectTumugiDescription,
                onTap: () =>
                    _selectCharacter(context, CharacterAssetService.tumugi),
              ),
              const SizedBox(height: 16),
              _CharacterCard(
                character: CharacterAssetService.kasumi,
                name: CharacterAssetService.characterDisplayName(
                  CharacterAssetService.kasumi,
                  Localizations.localeOf(context).languageCode,
                ),
                description: loc.characterSelectKasumiDescription,
                onTap: () =>
                    _selectCharacter(context, CharacterAssetService.kasumi),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CharacterCard extends StatelessWidget {
  final String character;
  final String name;
  final String description;
  final VoidCallback onTap;

  const _CharacterCard({
    required this.character,
    required this.name,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
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
            // キャラクター画像
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                CharacterAssetService.dailyPracticeImage(character),
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => CircleAvatar(
                  radius: 40,
                  backgroundImage: AssetImage(
                    CharacterAssetService.chatAvatar(character),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // キャラクター名・説明
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
