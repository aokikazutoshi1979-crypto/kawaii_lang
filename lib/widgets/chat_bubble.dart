import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';
import 'dart:io';
import 'package:just_audio/just_audio.dart';
import 'package:kawaii_lang/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    this.avatarPath,           // ← 追加: botアイコン画像パス
    this.showAvatar = true,
    this.onSpeak,              // ← VOICEVOX用カスタム再生コールバック
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
  final String? avatarPath;      // ← 追加
  final bool showAvatar;
  final Future<void> Function(String, void Function(Duration)?)? onSpeak; // ← VOICEVOX用

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble>
    with SingleTickerProviderStateMixin {
  // 再生用
  late final AudioPlayer _player;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _visible = false;
  bool _isTtsLoading = false; // TTS再生待ちローディング状態
  late final AnimationController _karaokeController; // カラオケ進行アニメーション

  final FlutterTts _tts = FlutterTts();

  Widget _labelChip(String text, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _karaokeController = AnimationController(
      vsync: this,
      duration: Duration.zero,
    )..addListener(() { if (mounted) setState(() {}); });
    Future.microtask(() {
      if (mounted) setState(() => _visible = true);
    });
    _player = AudioPlayer();

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
    _karaokeController.dispose();
    _player.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<void> _setTtsLanguage() async {
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
        await _tts.setLanguage('zh-CN');
        break;
      case 'zh_tw':
        await _tts.setLanguage('zh-TW');
        final taiwanVoices = allVoices
            ?.where((v) => v['locale'] == 'zh-TW')
            .toList();
        debugPrint('🎤 zh‑TW voices: $taiwanVoices');
        await _tts.setVoice({
          'name': 'Mei‑Jia',
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
        await _tts.setLanguage('fr-FR');
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
    // 速度は _speak() 側で設定するためここでは上書きしない

    await _tts.setIosAudioCategory(
      IosTextToSpeechAudioCategory.playback,
      [
        IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
        IosTextToSpeechAudioCategoryOptions.allowBluetooth,
      ],
    );
  }

  void _speak() async {
    // ふりがな（ひらがな）があれば優先して読み上げる（日本語のみ）
    final ttsSource = (widget.transcription?.isNotEmpty == true && widget.targetLang == 'ja')
        ? widget.transcription!
        : widget.ttsText;
    if (ttsSource == null || ttsSource.isEmpty) return;
    _karaokeController.stop();
    _karaokeController.reset();
    if (mounted) setState(() => _isTtsLoading = true);
    try {
      if (widget.onSpeak != null) {
        // VOICEVOX経由（日本語学習時）: onPlayStart で音声開始タイミングを受け取る
        await widget.onSpeak!(ttsSource, (audioDuration) {
          if (!mounted) return;
          setState(() => _isTtsLoading = false);
          _karaokeController.duration = audioDuration;
          _karaokeController.forward(from: 0.0);
        });
      } else {
        // iPhoneデフォルトTTS（その他の言語）
        await _setTtsLanguage();
        // 設定画面の速度スライダーを反映する
        final prefs = await SharedPreferences.getInstance();
        final savedRate = prefs.getDouble('tts_speech_rate') ?? 0.40;
        final double rate = Platform.isIOS ? savedRate : (savedRate + 0.45).clamp(0.0, 1.0);
        await _tts.setSpeechRate(rate);
        // 文字数・速度から再生時間を推定してカラオケを開始
        final estimatedMs = ((ttsSource.length * 150.0) / savedRate).round().clamp(500, 20000);
        final completer = Completer<void>();
        _tts.setCompletionHandler(() { if (!completer.isCompleted) completer.complete(); });
        if (mounted) setState(() => _isTtsLoading = false);
        _karaokeController.duration = Duration(milliseconds: estimatedMs);
        _karaokeController.forward(from: 0.0);
        await _tts.speak(ttsSource);
        // TTS完了コールバックまで待機（タイムアウト付き）
        await completer.future.timeout(
          Duration(milliseconds: estimatedMs + 5000),
          onTimeout: () {},
        );
      }
    } finally {
      if (mounted) {
        _karaokeController.stop();
        _karaokeController.reset();
        setState(() => _isTtsLoading = false);
      }
    }
  }

  /// カラオケテロップ風テキスト。progress(0.0〜1.0)に応じて左から色が変わる。
  Widget _karaokeText(String text, double progress, {double fontSize = 16}) {
    final total = text.length;
    final colored = (total * progress).round().clamp(0, total);
    return RichText(
      text: TextSpan(
        children: [
          if (colored > 0)
            TextSpan(
              text: text.substring(0, colored),
              style: TextStyle(
                fontSize: fontSize,
                height: 1.4,
                color: const Color(0xFFE91E63), // ピンク（再生済み）
                fontWeight: FontWeight.bold,
              ),
            ),
          if (colored < total)
            TextSpan(
              text: text.substring(colored),
              style: TextStyle(
                fontSize: fontSize,
                height: 1.4,
                color: Colors.black87,
              ),
            ),
        ],
      ),
    );
  }

  /// highlightBody を行ごとに分割し描画。
  /// [furigana] が指定された場合、1行目（漢字）の直後にふりがな・ローマ字を挿入する。
  Widget _buildHighlightBody(String body, {String? furigana}) {
    final lines = body.split('\n');
    final isJapanese = widget.targetLang == 'ja';
    final progress = _karaokeController.value;
    final children = <Widget>[];
    int nonEmptyCount = 0;
    for (final line in lines) {
      if (line.trim().isEmpty) {
        children.add(const SizedBox(height: 6));
        continue;
      }
      final isKaraokeTarget = isJapanese && nonEmptyCount == 0 && progress > 0;
      nonEmptyCount++;
      children.add(
        isKaraokeTarget
            ? _karaokeText(line, progress)
            : Text(line, style: const TextStyle(fontSize: 16, height: 1.4)),
      );
      // 1行目（漢字）の直後にふりがな・ローマ字を挿入
      if (furigana != null && furigana.isNotEmpty && nonEmptyCount == 1) {
        // ふりがな（常に静的ピンク）
        children.add(
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              furigana,
              style: TextStyle(
                fontSize: 13,
                color: Colors.pink.shade400,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
        // ローマ字（カラオケ対応）
        final romaji = _hiraganaToRomaji(furigana);
        if (romaji.isNotEmpty) {
          children.add(
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: isKaraokeTarget
                  ? _karaokeText(romaji, progress, fontSize: 11)
                  : Text(
                      romaji,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          );
        }
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
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
    final screenWidth = MediaQuery.of(context).size.width;

    final avatarPathLower = (widget.avatarPath ?? '').toLowerCase();
    final isKasumiBubble = widget.isBot && avatarPathLower.contains('kasumi');

    // Character (left) bubble gradients
    const tsumugiGradient = LinearGradient(
      colors: [
        Color(0xFFFFF3F7),
        Color(0xFFFFE9F0),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    const kasumiGradient = LinearGradient(
      colors: [
        Color(0xFFFFE9F0),
        Color(0xFFFFDCE6),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final botBubbleGradient = isKasumiBubble ? kasumiGradient : tsumugiGradient;
    final botBorderColor = Colors.pink.shade200.withOpacity(0.6);
    final userBubbleColor = Colors.blue[100]!;

    final hasRecording = widget.recordingPath != null &&
        widget.recordingPath!.isNotEmpty &&
        File(widget.recordingPath!).existsSync();

    final bool hasHighlight =
        (widget.highlightTitle != null && widget.highlightTitle!.isNotEmpty) ||
        (widget.highlightBody  != null && widget.highlightBody!.isNotEmpty);
    final bool hasTts = widget.isBot && (widget.ttsText?.isNotEmpty ?? false);
    final bool hasBodyText = widget.text.trim().isNotEmpty;

    // ラベル判定（ユーザー側のみ）
    String? labelText;
    Color? labelBg;
    if (!widget.isBot && widget.labelType != null) {
      if (widget.labelType == 'correct') {
        labelText = loc.badgeCorrect;
        labelBg   = const Color(0xFF43A047); // 緑
      } else if (widget.labelType == 'incorrect') {
        labelText = loc.badgeNeedsImprovement;
        labelBg   = const Color(0xFFE53935); // 赤
      }
    }
    final showUserLabel = !widget.isBot && labelText != null;
    final showMainRow =
        hasBodyText || (widget.isBot && !hasHighlight && hasTts);
    final showNativeText = !hasHighlight && widget.nativeText != null;
    // ハイライトがある場合はボックス内に表示するため、ボックス外では重複表示しない
    final showTranscription = !hasHighlight && widget.transcription != null && widget.transcription!.isNotEmpty;
    final showTtsBody =
        widget.showTtsBody && widget.ttsText != null && widget.ttsText!.isNotEmpty;
    final showRecording = hasRecording;
    final hasContentBelowHighlight =
        showUserLabel || showMainRow || showNativeText || showTranscription || showTtsBody || showRecording;
    final mainTextStyle =
        (widget.isBot && widget.labelType == 'info')
            ? const TextStyle(fontSize: 16, height: 1.4)
            : const TextStyle(fontSize: 18, height: 1.4);

    final borderRadius = const BorderRadius.all(Radius.circular(18));

    // ── 吹き出し本体コンテナ（内側の内容は変更なし）
    final bubbleBox = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: widget.isBot ? null : userBubbleColor,
        gradient: widget.isBot ? botBubbleGradient : null,
        borderRadius: borderRadius,
        border: widget.isBot
            ? Border.all(color: botBorderColor, width: 1)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ★ ハイライト（見出し＋訳文）
          if (widget.highlightTitle != null || widget.highlightBody != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.yellow[100],
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
                      if (widget.isBot && (widget.ttsText?.isNotEmpty ?? false))
                        if (hasTts) IconButton(
                          icon: _isTtsLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                                  ),
                                )
                              : const Icon(Icons.volume_up),
                          onPressed: _isTtsLoading ? null : _speak,
                          tooltip: 'Play',
                        ),
                    ],
                  ),
                  if (widget.highlightBody != null) ...[
                    const SizedBox(height: 6),
                    // ふりがなは1行目（漢字）の直後に挿入
                    _buildHighlightBody(
                      widget.highlightBody!,
                      furigana: widget.transcription,
                    ),
                  ],
                ],
              ),
            ),
            if (hasContentBelowHighlight) const SizedBox(height: 8),
          ],

          // ① ユーザー発言でラベルがあるとき
          if (showUserLabel) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  loc.userAnswerHeader,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                _labelChip(labelText!, labelBg!),
              ],
            ),
            const SizedBox(height: 6),
          ],

          // ② 本文
          if (showMainRow)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (hasBodyText)
                  Expanded(
                    child: Text(
                      widget.text,
                      style: mainTextStyle,
                    ),
                  ),
                if (widget.isBot && widget.ttsText != null && widget.ttsText!.isNotEmpty)
                  if (!hasHighlight && hasTts)
                    IconButton(
                      icon: _isTtsLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                              ),
                            )
                          : const Icon(Icons.volume_up),
                      onPressed: _isTtsLoading ? null : _speak,
                    ),
              ],
            ),
          if (showNativeText)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(widget.nativeText!, style: const TextStyle(color: Colors.grey)),
            ),
          if (showTranscription)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                widget.transcription!,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.pink.shade400,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
          if (showTtsBody) ...[
            const SizedBox(height: 8),
            Text(
              widget.ttsText!,
              style: const TextStyle(fontSize: 18, height: 1.4),
            ),
          ],
          // 🎤 録音再生チップ
          if (showRecording) ...[
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
                const Text(
                  'Your voice',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
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
    );

    if (widget.isBot) {
      // ── Bot: 左寄せ [avatar] [bubble]
      const double avatarRadius = 31.5;
      const double avatarSlotWidth = (avatarRadius * 2) + 10; // avatar + gap
      final content = Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (widget.showAvatar) ...[
              CircleAvatar(
                radius: avatarRadius,
                backgroundColor: Colors.white,
                foregroundImage: widget.avatarPath != null
                    ? AssetImage(widget.avatarPath!) as ImageProvider
                    : null,
                child: widget.avatarPath == null
                    ? const Icon(Icons.smart_toy, size: 20, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 10),
            ] else
              const SizedBox(width: avatarSlotWidth),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: screenWidth * 0.65),
              child: bubbleBox,
            ),
          ],
        ),
      );
      if (widget.labelType == 'info') {
        return AnimatedSlide(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          offset: _visible ? Offset.zero : const Offset(0, 0.08),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            opacity: _visible ? 1.0 : 0.0,
            child: content,
          ),
        );
      }
      return content;
    } else {
      // ── User: 右寄せ [bubble]
      final content = Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: screenWidth * 0.74),
              child: bubbleBox,
            ),
          ],
        ),
      );
      return AnimatedSlide(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        offset: _visible ? Offset.zero : const Offset(0, 0.08),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          opacity: _visible ? 1.0 : 0.0,
          child: content,
        ),
      );
    }
  }
}

// ── ひらがな → ヘボン式ローマ字変換
String _hiraganaToRomaji(String text) {
  const combos = <String, String>{
    'きゃ':'kya','きゅ':'kyu','きょ':'kyo',
    'しゃ':'sha','しゅ':'shu','しょ':'sho',
    'ちゃ':'cha','ちゅ':'chu','ちょ':'cho',
    'にゃ':'nya','にゅ':'nyu','にょ':'nyo',
    'ひゃ':'hya','ひゅ':'hyu','ひょ':'hyo',
    'みゃ':'mya','みゅ':'myu','みょ':'myo',
    'りゃ':'rya','りゅ':'ryu','りょ':'ryo',
    'ぎゃ':'gya','ぎゅ':'gyu','ぎょ':'gyo',
    'じゃ':'ja', 'じゅ':'ju', 'じょ':'jo',
    'びゃ':'bya','びゅ':'byu','びょ':'byo',
    'ぴゃ':'pya','ぴゅ':'pyu','ぴょ':'pyo',
  };
  const singles = <String, String>{
    'あ':'a', 'い':'i', 'う':'u', 'え':'e', 'お':'o',
    'か':'ka','き':'ki','く':'ku','け':'ke','こ':'ko',
    'さ':'sa','し':'shi','す':'su','せ':'se','そ':'so',
    'た':'ta','ち':'chi','つ':'tsu','て':'te','と':'to',
    'な':'na','に':'ni','ぬ':'nu','ね':'ne','の':'no',
    'は':'ha','ひ':'hi','ふ':'fu','へ':'he','ほ':'ho',
    'ま':'ma','み':'mi','む':'mu','め':'me','も':'mo',
    'や':'ya','ゆ':'yu','よ':'yo',
    'ら':'ra','り':'ri','る':'ru','れ':'re','ろ':'ro',
    'わ':'wa','を':'wo','ん':'n',
    'が':'ga','ぎ':'gi','ぐ':'gu','げ':'ge','ご':'go',
    'ざ':'za','じ':'ji','ず':'zu','ぜ':'ze','ぞ':'zo',
    'だ':'da','ぢ':'di','づ':'zu','で':'de','ど':'do',
    'ば':'ba','び':'bi','ぶ':'bu','べ':'be','ぼ':'bo',
    'ぱ':'pa','ぴ':'pi','ぷ':'pu','ぺ':'pe','ぽ':'po',
    'ー':'-','　':' ',' ':' ',
  };

  final buf = StringBuffer();
  int i = 0;
  while (i < text.length) {
    // 小さいっ：次の子音を重ねる
    if (text[i] == 'っ') {
      if (i + 1 < text.length) {
        String? nextRomaji;
        if (i + 2 < text.length) nextRomaji = combos[text.substring(i + 1, i + 3)];
        nextRomaji ??= singles[text[i + 1]];
        if (nextRomaji != null && nextRomaji.isNotEmpty) buf.write(nextRomaji[0]);
      }
      i++;
      continue;
    }
    // 2文字組み合わせ（優先）
    if (i + 2 <= text.length) {
      final two = text.substring(i, i + 2);
      final r = combos[two];
      if (r != null) { buf.write(r); i += 2; continue; }
    }
    // 1文字
    final r = singles[text[i]];
    buf.write(r ?? text[i]);
    i++;
  }
  return buf.toString();
}

// ── LINE風しっぽ三角形
class _ChatTailPainter extends CustomPainter {
  final Color? color;
  final Gradient? gradient;
  final Color? borderColor;
  final bool pointsLeft; // true = bot(左向き), false = user(右向き)

  const _ChatTailPainter({
    required this.pointsLeft,
    this.color,
    this.gradient,
    this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    if (pointsLeft) {
      // Bot: 右辺直角 → 左下に向かう三角形（吹き出し左側に接続）
      path.moveTo(size.width, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
    } else {
      // User: 左辺直角 → 右下に向かう三角形（吹き出し右側に接続）
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    }
    path.close();

    final fill = Paint()..style = PaintingStyle.fill;
    if (gradient != null) {
      fill.shader = gradient!.createShader(Offset.zero & size);
    } else if (color != null) {
      fill.color = color!;
    }
    canvas.drawPath(path, fill);

    if (borderColor != null) {
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = borderColor!;
      canvas.drawPath(path, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _ChatTailPainter old) =>
      old.color != color ||
      old.gradient != gradient ||
      old.borderColor != borderColor ||
      old.pointsLeft != pointsLeft;
}
