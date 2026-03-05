import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../services/character_asset_service.dart';
import 'daily_complete_screen.dart';
import '../services/daily_practice_service.dart';
import '../services/gpt_service.dart';
import '../services/prompt_builders.dart';
import '../services/speech_service.dart';
import '../services/voicevox_tts_service.dart';
import '../widgets/tumugi_bubble.dart';
import '../widgets/wave_animation.dart';

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

class _DailyPracticeScreenState extends State<DailyPracticeScreen> {
  _PracticeStep _step = _PracticeStep.idle;
  bool _isCorrect = false;
  bool _isLoading = true;
  bool _showFurigana = true;
  bool _isProcessing = false; // STT→GPT処理中フラグ

  Map<String, dynamic>? _question;
  String _selectedCharacter = CharacterAssetService.defaultCharacter;
  int _streakDays = 0;

  late VoicevoxTtsService _voicevoxService;
  late SpeechService _speechService;

  @override
  void initState() {
    super.initState();
    _voicevoxService = VoicevoxTtsService();
    _speechService = SpeechService();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final character = CharacterAssetService.normalize(
      prefs.getString(CharacterAssetService.prefKey),
    );
    final showFurigana = prefs.getBool('show_furigana') ?? true;
    final userLevel = prefs.getString('user_level') ?? 'beginner';
    final streakDays = prefs.getInt('streak_days') ?? 0;

    final question = await DailyPracticeService.instance.getTodaysQuestion(
      userLevel: userLevel,
    );

    if (mounted) {
      setState(() {
        _selectedCharacter = character;
        _showFurigana = showFurigana;
        _question = question;
        _streakDays = streakDays;
        _isLoading = false;
      });
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

  String get _furigana {
    return (_question?['furigana'] as String?) ?? '';
  }

  String get _questionId {
    return (_question?['id'] as String?) ?? '';
  }

  // フレーズをモーラ単位で「・」区切りにする
  String _buildMoraHint(String text) {
    if (text.isEmpty) return '';
    // ひらがな・カタカナ・漢字などをrune単位で分割
    return text.runes.map((r) => String.fromCharCode(r)).join('・');
  }

  // ---------- VOICEVOX ----------

  Future<void> _listenPhrase() async {
    final text = _japaneseText;
    if (text.isEmpty) return;
    await _voicevoxService.speak(
      text,
      _selectedCharacter,
      onDailyLimitFallback: (_) {},
    );
    if (mounted && _step == _PracticeStep.idle) {
      setState(() => _step = _PracticeStep.listened);
    }
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
    setState(() => _step = _PracticeStep.recording);
    _speechService.listen((result) {
      _handleSTTResult(result);
    });
  }

  Future<void> _stopRecording() async {
    await _speechService.stop();
    if (mounted && _step == _PracticeStep.recording) {
      setState(() => _step = _PracticeStep.listened);
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
    final prompt = PromptBuilders.buildAccuracyPrompt(
      userAnswer: recognized,
      originalQuestion: correct,
      targetLang: 'Japanese',
      nativeLang: 'English',
    );

    final response = await GptService.getChatResponse(prompt, recognized, loc);
    final isCorrect = response?.trim() == '1';

    if (!mounted) return;

    if (isCorrect) {
      await DailyPracticeService.instance.markAsCompleted(_questionId);
      await DailyPracticeService.instance.incrementPracticeCount();
    }

    setState(() {
      _isCorrect = isCorrect;
      _step = _PracticeStep.result;
      _isProcessing = false;
    });
  }

  // ---------- ヒントダイアログ ----------

  void _showHintDialog() {
    final text = _japaneseText;
    final native = _nativeText;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ヒント', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text(
              _buildMoraHint(text),
              style: const TextStyle(fontSize: 20, letterSpacing: 2),
            ),
            const SizedBox(height: 8),
            Text(native, style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
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

  Widget _buildPhraseCard(AppLocalizations loc) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 右上：ふりがなトグル
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: Icon(
                      _showFurigana ? Icons.text_fields : Icons.text_fields_outlined,
                      color: Colors.pink.shade300,
                    ),
                    tooltip: 'ふりがな',
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      setState(() => _showFurigana = !_showFurigana);
                      await prefs.setBool('show_furigana', _showFurigana);
                    },
                  ),
                ),
                // ふりがな
                if (_showFurigana && _furigana.isNotEmpty)
                  Text(
                    _furigana,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                const SizedBox(height: 4),
                // 日本語テキスト
                Text(
                  _japaneseText,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                // ネイティブ語訳
                Text(
                  _nativeText,
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 4),
                // ヒントボタン（result + 不正解のみ表示）
                if (_step == _PracticeStep.result && !_isCorrect)
                  Align(
                    alignment: Alignment.bottomRight,
                    child: IconButton(
                      icon: const Icon(Icons.info_outline, color: Colors.grey),
                      onPressed: _showHintDialog,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepArea(AppLocalizations loc) {
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
          children: [
            WaveAnimation(isListening: true),
            const SizedBox(height: 8),
            const Text('録音中…', style: TextStyle(color: Colors.pinkAccent)),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _stopRecording,
              child: const Text('停止'),
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
                color: _isCorrect ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isCorrect ? Colors.green.shade200 : Colors.orange.shade200,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isCorrect ? Icons.check_circle : Icons.refresh,
                    color: _isCorrect ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isCorrect ? loc.badgeCorrect : loc.badgeNeedsImprovement,
                    style: TextStyle(
                      color: _isCorrect ? Colors.green.shade700 : Colors.orange.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
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
            const SizedBox(height: 8),
            // もう一回言う
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
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink.shade300,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('完了 →', style: TextStyle(fontSize: 16)),
            ),
          ],
        );
    }
  }

  Widget _buildListenButton(AppLocalizations loc) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.volume_up),
      label: Text(loc.dailyPracticeListenButton),
      onPressed: _listenPhrase,
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
    _voicevoxService.dispose();
    _speechService.stop();
    super.dispose();
  }
}
