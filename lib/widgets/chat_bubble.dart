import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:io';
import 'package:just_audio/just_audio.dart';
import 'package:kawaii_lang/l10n/app_localizations.dart';

class ChatBubble extends StatefulWidget {
  const ChatBubble({
    Key? key,
    required this.text,
    this.nativeText,
    required this.isBot,
    this.ttsText,
    this.targetLang,
    this.transcription,
    this.recordingPath,        // 🎤 ユーザー録音のローカルパス
    this.recordingDurationMs,  // ⏱️ 表示用
    this.labelType,
    this.highlightTitle,
    this.highlightBody,
    this.showTtsBody = true,
  }) : super(key: key);

  final String text;
  final String? nativeText;
  final bool isBot;
  final String? ttsText;
  final String? targetLang;      // 例: 'en', 'ja' 等
  final String? transcription;
  final String? recordingPath;
  final int? recordingDurationMs;
  final String? labelType;
  final String? highlightTitle;
  final String? highlightBody;
  final bool showTtsBody;
  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  // 再生用
  late final AudioPlayer _player;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  final FlutterTts _tts = FlutterTts();

  Widget _labelChip(String text, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(50), // 角丸50px相当
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12, // 本文より気持ち小さめ
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();

    // 録音ファイルがある場合のみプレイヤーをセット
    final rp = widget.recordingPath;
    if (rp != null && rp.isNotEmpty && File(rp).existsSync()) {
      _player.setFilePath(rp).then((_) async {
        final d = await _player.duration;
        if (mounted) {
          setState(() {
            _duration = d ?? Duration(milliseconds: widget.recordingDurationMs ?? 0);
          });
        }
      });

      _player.playerStateStream.listen((s) {
        final playing = s.playing && s.processingState == ProcessingState.ready;
        if (mounted) setState(() => _isPlaying = playing);
      });
      _player.positionStream.listen((p) {
        if (mounted) setState(() => _position = p);
      });
    }
  }

  @override
  void dispose() {
    _player.dispose();
    _tts.stop(); // ← 追加
    super.dispose();
  }

  Future<void> _setTtsLanguage() async {
    // ① —— まず最初に一度だけサポート言語・音声一覧を取得
    final List<dynamic>? langs = await _tts.getLanguages;
    debugPrint('🎤 Supported TTS languages: $langs');

    final List<dynamic>? allVoices = await _tts.getVoices;
    debugPrint('🎤 Supported TTS voices: $allVoices');

    switch (widget.targetLang?.toLowerCase()) {
      case 'en':
        await _tts.setLanguage('en-US');
        break;
      case 'ja':
        await _tts.setLanguage('ja-JP');
        break;
      case 'zh':
        // Chinese (Simplified)
        await _tts.setLanguage('zh-CN');
        break;
      case 'zh_tw':  // 元コードの分岐をそのまま使う場合
       // 正しい BCP-47 形式をセット
        await _tts.setLanguage('zh-TW');

        // （デバッグ用）台湾音声だけフィルターしてみる
        final taiwanVoices = allVoices
            ?.where((v) => v['locale'] == 'zh-TW')
            .toList();
        debugPrint('🎤 zh‑TW voices: $taiwanVoices');

        await _tts.setVoice({
          'name': 'Mei‑Jia',    // 実機で getVoices して一致を確認
          'locale': 'zh-TW',
        });
        break;
      case 'ko':
        await _tts.setLanguage('ko-KR');
        break;
      case 'es':
        await _tts.setLanguage('es-ES');
        break;
      case 'fr':
        // 1) 言語を fr‑FR に設定
        await _tts.setLanguage('fr-FR');

        // 2) iOS 標準の女性声 “Marie” を指定
        await _tts.setVoice({
          'name': 'Audrey',
          'locale': 'fr-FR',
        });
        break;
      case 'de':
        await _tts.setLanguage('de-DE');
        break;
      case 'vi':
        await _tts.setLanguage('vi-VN');
        break;
      case 'id':
        await _tts.setLanguage('id-ID');
        break;
      default:
        await _tts.setLanguage('en-US');
    }
    await _tts.setSpeechRate(0.4); // 任意：ゆっくり読み上げ

    // ✅ iOSでサイレントモードでも再生されるようにする
    await _tts.setIosAudioCategory(
      IosTextToSpeechAudioCategory.playback,
      [
        IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
        IosTextToSpeechAudioCategoryOptions.allowBluetooth,
      ],
    );
  }

  void _speak() async {
    if (widget.ttsText != null && widget.ttsText!.isNotEmpty) {
      await _setTtsLanguage(); // 言語設定を先に実行
      await _tts.speak(widget.ttsText!);
    }
  }

  String _mmss(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      if (_position >= (_duration - const Duration(milliseconds: 200))) {
        await _player.seek(Duration.zero);
      }
      await _player.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final bubbleColor = widget.isBot ? Colors.white : (Colors.blue[100]!);

    final hasRecording = widget.recordingPath != null &&
        widget.recordingPath!.isNotEmpty &&
        File(widget.recordingPath!).existsSync();

    final bool hasHighlight =
        (widget.highlightTitle != null && widget.highlightTitle!.isNotEmpty) ||
        (widget.highlightBody  != null && widget.highlightBody!.isNotEmpty);
    final bool hasTts = widget.isBot && (widget.ttsText?.isNotEmpty ?? false);

    // ラベル判定（ユーザー側のみ）
    String? labelText;
    Color? labelBg;
    if (!widget.isBot && widget.labelType != null) {
      if (widget.labelType == 'correct') {
        labelText = loc.badgeCorrect;      // arb: "正解"
        labelBg   = Colors.red;
      } else if (widget.labelType == 'incorrect') {
        labelText = loc.badgeNeedsImprovement;    // arb: "不正解"
        labelBg   = const Color(0xFF1E88E5); // 青色に変更（お好みでOK）
      }
    }

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        FractionallySizedBox(
          widthFactor: 0.95,
          child: Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ★ ハイライト（見出し＋訳文）— 必要なときだけ表示
                if (widget.highlightTitle != null || widget.highlightBody != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.yellow[100],            // ← 黄色背景
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (widget.highlightTitle != null)
                              Expanded(
                                child: Text(
                                  widget.highlightTitle!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            // 見出し行の右端にTTS（訳文を読み上げ）
                            if (widget.isBot && (widget.ttsText?.isNotEmpty ?? false))
                              if (hasTts) IconButton(
                                icon: const Icon(Icons.volume_up),
                                onPressed: _speak,
                                tooltip: 'Play',
                              ),
                          ],
                        ),
                        if (widget.highlightBody != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            widget.highlightBody!,
                            style: const TextStyle(fontSize: 16, height: 1.4),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 8), // ハイライトと本文の間を1行開ける
                ],

                // ① ユーザー発言でラベルがあるときだけ、ヘッダ行を表示
                if (!widget.isBot && labelText != null) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        loc.userAnswerHeader, // 例: あなたの回答（arbで用意）
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _labelChip(labelText!, labelBg!), // ← 赤/青の角丸チップ
                    ],
                  ),
                  const SizedBox(height: 6),
                ],

                // ② 本文（← ここからはラベルを外す）
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        widget.text, // 例: こんにちは
                        style: const TextStyle(fontSize: 18, height: 1.4),
                      ),
                    ),
                    // BotのときだけTTSボタン
                    if (widget.isBot && widget.ttsText != null && widget.ttsText!.isNotEmpty)
                      if (!hasHighlight && hasTts)
                        IconButton(
                          icon: const Icon(Icons.volume_up),
                          onPressed: _speak,
                        ),
                  ],
                ),
                if (!hasHighlight && widget.nativeText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(widget.nativeText!, style: TextStyle(color: Colors.grey)),
                  ),
                if (!hasHighlight && widget.transcription != null && widget.transcription!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(widget.transcription!, style: TextStyle(fontStyle: FontStyle.italic)),
                  ),
                if (widget.showTtsBody && widget.ttsText != null && widget.ttsText!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.ttsText!,
                    style: const TextStyle(fontSize: 18, height: 1.4),
                  ),
                ],
                // 🎤 録音がある場合は、下に「再生チップ」を表示
                if (hasRecording) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: _togglePlay,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.isBot ? Colors.grey.shade600 : const Color(0xFF1E88E5),
                          ),
                          child: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_mmss(_position)} / ${_mmss(_duration.inMilliseconds > 0 ? _duration : Duration(milliseconds: widget.recordingDurationMs ?? 0))}',
                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        // ▲ Bot気泡の三角形（色を気泡と合わせる）
        if (widget.isBot)
          Positioned(
            top: 0,
            child: CustomPaint(
              size: const Size(20, 10),
              painter: TrianglePainter(color: bubbleColor),
            ),
          ),
      ],
    );
  }
}

class TrianglePainter extends CustomPainter {
  final Color color;

  TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
