import 'package:flutter/material.dart';
import 'chat_bubble.dart';
import 'tumugi_bubble.dart';

class MessageList extends StatelessWidget {
  final List<Map<String, dynamic>> messages;
  final Widget? header;
  final String? botAvatarPath; // ← 追加: bot吹き出しに表示するキャラアイコン
  final Future<void> Function(String, void Function(Duration)?)? onSpeak; // ← VOICEVOX用コールバック

  const MessageList({
    required this.messages,
    this.header,
    this.botAvatarPath, // ← 追加
    this.onSpeak,       // ← VOICEVOX用
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (header != null) header!,
        ...messages.map((msg) {
          if (msg['role'] == 'thinking') {
            return _ThinkingBubble(
              text: msg['text'] ?? '',
              avatarPath: msg['avatarPath'],
              fadingOut: msg['fadingOut'] == true,
            );
          }
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
            // VOICEVOX: botバブルのみにコールバックを渡す
            onSpeak: isBot ? onSpeak : null,
          );
        }),
      ],
    );
  }
}

class _ThinkingBubble extends StatefulWidget {
  const _ThinkingBubble({
    required this.text,
    required this.avatarPath,
    required this.fadingOut,
  });

  final String text;
  final String? avatarPath;
  final bool fadingOut;

  @override
  State<_ThinkingBubble> createState() => _ThinkingBubbleState();
}

class _ThinkingBubbleState extends State<_ThinkingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _floatAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    final curved = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _floatAnimation = Tween<double>(begin: 0, end: -2).animate(curved);
    _scaleAnimation = Tween<double>(begin: 0.985, end: 1.0).animate(curved);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      opacity: widget.fadingOut ? 0.0 : 1.0,
      child: AnimatedBuilder(
        animation: _controller,
        child: TumugiBubble(
          text: widget.text,
          avatarPath: widget.avatarPath,
        ),
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _floatAnimation.value),
            child: Transform.scale(
              scale: _scaleAnimation.value,
              alignment: Alignment.centerLeft,
              child: child,
            ),
          );
        },
      ),
    );
  }
}
