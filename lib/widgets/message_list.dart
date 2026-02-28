import 'package:flutter/material.dart';
import 'chat_bubble.dart';
import 'tumugi_bubble.dart';

class MessageList extends StatelessWidget {
  final List<Map<String, dynamic>> messages;
  final Widget? header;
  final String? botAvatarPath; // ← 追加: bot吹き出しに表示するキャラアイコン

  const MessageList({
    required this.messages,
    this.header,
    this.botAvatarPath, // ← 追加
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (header != null) header!,
        ...messages.map((msg) {
          if (msg['role'] == 'tumugi') {
            return TumugiBubble(
              text: msg['text'] ?? '',
              avatarPath: msg['avatarPath'],
            );
          }
          final isBot = msg['role'] != 'user';
          return ChatBubble(
            text: msg['text'] ?? '',
            nativeText: msg['nativeText'],
            transcription: msg['transcription'],
            isBot: isBot,
            ttsText: msg['tts'],
            targetLang: msg['targetLang'],
            recordingPath: msg['audioPath'],
            recordingDurationMs: msg['durationMs'],
            labelType: msg['labelType'],
            highlightTitle: msg['highlightTitle'],
            highlightBody:  msg['highlightBody'],
            showTtsBody: msg['showTtsBody'] ?? true,
            showAvatar: msg['showAvatar'] ?? true,
            // bot メッセージにキャラアバターを渡す（userは不要なので null）
            avatarPath: isBot ? (msg['avatarPath'] ?? botAvatarPath) : null,
          );
        }),
      ],
    );
  }
}
