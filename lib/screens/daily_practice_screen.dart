import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../services/character_asset_service.dart';
import '../services/subscription_service.dart';
import '../services/subscription_state.dart';
import 'daily_complete_screen.dart';
import 'subscription_screen.dart';
import '../services/daily_practice_service.dart';
import '../services/gpt_service.dart';
import '../services/prompt_builders.dart';
import '../services/speech_service.dart';
import '../services/voicevox_tts_service.dart';
import '../widgets/chat_bubble.dart' show hiraganaToRomaji;
import '../widgets/tumugi_bubble.dart';
import '../widgets/mic_area.dart' show LiveWaveformBar;

enum _PracticeStep {
  idle,      // フレーズ表示中、まだ聞いていない
  listened,  // 1回以上VOICEVOX再生済み（録音ボタンがアクティブ）
  recording, // 録音中
  result,    // 正解/不正解判定後
}

class DailyPracticeScreen extends StatefulWidget {
  const DailyPracticeScreen({super.key});

  @override
  State<DailyPracticeScreen> createState() => _DailyPracticeScreenState();
}

class _DailyPracticeScreenState extends SubscriptionState<DailyPracticeScreen> {
  _PracticeStep _step = _PracticeStep.idle;
  bool _isCorrect = false;
  bool _isLoading = true;
  bool _isProcessing = false; // STT→GPT処理中フラグ

  bool _isPremium = false;
  int _todaysPracticeCount = 0;
  static const int _freeLimit = 10;
  bool get _isPremiumUser =>
      _isPremium ||
      hasSubOnDevice ||
      SubscriptionService.instance.subscriptionActiveNotifier.value;

  bool get _hasReachedLimit => !_isPremiumUser && _todaysPracticeCount >= _freeLimit;
  bool _isListeningTts = false; // VOICEVOX読み込み中フラグ

  // 波形用振幅キュー（チャット画面と同じ方式）
  final Queue<double> _ampQueue = Queue<double>();
  double _ampEma = 0.0;

  // リトライ制限
  int _attemptCount = 0;
  static const int _maxAttempts = 5;

  // カラオケ
  Timer? _karaokeTimer;
  int _karaokeIndex = 0;

  // ふりがな（ひらがな転写）
  String? _furigana;

  Map<String, dynamic>? _question;
  String _selectedCharacter = CharacterAssetService.defaultCharacter;
  int _streakDays = 0;

  late VoicevoxTtsService _voicevoxService;
  late SpeechService _speechService;

  @override
  void initState() {
    super.initState(); // SubscriptionState.initState() が hasSubOnDevice を取得
    _voicevoxService = VoicevoxTtsService();
    _speechService = SpeechService();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final character = CharacterAssetService.normalize(
      prefs.getString(CharacterAssetService.prefKey),
    );
    final userLevel = prefs.getString('user_level') ?? 'beginner';
    final streakDays = prefs.getInt('streak_days') ?? 0;

    final premium = await SubscriptionService.instance.checkSubscriptionOnDevice();
    final count = await DailyPracticeService.instance.getTodaysPracticeCount();

    final question = await DailyPracticeService.instance.getTodaysQuestion(
      userLevel: userLevel,
    );

    if (mounted) {
      setState(() {
        _selectedCharacter = character;
        _question = question;
        _streakDays = streakDays;
        _isPremium = premium;
        _todaysPracticeCount = count;
        _attemptCount = 0;
        _karaokeIndex = 0;
        _isLoading = false;
      });
      _fetchFurigana();
    }
  }

  // ふりがな（ひらがな転写）をGPT経由で非同期取得
  Future<void> _fetchFurigana() async {
    final text = _japaneseText;
    if (text.isEmpty || !mounted) return;
    final loc = AppLocalizations.of(context);
    if (loc == null) return;
    final prompt = PromptBuilders.buildSimilarQuestionTtsPrompt(
      translatedText: text,
      targetLang: 'ja',
    );
    // gpt-4o-miniは漢字読みの精度がgpt-3.5-turboより大幅に高い
    final res = await GptService.getChatResponse(prompt, text, loc, model: 'gpt-4o-mini');
    if (res != null && res.trim().isNotEmpty && mounted) {
      // GPTが説明文を混ぜて返すことがあるため、ひらがな・長音符のみ抽出する
      final hiraganaOnly = RegExp(r'[ぁ-んー]')
          .allMatches(res)
          .map((m) => m.group(0)!)
          .join();
      if (hiraganaOnly.isNotEmpty) {
        setState(() => _furigana = hiraganaOnly);
      }
    }
  }

  // ---------- helpers ----------

  String get _japaneseText {
    final t = _question?['translations'];
    if (t is Map) return (t['ja'] as String?) ?? '';
    return '';
  }

  String get _nativeText {
    // ネイティブ言語はenをフォールバックとして使う
    final t = _question?['translations'];
    if (t is Map) {
      final loc = AppLocalizations.of(context);
      final code = loc?.localeName ?? 'en';
      final base = code.split('_').first;
      return (t[code] as String?) ?? (t[base] as String?) ?? (t['en'] as String?) ?? '';
    }
    return '';
  }

  String get _questionId {
    return (_question?['id'] as String?) ?? '';
  }

  // ---------- VOICEVOX ----------

  Future<void> _listenPhrase() async {
    // ふりがなが取得済みならそちらをTTS対象にする（より自然な読み上げのため）
    final text = (_furigana != null && _furigana!.isNotEmpty) ? _furigana! : _japaneseText;
    if (text.isEmpty) return;
    setState(() {
      _isListeningTts = true;
      _karaokeIndex = 0;
    });
    await _voicevoxService.speak(
      text,
      _selectedCharacter,
      onPlayStart: (duration) {
        if (mounted) _startKaraoke(text, duration);
      },
      onDailyLimitFallback: (_) {},
    );
    if (mounted) {
      setState(() {
        _isListeningTts = false;
        if (_step == _PracticeStep.idle) _step = _PracticeStep.listened;
      });
    }
  }

  void _startKaraoke(String text, Duration duration) {
    _karaokeTimer?.cancel();
    if (!mounted) return;
    setState(() => _karaokeIndex = 0);
    final total = text.runes.length;
    if (total == 0 || duration.inMilliseconds <= 0) return;
    final intervalMs = (duration.inMilliseconds / total).round().clamp(50, 1000);
    _karaokeTimer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      if (!mounted) { timer.cancel(); return; }
      if (_karaokeIndex >= total) { timer.cancel(); return; }
      setState(() => _karaokeIndex++);
    });
  }

  // ---------- STT ----------

  Future<void> _startRecording() async {
    final available = await _speechService.initialize('ja-JP');
    if (!available) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('マイクが使用できません')),
        );
      }
      return;
    }
    _ampQueue.clear();
    _ampEma = 0.0;
    setState(() => _step = _PracticeStep.recording);
    _speechService.listen(
      (result) => _handleSTTResult(result),
      onSoundLevel: (level) {
        if (!mounted) return;
        const alpha = 0.25;
        _ampEma = (_ampEma * (1 - alpha)) + (level * alpha);
        setState(() {
          _ampQueue.add(_ampEma);
          while (_ampQueue.length > 40) _ampQueue.removeFirst();
        });
      },
    );
  }

  Future<void> _stopRecording() async {
    await _speechService.stop();
    if (mounted && _step == _PracticeStep.recording) {
      setState(() {
        _step = _PracticeStep.listened;
        _ampQueue.clear();
      });
    }
  }

  Future<void> _handleSTTResult(String recognized) async {
    if (!mounted) return;
    setState(() {
      _step = _PracticeStep.listened;
      _isProcessing = true;
    });

    final loc = AppLocalizations.of(context)!;
    final correct = _japaneseText;
    final prompt = PromptBuilders.buildListeningPrompt(
      userAnswer: recognized,
      originalQuestion: correct,
      targetLang: 'Japanese',
      nativeLang: 'English',
      furigana: _furigana,
    );

    final response = await GptService.getChatResponse(prompt, recognized, loc, model: 'gpt-4o-mini');
    // GPTが「1」や 1. など余分な文字を返すことがあるため、最初の数字で判定する
    final digit = RegExp(r'[12]').firstMatch(response ?? '')?.group(0);
    final isCorrect = digit == '1';

    if (!mounted) return;

    if (isCorrect) {
      await DailyPracticeService.instance.markAsCompleted(_questionId);
      await DailyPracticeService.instance.incrementPracticeCount();
      if (mounted) setState(() => _todaysPracticeCount++);
    }

    setState(() {
      _isCorrect = isCorrect;
      _step = _PracticeStep.result;
      _isProcessing = false;
      _attemptCount++;
    });
  }

  // ---------- 次のフレーズを読み込む ----------

  Future<void> _loadNextPhrase() async {
    _karaokeTimer?.cancel();
    setState(() {
      _isLoading = true;
      _step = _PracticeStep.idle;
      _attemptCount = 0;
      _karaokeIndex = 0;
      _furigana = null;
    });
    await DailyPracticeService.instance.clearCurrentQuestion();
    final prefs = await SharedPreferences.getInstance();
    final userLevel = prefs.getString('user_level') ?? 'beginner';
    final question = await DailyPracticeService.instance.getTodaysQuestion(
      userLevel: userLevel,
    );
    if (mounted) {
      setState(() {
        _question = question;
        _isLoading = false;
      });
      _fetchFurigana();
    }
  }

  // ---------- リセット ----------

  void _retry() {
    setState(() {
      _step = _PracticeStep.listened;
      _isProcessing = false;
    });
  }

  // ---------- build ----------

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(loc.dailyPracticeTitle),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFFFF8FB),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _question == null
              ? Center(child: Text(loc.noHistoryData))
              : _buildBody(loc),
    );
  }

  Widget _buildBody(AppLocalizations loc) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. キャラクター画像
          _buildCharacterImage(),
          const SizedBox(height: 8),

          // 2. セリフバブル
          _buildBubble(loc),
          const SizedBox(height: 16),

          // 3. フレーズカード
          _buildPhraseCard(loc),
          const SizedBox(height: 20),

          // 4. ステップボタン
          _buildStepArea(loc),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCharacterImage() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.30,
      child: Image.asset(
        CharacterAssetService.dailyPracticeImage(_selectedCharacter),
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Image.asset(
          CharacterAssetService.chatAvatar(_selectedCharacter),
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildBubble(AppLocalizations loc) {
    String bubbleText;
    if (_step == _PracticeStep.result) {
      bubbleText = _isCorrect
          ? loc.tumugiAccuracyCorrect
          : loc.tumugiAccuracyIncorrect;
    } else {
      bubbleText = loc.dailyPracticeEncourage;
    }
    return TumugiBubble(
      text: bubbleText,
      avatarPath: CharacterAssetService.chatAvatar(_selectedCharacter),
    );
  }

  // ふりがなからローマ字カラオケ用インデックスを計算
  int get _romajiKaraokeIndex {
    final phraseLen = _japaneseText.runes.length;
    if (phraseLen == 0 || _furigana == null) return 0;
    final romaji = hiraganaToRomaji(_furigana!);
    return (_karaokeIndex / phraseLen * romaji.length).round().clamp(0, romaji.length);
  }

  // ふりがなカラオケ用インデックスを計算
  int get _furiganaKaraokeIndex {
    final phraseLen = _japaneseText.runes.length;
    if (phraseLen == 0 || _furigana == null) return 0;
    final furiganaLen = _furigana!.runes.length;
    return (_karaokeIndex / phraseLen * furiganaLen).round().clamp(0, furiganaLen);
  }

  // ふりがなカラオケ用 Widget
  Widget _buildFuriganaKaraoke() {
    final f = _furigana;
    if (f == null || f.isEmpty) return const SizedBox.shrink();
    final chars = f.runes.map(String.fromCharCode).toList();
    final idx = _furiganaKaraokeIndex;
    final highlighted = chars.take(idx).join();
    final remaining = chars.skip(idx).join();
    const double fontSize = 28 * 2 / 3;
    return RichText(
      text: TextSpan(
        children: [
          if (highlighted.isNotEmpty)
            TextSpan(
              text: highlighted,
              style: TextStyle(
                fontSize: fontSize,
                color: Colors.pink.shade400,
                fontWeight: FontWeight.bold,
              ),
            ),
          if (remaining.isNotEmpty)
            TextSpan(
              text: remaining,
              style: TextStyle(
                fontSize: fontSize,
                color: Colors.pink.shade300,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  // ローマ字カラオケ用 Widget
  Widget _buildRomajiKaraoke() {
    final f = _furigana;
    if (f == null || f.isEmpty) return const SizedBox.shrink();
    final romaji = hiraganaToRomaji(f);
    if (romaji.isEmpty) return const SizedBox.shrink();
    final idx = _romajiKaraokeIndex;
    final highlighted = romaji.substring(0, idx);
    final remaining = romaji.substring(idx);
    const double fontSize = 28 * 2 / 3;
    return RichText(
      text: TextSpan(
        children: [
          if (highlighted.isNotEmpty)
            TextSpan(
              text: highlighted,
              style: TextStyle(
                fontSize: fontSize,
                color: Colors.pink.shade400,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          if (remaining.isNotEmpty)
            TextSpan(
              text: remaining,
              style: TextStyle(
                fontSize: fontSize,
                color: Colors.grey.shade500,
                letterSpacing: 0.5,
              ),
            ),
        ],
      ),
    );
  }

  // カラオケ用 TextSpan リスト
  List<InlineSpan> _buildKaraokeSpans() {
    final text = _japaneseText;
    if (text.isEmpty) return [];
    final chars = text.runes.map(String.fromCharCode).toList();
    final idx = _karaokeIndex.clamp(0, chars.length);
    final highlighted = chars.take(idx).join();
    final remaining = chars.skip(idx).join();
    return [
      TextSpan(
        text: highlighted,
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.pink.shade400,
        ),
      ),
      if (remaining.isNotEmpty)
        TextSpan(
          text: remaining,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
    ];
  }

  Widget _buildPhraseCard(AppLocalizations loc) {
    final spans = _buildKaraokeSpans();
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // カラオケ付き日本語テキスト
            RichText(
              text: TextSpan(
                children: spans.isNotEmpty
                    ? spans
                    : [
                        TextSpan(
                          text: _japaneseText,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
              ),
            ),
            // ふりがな（カラオケ）
            if (_furigana != null && _furigana!.isNotEmpty) ...[
              const SizedBox(height: 4),
              _buildFuriganaKaraoke(),
              const SizedBox(height: 2),
              // ローマ字カラオケ
              _buildRomajiKaraoke(),
            ],
            const SizedBox(height: 8),
            // ネイティブ語訳
            Text(
              _nativeText,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLimitCard(AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.pink.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.pink.shade100),
      ),
      child: Column(
        children: [
          Text(
            loc.dailyLimitTitle,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.pink.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            loc.dailyLimitMessage,
            style: TextStyle(fontSize: 14, color: Colors.pink.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
              ).then((_) async {
                if (!mounted) return;
                final premium = await SubscriptionService.instance.checkSubscriptionOnDevice();
                if (mounted) setState(() => _isPremium = premium);
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink.shade400,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(loc.dailyLimitUpgrade),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                loc.dailyLimitClose,
                style: TextStyle(color: Colors.pink.shade400),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepArea(AppLocalizations loc) {
    if (_hasReachedLimit) {
      return _buildLimitCard(loc);
    }
    if (_isProcessing) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (_step) {
      case _PracticeStep.idle:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildListenButton(loc),
            const SizedBox(height: 12),
            _buildTryButton(loc, enabled: false),
          ],
        );

      case _PracticeStep.listened:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildListenButton(loc),
            const SizedBox(height: 12),
            _buildTryButton(loc, enabled: true),
          ],
        );

      case _PracticeStep.recording:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LiveWaveformBar(samples: _ampQueue.toList()),
            const SizedBox(height: 8),
            Text(
              loc.recordingLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.pinkAccent),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _stopRecording,
              child: Text(loc.dailyPracticeStopButton),
            ),
          ],
        );

      case _PracticeStep.result:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 結果バッジ
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: _isCorrect ? Colors.green.shade50 : Colors.pink.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isCorrect ? Colors.green.shade200 : Colors.pink.shade200,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isCorrect ? Icons.check_circle : Icons.favorite_outline,
                    color: _isCorrect ? Colors.green : Colors.pink.shade400,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isCorrect ? loc.badgeCorrect : loc.badgeNeedsImprovement,
                    style: TextStyle(
                      color: _isCorrect ? Colors.green.shade700 : Colors.pink.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // 不正解の場合のみ：インラインヒント表示
            if (!_isCorrect && _furigana != null && _furigana!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.pink.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.hintLabel,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.pink.shade400,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _furigana!,
                      style: const TextStyle(fontSize: 18, color: Colors.black87),
                    ),
                    Text(
                      hiraganaToRomaji(_furigana!),
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            // ▶ もう一度聞く
            OutlinedButton.icon(
              icon: const Icon(Icons.volume_up_outlined),
              label: Text(loc.dailyPracticeListenButton),
              onPressed: _listenPhrase,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.pink.shade400,
                side: BorderSide(color: Colors.pink.shade200),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            // もう一回言う（上限5回まで）
            if (_attemptCount < _maxAttempts) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.mic_outlined),
                label: Text(loc.retryButton),
                onPressed: _retry,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.pink.shade400,
                  side: BorderSide(color: Colors.pink.shade200),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
            const SizedBox(height: 8),
            // 完了 → DailyCompleteScreenへ
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DailyCompleteScreen(
                      practicedPhrase: _japaneseText,
                      streakDays: _streakDays,
                      character: _selectedCharacter,
                      todayPracticeCount: _todaysPracticeCount,
                    ),
                  ),
                ).then((_) {
                  if (!mounted) return;
                  // 制限中でも次フレーズを読み込む（ステップエリアが制限カードを表示する）
                  _loadNextPhrase();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink.shade300,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(loc.dailyPracticeDoneButton, style: const TextStyle(fontSize: 16)),
            ),
          ],
        );
    }
  }

  Widget _buildListenButton(AppLocalizations loc) {
    return ElevatedButton.icon(
      icon: _isListeningTts
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.pink.shade700),
              ),
            )
          : const Icon(Icons.volume_up),
      label: Text(loc.dailyPracticeListenButton),
      onPressed: _isListeningTts ? null : _listenPhrase,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.pink.shade100,
        foregroundColor: Colors.pink.shade700,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }

  Widget _buildTryButton(AppLocalizations loc, {required bool enabled}) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.mic),
      label: Text(loc.dailyPracticeTryButton),
      onPressed: enabled ? _startRecording : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: enabled ? Colors.pink.shade400 : Colors.grey.shade300,
        foregroundColor: enabled ? Colors.white : Colors.grey.shade500,
        elevation: enabled ? 2 : 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }

  @override
  void dispose() {
    _karaokeTimer?.cancel();
    _voicevoxService.dispose();
    _speechService.stop();
    super.dispose();
  }
}
