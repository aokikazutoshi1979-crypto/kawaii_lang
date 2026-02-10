import 'package:flutter/material.dart';
import 'chat_bubble.dart';
import 'tumugi_bubble.dart';

class MessageList extends StatelessWidget {
  final List<Map<String, dynamic>> messages;

  const MessageList({required this.messages, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: messages.map((msg) {
        if (msg['role'] == 'tumugi') {
          return TumugiBubble(
            text: msg['text'] ?? '',
            avatarPath: msg['avatarPath'],
          );
        }
        final isBot = msg['role'] != 'user';
        final tts = msg['tts']; // ← 🔊 TTS対象テキストがある場合
        return ChatBubble(
          text: msg['text'] ?? '',
          nativeText: msg['nativeText'],    // ← ここを追加
          transcription: msg['transcription'],  // ← 追加
          isBot: isBot,
          ttsText: msg['tts'], // 🔊 再生対象
          targetLang: msg['targetLang'], // 🌐 言語を渡す
          recordingPath: msg['audioPath'], // 🎤 追加
          recordingDurationMs: msg['durationMs'],   // ← あれば渡す
          labelType: msg['labelType'], // 'correct' | 'incorrect' | null
          highlightTitle: msg['highlightTitle'],
          highlightBody:  msg['highlightBody'],
          showTtsBody: msg['showTtsBody'] ?? true,
        );
      }).toList(),
    );
  }
}
