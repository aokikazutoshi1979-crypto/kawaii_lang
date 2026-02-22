import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/speech_service.dart';
import '../services/question_manager.dart';
import '../widgets/message_list.dart';
import '../widgets/mic_area.dart';
import 'package:kawaii_lang/l10n/app_localizations.dart';
import '../utils/lang_utils.dart';
import '../services/gpt_service.dart';
import 'package:kawaii_lang/services/prompt_builders.dart';
import '../widgets/keyboard_guide_button.dart';
import 'dart:convert'; // ✅ これが必要！
import 'package:kawaii_lang/services/history_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:kawaii_lang/config/quiz_mode_config.dart';
import 'package:kawaii_lang/widgets/mode_toggle_bar.dart';
import '../models/quiz_mode.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:ui';
// 先頭で：プラットフォーム別にしたい場合
import 'dart:io' show Platform, File;
import '../common/scene_label.dart';
import 'package:kawaii_lang/services/language_catalog.dart';
import 'question_list_screen.dart';
import '../utils/tsumugi_prompt.dart' as tsumugi_prompt;
import '../services/character_asset_service.dart';


class ChatScreen extends StatefulWidget {
  final String nativeLang;
  final String targetLang;
  final String scene;
  final String promptLang;
  final bool isNativePrompt;
  final String selectedQuestionText;
  final String correctAnswerText;
  final List<Map<String, String>> questionList;
  final int selectedIndex;
  final QuizMode mode; // ★追加
  final bool showRecommendedStartLink;
  final String? recommendedReturnScene;

  const ChatScreen({
    required this.nativeLang,
    required this.targetLang,
    required this.scene,
    required this.promptLang,
    required this.isNativePrompt,
    required this.selectedQuestionText,
    required this.correctAnswerText,
    required this.questionList,
    required this.selectedIndex,
    required this.mode,
    this.showRecommendedStartLink = false,
    this.recommendedReturnScene,
    Key? key,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  AppLocalizations get loc => AppLocalizations.of(context)!; // ← これを追加
  final TextEditingController _controller = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  String get nativeName => getLangLabelEn(widget.nativeLang);
  String get targetName => getLangLabelEn(widget.targetLang);
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  bool _hasInput = false;
  bool _hasSubmitted = false;

  late SpeechService _speechService;
  late QuestionManager _questionManager;
  late QuizMode _mode;

  bool _isListening = false;
  bool _isKeyboardMode = false;
  String _nativeCode = 'ja';

  String _currentNativeText = ''; // ← 出題を保持
  String _tsumugiQuestionText = '';
  bool _isPromptExpanded = false;

  late String _targetCode;

  DateTime? _lastReset;
  int _requestCount = 0;

  // ── 追加メンバ
  final List<DateTime> _sendTimestamps = [];
  DateTime? _rateLimitResetTime;
  bool _hasShownRateLimitError = false;

  bool _hasShownSessionError = false;

  static const List<Map<String, Object>> _ranks = [
    {'name': 'Starter', 'threshold': 0},
    {'name': 'Explorer', 'threshold': 25},
    {'name': 'Speaker', 'threshold': 100},
    {'name': 'Fluent', 'threshold': 300},
    {'name': 'Pro', 'threshold': 600},
    {'name': 'Master', 'threshold': 1000},
  ];

  final Queue<double> _ampQueue = Queue<double>();
  StreamSubscription<Amplitude>? _ampSub;
  double _ampEma = 0.0;

  final Queue<String> _recentTumugiLines = Queue<String>();
  final Random _rng = Random();

  // 録音用
  final AudioRecorder _rec = AudioRecorder();
  String? _pendingAudioPath;   // 送信時にメッセへ添付するための一時バッファ
  int? _pendingDurationMs;
  DateTime? _recStartAt;
  Timer? _recLimitTimer;       // 10秒上限のタイマー

  late final FlutterTts _tts;   // ← 追加
  bool _ttsReady = false;       // ← 追加
  bool _isSpeaking = false;     // ← 追加

  // ── 送信前ボタン有効判定
  bool get _canSend {
    final now = DateTime.now();
    if (_rateLimitResetTime != null && now.isBefore(_rateLimitResetTime!)) {
      return false;
    }
    _sendTimestamps.retainWhere((t) => now.difference(t) < Duration(minutes: 1));
    return _sendTimestamps.length < 10;
  }

  bool _revealListeningText = false;
  String? _displayName;
  String _selectedCharacter = CharacterAssetService.defaultCharacter;

  String _pickTumugiLine() {
    final isKasumi = _selectedCharacter == CharacterAssetService.kasumi;
    final baseLines = isKasumi
        ? tsumugi_prompt.kasumiPraiseLines(_nativeCode)
        : tsumugi_prompt.tsumugiPraiseLines(_nativeCode);
    final pool = List<String>.from(baseLines)
      ..removeWhere((line) => _recentTumugiLines.contains(line));
    if (pool.isEmpty) {
      pool.addAll(baseLines);
    }
    final baseLine = pool[_rng.nextInt(pool.length)];
    _recentTumugiLines.addLast(baseLine);
    while (_recentTumugiLines.length > 3) {
      _recentTumugiLines.removeFirst();
    }
    final prefix = tsumugi_prompt.tsumugiNamePrefix(_nativeCode, _displayName);
    final joiner = tsumugi_prompt.tsumugiSentenceJoiner(_nativeCode);
    final nextPrompt = isKasumi
        ? tsumugi_prompt.kasumiNextPrompt(_nativeCode)
        : tsumugi_prompt.tsumugiNextPrompt(_nativeCode);
    return '$prefix$baseLine$joiner$nextPrompt';
  }

  Future<void> _enqueueTumugiReply() async {
    if (_messages.isEmpty || _messages.last['role'] == 'user') return;
    final delayMs = 300 + _rng.nextInt(301);
    await Future.delayed(Duration(milliseconds: delayMs));
    if (!mounted) return;
    setState(() {
      _messages.add({
        'role': 'tumugi',
        'text': _pickTumugiLine(),
        'avatarPath': CharacterAssetService.chatAvatar(_selectedCharacter),
      });
    });
  }

  // 返ってくる型が String でも Map でも安全に扱う
  bool _parseIsCorrectJson(dynamic response) {
    try {
      // 1) まず素の型を優先判定
      if (response is bool) return response;                 // true / false
      if (response is num)  return response == 1;            // 1 / 0
      if (response is String) {
        final s = response.trim().toLowerCase();
        if (s == '1' || s == 'true')  return true;           // "1" / "true"
        if (s == '0' || s == 'false') return false;          // "0" / "false"
        // JSON文字列の可能性
        final decoded = jsonDecode(s);
        return _parseIsCorrectJson(decoded);                 // 再帰
      }

      // 2) Map(JSON) を安全に走査
      if (response is Map) {
        // 代表キーを直接見る
        for (final k in const ['isCorrect', 'correct']) {
          if (response.containsKey(k)) {
            final v = response[k];
            final r = _parseIsCorrectJson(v);
            if (r is bool) return r;
          }
        }
        // よくあるネスト: result.isCorrect / data.isCorrect / evaluation.isCorrect
        for (final path in const [
          ['result', 'isCorrect'],
          ['data', 'isCorrect'],
          ['evaluation', 'isCorrect'],
        ]) {
          dynamic cur = response;
          for (final key in path) {
            if (cur is Map && cur.containsKey(key)) {
              cur = cur[key];
            } else {
              cur = null;
              break;
            }
          }
          if (cur != null) return _parseIsCorrectJson(cur);
        }
      }
    } catch (_) {
      // 解析失敗は下で false
    }
    return false; // 判定不能は不正解扱い
  }

  void _startAmplitudeStream() {
    _ampSub?.cancel();
    _ampQueue.clear();
    _ampEma = 0.0;
    _ampSub = _rec
        .onAmplitudeChanged(const Duration(milliseconds: 50))
        .listen((amp) {
      if (!mounted) return;
      final db = amp.current ?? -60.0;
      final normalized = ((db + 60.0) / 60.0).clamp(0.0, 1.0);
      const alpha = 0.25;
      _ampEma = (_ampEma * (1 - alpha)) + (normalized * alpha);
      setState(() {
        _ampQueue.add(_ampEma);
        while (_ampQueue.length > 40) {
          _ampQueue.removeFirst();
        }
      });
    });
  }

  void _stopAmplitudeStream({bool clear = true}) {
    _ampSub?.cancel();
    _ampSub = null;
    _ampEma = 0.0;
    if (clear) {
      _ampQueue.clear();
    }
  }

  int _rankIndexForUnique(int uniqueCorrect) {
    var index = 0;
    for (var i = 0; i < _ranks.length; i++) {
      final threshold = _ranks[i]['threshold'] as int;
      if (uniqueCorrect >= threshold) {
        index = i;
      } else {
        break;
      }
    }
    return index;
  }

  Future<void> _maybeShowRankUp() async {
    final stats = await HistoryService.instance.getProfileStats();
    final uniqueCorrect = stats.uniqueCorrect;
    final currentIndex = _rankIndexForUnique(uniqueCorrect);

    final prefs = await SharedPreferences.getInstance();
    final lastIndex = prefs.getInt('last_rank_index');
    if (lastIndex == null) {
      await prefs.setInt('last_rank_index', currentIndex);
      return;
    }

    if (currentIndex > lastIndex) {
      await prefs.setInt('last_rank_index', currentIndex);
      if (!mounted) return;
      final rankName = _ranks[currentIndex]['name'] as String;
      showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(loc.rankUpTitle),
            content: Text(loc.rankUpBody(rankName)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(loc.ok),
              ),
            ],
          );
        },
      );
    }
  }

  String _normalizeForDuplicateCheck(String input) {
    var s = input.trim().toLowerCase();
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    s = s.replaceAll(RegExp(r'^[\"“”『』「」]+|[\"“”『』「」]+$'), '');
    s = s.replaceAll(RegExp(r'[.!?。！？…．、]+$'), '');
    return s;
  }

  String _normalizeRomaji(String input) {
    return input
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }

  bool _isSameRomaji(String? a, String? b) {
    if (a == null || b == null) return false;
    final na = _normalizeRomaji(a);
    final nb = _normalizeRomaji(b);
    if (na.isEmpty || nb.isEmpty) return false;
    return na == nb;
  }

  Future<String?> _romajiForJapanese(String text, AppLocalizations loc) async {
    final t = text.trim();
    if (t.isEmpty) return null;
    final prompt = PromptBuilders.buildSimilarQuestionTtsPrompt(
      translatedText: t,
      targetLang: _targetCode,
    );
    final res = await GptService.getChatResponse(prompt, t, loc);
    if (res == null) return null;
    final r = res.trim();
    if (r.isEmpty || r.toLowerCase() == 'null') return null;
    return r;
  }

  bool _isDuplicateSimilar(String candidate, List<String> avoidList) {
    final c = _normalizeForDuplicateCheck(candidate);
    if (c.isEmpty) return true;
    for (final a in avoidList) {
      if (a.trim().isEmpty) continue;
      final n = _normalizeForDuplicateCheck(a);
      if (n.isNotEmpty && c == n) return true;
    }
    return false;
  }

  String _buildSimilarPromptWithAvoid({
    required String seed,
    required String targetLang,
    required List<String> avoidList,
  }) {
    final base = PromptBuilders.buildSimilarQuestionPrompt(
      translatedText: seed,
      targetLang: targetLang,
    );
    if (avoidList.isEmpty) return base;
    final quoted = avoidList.where((s) => s.trim().isNotEmpty).map((s) => '"$s"').join(', ');
    if (quoted.isEmpty) return base;
    return '$base\n\n【追加条件】\n- 次の表現と同一にならないこと: $quoted\n';
  }

  Future<String?> _generateSimilarExpression({
    required String seed,
    required String targetLang,
    required AppLocalizations loc,
    List<String> avoidList = const [],
  }) async {
    final basePrompt = PromptBuilders.buildSimilarQuestionPrompt(
      translatedText: seed,
      targetLang: targetLang,
    );
    final String? first = await GptService.getChatResponse(basePrompt, seed, loc);
    final String firstText = (first ?? '').trim();
    if (firstText.isEmpty) return null;
    if (!_isDuplicateSimilar(firstText, avoidList)) return firstText;

    final retryPrompt = _buildSimilarPromptWithAvoid(
      seed: seed,
      targetLang: targetLang,
      avoidList: avoidList,
    );
    final String? retry = await GptService.getChatResponse(retryPrompt, seed, loc);
    final String retryText = (retry ?? '').trim();
    if (retryText.isEmpty) return null;
    if (_isDuplicateSimilar(retryText, avoidList)) {
      print('similar expression duplicated; skipped');
      return null;
    }
    return retryText;
  }

  Widget _langPill(BuildContext context, String text) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.6)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );
  }

  // 「母語の表記」で対象言語名を返す
  String _displayLangName(String rawCode) {
    final code = getLangCode(rawCode);              // "English" → "en" など正規化
    final display = getLangCode(widget.nativeLang); // 母語のコード
    return LanguageCatalog.instance.labelFor(code, displayLang: display);
  }

  String _displayLangCode(String rawCode) {
    final code = getLangCode(rawCode).replaceAll('_', '-');
    return code.toUpperCase();
  }

  @override
  void initState() {
    super.initState();

    // 1) まず現在のモードを確定（← これが先）
    _mode = widget.mode; // QuizMode.reading / listening

    // 2) 既存の初期化
    _speechService = SpeechService();
    _controller.clear();
    _questionManager = QuestionManager(widget.questionList, widget.selectedIndex);
    _nativeCode = getLangCode(widget.nativeLang);
    _targetCode = getLangCode(widget.targetLang); // ★追加

    _tts = FlutterTts();
    // 3) TTS 初期化（内部で _ttsReady = true にする想定）
    _initTts();

    _loadDisplayName();
    _loadCharacter();

    // ★ 言語カタログを読み込んでから一度だけ再描画
    Future.microtask(() async {
      await LanguageCatalog.instance.ensureLoaded();
      if (mounted) {
        setState(() {
          _tsumugiQuestionText = _selectedCharacter == CharacterAssetService.kasumi
              ? tsumugi_prompt.buildKasumiQuestionLine(
                  uiLanguageCode: _nativeCode,
                  targetLanguageName: _displayLangName(widget.targetLang),
                )
              : tsumugi_prompt.buildTsumugiQuestionLine(
                  uiLanguageCode: _nativeCode,
                  targetLanguageName: _displayLangName(widget.targetLang),
                );
        });
      }
    });

    // 4) Listening で入室したら、自動再生（ビルド完了後に）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // if (_mode == QuizMode.listening) _speakCurrentQuestion();
    });
  }

  Future<void> _loadDisplayName() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _displayName = prefs.getString('user_display_name');
    });
  }

  Future<void> _loadCharacter() async {
    final character = await CharacterAssetService.loadSelectedCharacter();
    if (!mounted) return;
    setState(() => _selectedCharacter = character);
  }

  Future<void> _initTts() async {
    final double rate = Platform.isIOS ? 0.40 : 0.85; // AndroidはiOSより遅く感じやすい
    await _tts.setSpeechRate(rate);

    // （お好み）声の高さ
    await _tts.setPitch(1.0);

    await _setTtsLanguage();          // ← chat_bubble からコピペした関数を呼ぶ
    await _tts.setVolume(1.0);
    await _tts.awaitSpeakCompletion(true); // 任意：再生完了待ちを有効化
    _ttsReady = true;
  }

  // Listening時は target、Reading時は native を優先して取る
  String _currentQuestionTextForMode() {
    final cur = _questionManager.current;
    // よく使うキーの安全フォールバック
    String from(Map m, String key) => (m[key] as String?)?.trim() ?? '';

    if (_mode == QuizMode.listening) {
      final t = from(cur, _targetCode);
      if (t.isNotEmpty) return t;
    } else {
      final n = from(cur, _nativeCode);
      if (n.isNotEmpty) return n;
    }
    // どちらも無ければ汎用キーを探索
    for (final k in const ['questionText', 'promptText', 'text', 'question']) {
      final v = (cur[k] as String?)?.trim() ?? '';
      if (v.isNotEmpty) return v;
    }
    return '';
  }

  String _currentQuestionText() {
    // 1) 画面遷移時に明示的に渡されている場合（最優先）
    final sel = (widget.selectedQuestionText ?? '').trim();
    if (sel.isNotEmpty) return sel;

    // 2) 現在インデックスのアイテムから推測
    try {
      final idx = _questionManager.currentIndex;
      if (idx >= 0 && idx < widget.questionList.length) {
        final item = widget.questionList[idx];
        if (item is Map) {
          // あり得そうなキー名を優先順で探索
          for (final k in const [
            'questionText',
            'promptText',
            'text',
            'question',
            'body',
            'display',
          ]) {
            final v = item[k];
            if (v is String && v.trim().isNotEmpty) {
              return v.trim();
            }
          }
        }
      }
    } catch (_) {
      // 何もしない（下のフォールバックへ）
    }

    // 3) 最終フォールバック（本来は問題文を読むが、無い時は正解文を読む）
    final ans = (widget.correctAnswerText ?? '').trim();
    if (ans.isNotEmpty) return ans;

    return '';
  }

  // _ChatScreenState のメンバに追加（initStateやbuildの外）
  String get questionText {
    final cur = _questionManager.current;
    // 文字列取り出しの安全関数
    String pick(Map m, String key) => (m[key] as String?)?.trim() ?? '';

    if (_mode == QuizMode.listening) {
      // ★ Listening のときは target 言語を優先
      final t = pick(cur, _targetCode);
      if (t.isNotEmpty) return t;
      // なければフォールバックで native など汎用キー
      final n = pick(cur, _nativeCode);
      if (n.isNotEmpty) return n;
    } else {
      // ★ Reading のときは native を優先
      final n = pick(cur, _nativeCode);
      if (n.isNotEmpty) return n;
      // なければ target にフォールバック
      final t = pick(cur, _targetCode);
      if (t.isNotEmpty) return t;
    }

    // さらに一般キーにもフォールバック（必要なら調整）
    for (final k in const ['questionText', 'promptText', 'text', 'question', 'body']) {
      final v = (cur[k] as String?)?.trim() ?? '';
      if (v.isNotEmpty) return v;
    }
    return '';
  }

  Widget _listeningQuestionCard() {
    final text = _currentQuestionTextForMode();
    if (text.isEmpty) return const SizedBox.shrink();

    final blurredText = Stack(
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
          child: Text(
            text,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Positioned.fill(
          child: Container(color: Colors.white.withOpacity(0.45)),
        ),
      ],
    );

    final plainText = Text(
      text,
      style: const TextStyle(fontSize: 16, color: Colors.black87),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ラベルなし大アイコンの再生ボタン
            Tooltip(
              message: '再生',
              child: FilledButton(
                onPressed: _isSpeaking ? null : () => _speakText(text),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  minimumSize: const Size(56, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Icon(Icons.volume_up_rounded, size: 28),
              ),
            ),
            const SizedBox(width: 12),

            // ぼかし → 平文へスムーズに切替
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: _revealListeningText
                    ? plainText
                    : blurredText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _speakText(String text) async {
    if (!_ttsReady || _isSpeaking) return;
    text = text.replaceAll(RegExp(r'<[^>]+>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.isEmpty) return;

    try {
      _isSpeaking = true;
      await _tts.stop();
      await _tts.speak(text);
    } catch (e) {
      print('TTS failed: $e');
    } finally {
      _isSpeaking = false;
    }
  }

  Future<void> _speakCurrentQuestion() async {
    if (!_ttsReady || _isSpeaking) return;
    try {
      var text = _currentQuestionText();

      // ざっくりタグ/改行除去（SSMLやMarkdownが混ざっていても読みやすく）
      text = text
          .replaceAll(RegExp(r'<[^>]+>'), ' ') // SSML/HTMLタグ除去
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      if (text.isEmpty) {
        print('TTS: empty question text, skip.');
        return;
      }

      _isSpeaking = true;
      await _tts.stop();
      await _tts.speak(text);
    } catch (e) {
      if (!mounted) return;
      // フォールバック不要なら何もしない（ログだけでもOK）
      print('TTS failed: $e');
    } finally {
      _isSpeaking = false;
    }
  }

  void _toggleMode() {
    setState(() {
      _mode = _mode == QuizMode.reading ? QuizMode.listening : QuizMode.reading;
    });
    if (_mode == QuizMode.listening) _speakCurrentQuestion();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final loc = AppLocalizations.of(context)!;
    _loadQuestion(loc);
  }

  @override
  void dispose() {
    _recLimitTimer?.cancel();
    // 録音中なら止める（安全策）
    _rec.stop();
    _rec.dispose();
    _stopAmplitudeStream(clear: false);
    _tts.stop();
    _speechService.stop();
    _controller.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _loadQuestion(AppLocalizations loc) {
    final q = _questionManager.current;

    final nativeText = (q[_nativeCode] as String?)?.trim() ?? '';
    final targetText = (q[_targetCode] as String?)?.trim() ?? '';

    final isListening = _mode == QuizMode.listening;

    setState(() {
      // ★ ここで毎回リセット（モードに関わらず）
      _revealListeningText = false;
      _currentNativeText = nativeText;
      _isPromptExpanded = false;
      _tsumugiQuestionText = _selectedCharacter == CharacterAssetService.kasumi
          ? tsumugi_prompt.buildKasumiQuestionLine(
              uiLanguageCode: _nativeCode,
              targetLanguageName: _displayLangName(widget.targetLang),
            )
          : tsumugi_prompt.buildTsumugiQuestionLine(
              uiLanguageCode: _nativeCode,
              targetLanguageName: _displayLangName(widget.targetLang),
            );

      if (isListening) {
        _messages = [
          // （必要なら）{'role': 'bot', 'text': loc.listeningPrompt}
        ];
      } else {
        _messages = [
          // {'role': 'bot', 'text': '${loc.translatePrompt}\n「$nativeText」'}
        ];
      }

      _hasInput = false;
      _hasSubmitted = false;
      _isKeyboardMode = false;
    });
  }

  void _speakIfListeningAfterBuild() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_mode == QuizMode.listening) _speakCurrentQuestion();
    });
  }

  void _loadNextQuestion() {
    _questionManager.next();
    final loc = AppLocalizations.of(context)!;
    _loadQuestion(loc);            // ← これが _revealListeningText を false にしてくれる
    // setState(() => _revealListeningText = false); // ← もう不要
  }

  void _startListening() async {
    final localeId = getLocaleId(widget.targetLang);
    final available = await _speechService.initialize(localeId);
    if (available) {
      // ★★ 録音開始（端末の一時フォルダへ .m4a で保存）
      try {
        final hasPerm = await _rec.hasPermission();
        if (hasPerm) {
          final tmp = await getTemporaryDirectory();
          final path = '${tmp.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a';
          await _rec.start(
            const RecordConfig(
              encoder: AudioEncoder.aacLc,
              bitRate: 128000,
              sampleRate: 44100,
            ),
            path: path, // ← v6ではIO系プラットフォームで必須
          );
          _pendingAudioPath = path;                 // 後で吹き出しへ添付するため保持
          _recStartAt = DateTime.now();
          _startAmplitudeStream();

          // ★★ 10秒で自動停止（STT & 録音を同時に止める）
          _recLimitTimer?.cancel();
          _recLimitTimer = Timer(const Duration(seconds: 10), () {
            if (_isListening) {
              _stopListening(autoStopped: true);
            }
          });
        } else {
          // パーミッション無い場合は録音なしでSTTだけ動かす
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('マイクの権限がありません（録音なしで音声認識を開始します）')),
          );
        }
      } catch (e) {
        print('record.start failed: $e');
      }
      setState(() {
        _isListening = true;
        _isKeyboardMode = false;
      });
      _speechService.listen((recognizedText) {
        setState(() {
          _controller.text = (_controller.text + ' ' + recognizedText).trim();
          _hasInput = _controller.text.trim().isNotEmpty;
        });
      });
    }
  }

  Future<void> _setTtsLanguage() async {
    // ① —— まず最初に一度だけサポート言語・音声一覧を取得
    final List<dynamic>? langs = await _tts.getLanguages;

    final List<dynamic>? allVoices = await _tts.getVoices;

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
        // print('🎤 zh‑TW voices: $taiwanVoices');

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

  Future<void> _stopListening({bool autoStopped = false}) async {
    await _speechService.stop();

    // ★★ 10秒タイマー停止
    _recLimitTimer?.cancel();
    _stopAmplitudeStream(clear: true);

    // ★★ 録音停止 → 長さ計測 → バッファに保持
    try {
      if (await _rec.isRecording()) {
        final actualPath = await _rec.stop(); // 実際に保存されたパス（null の可能性も）
        // record.stop() が null を返す可能性に備えて pending を優先
        final path = actualPath ?? _pendingAudioPath;

        final durMs = (_recStartAt != null)
            ? DateTime.now().difference(_recStartAt!).inMilliseconds
            : null;

        _pendingAudioPath = path;            // 送信時にメッセへ添付
        _pendingDurationMs = durMs;
        _recStartAt = null;
      }
    } catch (e) {
      print('record.stop failed: $e');
    }

    if (autoStopped) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.recordingAutoStopped)),
      );
    }

    setState(() => _isListening = false);
  }

  Future<void> _cancelRecording() async {
    await _stopListening();
    final path = _pendingAudioPath;
    if (path != null && path.isNotEmpty) {
      try {
        final f = File(path);
        if (f.existsSync()) {
          await f.delete();
        }
      } catch (_) {}
    }
    _pendingAudioPath = null;
    _pendingDurationMs = null;
    if (mounted) {
      setState(() {
        _controller.clear();
        _hasInput = false;
      });
    }
  }

  Future<void> _confirmRecording() async {
    await _stopListening();
  }

  void _activateKeyboardMode() async {
    setState(() {
      _isKeyboardMode = true;
      _isListening = false;
    });
    _speechService.stop();
    _stopAmplitudeStream(clear: true);

    // もし録音中なら止める
    try {
      if (await _rec.isRecording()) {
        await _rec.stop();
      }
    } catch (_) {}

    // 🔴 キーボードに切り替えたら pending 音声を破棄
    _pendingAudioPath = null;
    _pendingDurationMs = null;

    Future.delayed(const Duration(milliseconds: 100), () {
      _inputFocusNode.requestFocus();
    });
  }

  void _sendMessage() async {
    final rawInput = _controller.text.trim();
    if (rawInput.isEmpty) return;

    if (!_canSend) {
      if (!_hasShownRateLimitError) {
        setState(() {
          _messages.add({
            'role': 'bot',
            'text': AppLocalizations.of(context)!.errorRateLimit,
          });
          _hasShownRateLimitError = true;
        });
      }
      return;
    }

    _sendTimestamps.add(DateTime.now());

    setState(() {
      _controller.clear();
      _hasInput = false;
      _isLoading = true;
      _hasSubmitted = true;
    });

    final loc = AppLocalizations.of(context)!;
    // final questionText = _questionManager.current[_nativeCode] ?? '';

    try {
      print('▶ Entering GPT request try-block');

      // ⑤ 正解チェック（問1）だけ mode で分岐
      final prompt1 = (_mode == QuizMode.listening)
        ? PromptBuilders.buildListeningPrompt(
            userAnswer:       rawInput,
            originalQuestion: questionText,
            targetLang:       targetName,
            nativeLang:       nativeName,
          )
        : PromptBuilders.buildAccuracyPrompt(
            userAnswer:       rawInput,
            originalQuestion: questionText,
            targetLang:       targetName,
            nativeLang:       nativeName,
          );


      final res1 = await GptService.getChatResponse(
        prompt1,
        rawInput,
        loc,
        model: 'gpt-4o',  // ←ここでモデルをオーバーライド
        // model: 'gpt-3.5-turbo',  // ←ここでモデルをオーバーライド
      );
      // ★ JSONから正誤boolを抽出
      final bool isCorrectFlag = _parseIsCorrectJson(res1);

      if (isCorrectFlag) {
        if (rawInput == null || rawInput.trim().isEmpty) {
          setState(() {
            _messages.add({'role': 'bot', 'text': loc.errorPunctuationFailed});
          });
          return;
        }

        final bool shouldAttachAudio = !_isKeyboardMode && _pendingAudioPath != null;

        setState(() {
          final Map<String, dynamic> userMsg = {
            'role': 'user',
            'text': rawInput,
            'labelType': 'correct',
          };
          // 🎯 キーボードモードなら音声は付けない
          if (shouldAttachAudio) {
            userMsg['audioPath'] = _pendingAudioPath;   // 🎤 録音のローカルパス
            if (_pendingDurationMs != null) {
              userMsg['durationMs'] = _pendingDurationMs; // ⏱️ 表示用
            }
          }
          _messages.add(userMsg);

          // 入力欄のクリア（必要なら）
          _controller.clear();
          _hasInput = false;
        });

        // pending のクリアは setState の外でOK
        _pendingAudioPath = null;
        _pendingDurationMs = null;

        // ログイン中（匿名含む）のユーザーであれば履歴を記録
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // ここでだけ Firestore 書き込み
          final currentMap = widget.questionList[_questionManager.currentIndex];
          final questionId = currentMap['id'] as String;
          final scene      = currentMap['scene'] as String;
          final subScene   = currentMap['subScene'] as String;
          final level      = currentMap['level'] as String;

          try {
            final uid = FirebaseAuth.instance.currentUser?.uid;
            print('→ recordAnswer call: q=$questionId target=$targetName native=$nativeName uid=$uid');

            await HistoryService.instance.recordAnswer(
              questionId: questionId,
              isCorrect:  isCorrectFlag,
              scene:      scene,
              subScene:   subScene,
              level:      level,
              mode:       _mode.name, // "reading" | "listening"
              targetLang: targetName,  // ★追加
              nativeLang: nativeName,  // ★追加
              targetCode: _targetCode,
              nativeCode: _nativeCode,
            );

            print('✓ recordAnswer saved');
          } catch (e) {
            print('▶ history record failed (ignored): $e');
          }
        }

        if (user != null) {
          await _maybeShowRankUp();
        }

        // 問6
        await _handleOriginalQuestionTranslation(
          questionText,
          loc,
          rawInput: rawInput,
          useAnswerPrefix: false,
          skipFirstBubble: true,           // ←①を出さない
          addAccuracyNoticeBubble: true,   // ←“的確です”通知を表示
          onlyFirstBubble: false,          // ←②以降も続ける
        );
        await _enqueueTumugiReply();
        return;
      }



      // ① 問7：記号または数字のみ、不適切文、母語以外で書かれているかチェック
      final minimalPrompt = PromptBuilders.buildSymbolOrNumberOnlyCheckPrompt(
        userAnswer: rawInput,
        targetLang: targetName,
      );
      final res7 = await GptService.getChatResponse(minimalPrompt, rawInput, loc);
      final answer7 = _parseAnswer(res7);

      // ① or ② の両方で同じフロー（違いは incorrectLine を出すかどうかだけ）
      if (answer7 == '1' || answer7 == '2') {
        if (rawInput == null || rawInput.trim().isEmpty) {
          setState(() {
            _messages.add({'role': 'bot', 'text': loc.errorPunctuationFailed});
          });
          return;
        }

        final bool shouldAttachAudio = !_isKeyboardMode && _pendingAudioPath != null;

        setState(() {
          final Map<String, dynamic> userMsg = {
            'role': 'user',
            'text': rawInput,
            'labelType': 'incorrect',
          };
          // 🎯 キーボードモードなら音声は付けない
          if (shouldAttachAudio) {
            userMsg['audioPath'] = _pendingAudioPath;   // 🎤 録音のローカルパス
            if (_pendingDurationMs != null) {
              userMsg['durationMs'] = _pendingDurationMs; // ⏱️ 表示用
            }
          }
          _messages.add(userMsg);

          // 入力欄のクリア（必要なら）
          _controller.clear();
          _hasInput = false;
        });

        // pending のクリアは setState の外でOK
        _pendingAudioPath = null;
        _pendingDurationMs = null;

        // 1) オリジナルの翻訳（ターゲット言語）
        final prompt6 = PromptBuilders.buildOriginalQuestionTranslationPrompt(
          originalQuestion: questionText,
          targetLang:       targetName,
        );
        final String? res6 = await GptService.getChatResponse(prompt6, questionText, loc);
        final String translatedText = (res6 ?? '').trim();

        // 2) オリジナルの音声転写（対象言語が ja/zh/zh_tw/ko のときのみ）
        String? transcription6;
        {
          final norm = widget.targetLang.replaceAll('-', '_').toLowerCase();
          if (const {'ja', 'zh', 'zh_tw', 'ko'}.contains(norm) && translatedText.isNotEmpty) {
            final promptTts6 = PromptBuilders.buildSimilarQuestionTtsPrompt(
              translatedText: translatedText,
              targetLang: widget.targetLang,
            );
            final String? rawTrans6 = await GptService.getChatResponse(promptTts6, translatedText, loc);
            if (rawTrans6 != null && rawTrans6.toLowerCase() != 'null') {
              transcription6 = rawTrans6.trim();
            }
          }
        }

        // 3) オリジナルの解説（100文字以内）
        final prompt01 = PromptBuilders.buildPrompt01(
          userAnswer:       rawInput,
          originalQuestion: questionText,
          targetLang:       targetName,
          nativeLang:       nativeName,
        );
        final String? expl01 = await GptService.getChatResponse(prompt01, questionText, loc);
        final String explanation01 = (expl01 ?? '').trim();

        // ★ answer7==1 のときだけ Prompt02 を呼ぶ
        String? explanation02;
        if (answer7 == '1') {
          final prompt02 = PromptBuilders.buildPrompt02(
            userAnswer:       rawInput,
            originalQuestion: questionText,
            targetLang:       targetName,
            nativeLang:       nativeName,
          );
          final String? expl02 = await GptService.getChatResponse(prompt02, questionText, loc);
          explanation02 = (expl02 ?? '').trim();
        }

        // 4) 1つ目の吹き出しを表示
        //    answer7==2 のときだけ incorrectLine を含める。==1 なら省く。
        final bool showIncorrectLine = (answer7 == '2');
        final incorrectLine = loc.incorrectMessageWithRaw('"$rawInput"');

        // 🔶 ハイライト本文（訳文＋転写を全部ここに入れる）
        final highlightLines = <String>[];
        highlightLines.add(translatedText); // 訳文

        if (transcription6 != null && transcription6!.isNotEmpty) {
          highlightLines
            ..add('')                // 改行で1行空ける
            ..add(transcription6!);  // 転写テキストだけ追加
        }

        final List<String> bodyLines = ['']; // 1行空け
        if (showIncorrectLine) {
          bodyLines.add(incorrectLine);
          bodyLines.add(''); // もう1行空け
        }
        // ★ explanation02 があるときは 1行空けて追加
        if (explanation02 != null && explanation02.isNotEmpty) {
          bodyLines.add(explanation02);
          bodyLines.add('');
        }
        bodyLines.add(explanation01);

        setState(() {
          _messages.add({
            'role': 'bot',
            // ★ ハイライト用（黄色ボックスの内容）
            'highlightTitle': loc.answerTranslationPrefix,  // 例: 修正例
            'highlightBody':  highlightLines.join('\n'),

            // 🔊 音声ボタン（本文に重複表示はしない）
            'tts': translatedText,
            'showTtsBody': false,

            // ★ 通常本文（ハイライトの下に続くテキスト）
            'text': bodyLines.join('\n'),

            'targetLang': widget.targetLang,
            // ← これで下側の「tts本文テキスト」を消せる
            // 'showTtsBody': false,
          });
        });

        // 5) 類似表現（ターゲット言語）を生成（同一文は再生成）
        String? userRomaji;
        if (_targetCode == 'ja' && rawInput.trim().isNotEmpty) {
          userRomaji = await _romajiForJapanese(rawInput, loc);
        }

        String? similar = await _generateSimilarExpression(
          seed: questionText,
          targetLang: targetName,
          loc: loc,
          avoidList: [rawInput, translatedText],
        );
        if (similar == null || similar.isEmpty) return; // 念のためガード

        String? similarRomaji;
        if (_targetCode == 'ja' && userRomaji != null) {
          similarRomaji = await _romajiForJapanese(similar, loc);
          if (_isSameRomaji(similarRomaji, userRomaji)) {
            final retry = await _generateSimilarExpression(
              seed: questionText,
              targetLang: targetName,
              loc: loc,
              avoidList: [rawInput, translatedText, similar],
            );
            if (retry != null && retry.trim().isNotEmpty) {
              similar = retry;
              similarRomaji = await _romajiForJapanese(similar, loc);
            }
          }
        }

        // 6) 類似表現の母語訳
        final prompt10 = PromptBuilders.buildSimilarQuestionInNativeLangPrompt(
          translatedText: similar,
          nativeLang:     nativeName,
        );
        final String? nativeSimilarRes = await GptService.getChatResponse(prompt10, similar, loc);
        final String nativeSimilar = (nativeSimilarRes ?? '').trim();

        // 7) 類似表現の音声転写（ja/zh/zh_tw/koのみ）
        String? transcriptionSimilar;
        {
          final norm = widget.targetLang.replaceAll('-', '_').toLowerCase();
          if (norm == 'ja' && similarRomaji != null) {
            transcriptionSimilar = similarRomaji;
          } else if (const {'ja', 'zh', 'zh_tw', 'ko'}.contains(norm) && similar.isNotEmpty) {
            final prompt12 = PromptBuilders.buildSimilarQuestionTtsPrompt(
              translatedText: similar,
              targetLang: widget.targetLang,
            );
            final String? rawTranscription = await GptService.getChatResponse(prompt12, similar, loc);
            if (rawTranscription != null && rawTranscription.toLowerCase() != 'null') {
              transcriptionSimilar = rawTranscription.trim();
            }
          }
        }

        // ★ ハイライト本文（類似表現＋転写＋母語訳を全部まとめる）
        final simLines = <String>[];
        simLines.add(similar); // 1行目：類似表現
        if (transcriptionSimilar != null && transcriptionSimilar!.isNotEmpty) {
          simLines..add('')..add(transcriptionSimilar!); // 見出し不要なら転写だけ
        }
        if (nativeSimilar.isNotEmpty) {
          simLines..add('')..add(nativeSimilar); // 見出し不要ならそのまま
        }

        // 8) 2つ目の吹き出しを表示
        // テキスト部は見出し（類似表現）だけにして、本文は tts/nativetext/transcription に流す
        setState(() {
          _messages.add({
            'role': 'bot',
            // ★ ハイライト用（薄い緑色のボックスの内容）
            'highlightTitle': loc.similarExpressionHeader, // 例: 類似表現
            'highlightBody':  simLines.join('\n'),                      // ← 再生ボタン＆本文表示

            // ★ 音声ボタン（本文は出さない）
            'tts': similar,              // ← これで再生アイコンが出る
            'showTtsBody': false,        // ← ttsテキストを本文に重複表示しない

            // ★ 通常本文（補足などを入れたいときだけ）
            'targetLang': widget.targetLang,
            // 'nativeText': nativeSimilar,         // ← 母語訳（ChatBubbleで本文下に表示）
            // if (transcriptionSimilar != null) 'transcription': transcriptionSimilar,
            // 'text': '', 
          });
        });

        return;
      } 

      if (rawInput == null || rawInput.trim().isEmpty) {
        setState(() {
          _messages.add({'role': 'bot', 'text': loc.errorPunctuationFailed});
        });
        return;
      }

      setState(() {
        final Map<String, dynamic> userMsg = {
          'role': 'user',
          'text': rawInput,                 // ← 句読点補完後のテキストを使う
          'labelType': 'incorrect',
        };
        if (_pendingAudioPath != null) {
          userMsg['audioPath'] = _pendingAudioPath;     // 🎤 録音のローカルパス
        }
        if (_pendingDurationMs != null) {
          userMsg['durationMs'] = _pendingDurationMs;   // ⏱️ 表示用
        }
        _messages.add(userMsg);

        // 入力欄のクリア（必要なら）
        _controller.clear();
        _hasInput = false;
      });

      // pending のクリアは setState の外でOK
      _pendingAudioPath = null;
      _pendingDurationMs = null;

    } catch (e, st) {

      final err = e.toString();
      if (err.contains("RATE_LIMIT")) {
        final retrySec = 60;
        setState(() {
          _rateLimitResetTime = DateTime.now().add(Duration(seconds: retrySec));
          _hasShownRateLimitError = true;
          _messages.add({'role': 'bot', 'text': loc.errorRateLimit});
        });
        Future.delayed(Duration(seconds: retrySec), () {
          setState(() {
            _rateLimitResetTime = null;
            _hasShownRateLimitError = false;
          });
        });
      } else {
        setState(() {
          _messages.add({'role': 'bot', 'text': loc.errorBrokenGpt});
        });
      }
    } finally {
      setState(() {
        _isLoading = false;
        _isKeyboardMode = false;
      });
    }
  }

  String _parseAnswer(String? res) {
    if (res == null) return '';
    final s = res.trim();

    // 0) そのまま "1" / "2" のケース
    if (s == '1' || s == '2') return s;

    // 1) ```json ... ``` のようなコードブロックが来た場合に中身だけ抜く
    final codeMatch = RegExp(r'```(?:json)?\s*([\s\S]*?)```').firstMatch(s);
    final candidate = (codeMatch != null ? codeMatch.group(1) : s)?.trim() ?? '';

    // 2) JSONをまず試す
    try {
      final parsed = jsonDecode(candidate);

      // { "answer": "1" }
      if (parsed is Map && parsed['answer'] != null) {
        final v = parsed['answer'].toString().trim();
        if (v == '1' || v == '2') return v;
      }

      // "1" / 1 など
      if (parsed is String && (parsed == '1' || parsed == '2')) return parsed;
      if (parsed is num && (parsed == 1 || parsed == 2)) return parsed.toString();
    } catch (_) {
      // つづくフォールバックへ
    }

    // 3) フォールバック: "answer": "1" を拾う
    final m = RegExp(r'"?answer"?\s*:\s*"?(1|2)"?').firstMatch(candidate);
    if (m != null) return m.group(1)!;

    // 4) さらに最後の保険: 文中の単独 1/2
    final n = RegExp(r'\b[12]\b').firstMatch(candidate);
    if (n != null) return n.group(0)!;

    return '';
  }

  // 問5：ユーザー入力の翻訳
  Future<void> _handleUserAnswerTranslation(String userText, AppLocalizations loc) async {
    // 1) ユーザー入力の翻訳
    final prompt = PromptBuilders.buildUserAnswerTranslationPrompt(
      userAnswer: userText,
      nativeLang: nativeName,
    );
    final res = await GptService.getChatResponse(prompt, userText, loc);
    final translation = res?.trim() ?? '';

    // 2) 誤答解説を取得
    final explanationPrompt = PromptBuilders.buildIncorrectAnswerExplanationPrompt(
      userAnswer: userText,
      nativeLang: nativeName,
      targetLang: targetName,
    );
    final explRes = await GptService.getChatResponse(
      explanationPrompt,
      userText,
      loc,
    );
    final explanation = explRes?.trim();

    // 3) 翻訳と解説をひとつの吹き出しにまとめて追加
    final buffer = StringBuffer();
    buffer.write(loc.answerMeaningPrefix(translation));
    if (explanation != null &&
        explanation.isNotEmpty &&
        explanation.toLowerCase() != 'null') {
      buffer.write('\n');
      buffer.write(explanation);
    }
    setState(() {
      _messages.add({
        'role': 'bot',
        'text': buffer.toString(),
      });
    });
  }

  Future<void> _handleOriginalQuestionTranslation(
    String questionText,
    AppLocalizations loc, {
    String? rawInput,
    bool useAnswerPrefix = true,
    bool onlyFirstBubble = false,
    bool addAccuracyNoticeBubble = false,  // 追加：通知バブル
    bool skipFirstBubble = false,          // 追加：①をスキップ
  }) async {
    // ①：模範訳の生成（skipFirstBubble が false の場合のみやる）
    String? translatedText;
    String? nativeOriginalText;
    String? transcription6;

    if (!skipFirstBubble) {
      // ① 問6：模範訳の生成
      final prompt6 = PromptBuilders.buildOriginalQuestionTranslationPrompt(
        originalQuestion: questionText,
        targetLang: targetName,
      );
      final String? res6 = await GptService.getChatResponse(
        prompt6,
        questionText,
        loc,
      );
      if (res6 == null) {
        print('❌ 問6の翻訳に失敗しました');
        return;
      }
      final translatedText = res6.trim();

      // ——— ここから追加 ———
      // 問10’: オリジナル文の母語での逆翻訳
      final promptNative6 = PromptBuilders.buildSimilarQuestionInNativeLangPrompt(
        translatedText: translatedText,
        nativeLang: nativeName,
      );
      final String? nativeOriginal = await GptService.getChatResponse(
        promptNative6,
        translatedText,
        loc,
      );
      // “null” を捨てる
      nativeOriginalText =
          (nativeOriginal == null || nativeOriginal.toLowerCase() == 'null')
              ? null
              : nativeOriginal.trim();

      // 問12’: オリジナル文の音声転写
      String? rawTrans6;
      if (const {'ja', 'zh', 'zh_tw', 'ko'}.contains(widget.targetLang)) {
        final promptTts6 = PromptBuilders.buildSimilarQuestionTtsPrompt(
          translatedText: translatedText,
          targetLang: widget.targetLang,
        );
        rawTrans6 = await GptService.getChatResponse(
          promptTts6,
          translatedText,
          loc,
        );
      } else {
        rawTrans6 = null;
      }
      final String? transcription6 =
          (rawTrans6 == null || rawTrans6.toLowerCase() == 'null')
              ? null
              : rawTrans6.trim();
      // ——— ここまで追加 ———

      // ①の ChatBubble を表示
      setState(() {
        _messages.add({
          'role': 'bot',
          'text': useAnswerPrefix
              ? loc.answerMeaningPrefix(translatedText)
              : loc.answerTranslationPrefix,
          'highlightBody': translatedText,   // 本文（例: Nice to meet you.）

          'tts': translatedText,
          'showTtsBody': false,              // 本文に重複表示させない

          'targetLang': widget.targetLang,
          // 追加分をもし取れたらキーに含める
          if (nativeOriginalText != null) 'nativeText': nativeOriginalText,
          if (transcription6    != null) 'transcription': transcription6,
        });
      });
    }

    // ★ 正解通知バブル（②以降の“上”に差し込む）
    if (addAccuracyNoticeBubble) {
      setState(() {
        _messages.add({
          'role': 'bot',
          'text': loc.answerMeaningAccurate, // ← arbのキー名に合わせて
          'labelType': 'info',               // 任意（UIで淡色など）
        });
      });
    }

    // ✅ 「①だけで終わる」モードの早期終了は残すが、
    //    今回は skipFirstBubble=true のときはここに来ないので影響なし
    if (onlyFirstBubble) return;

    // ②：類似表現
    //   ※ ①をスキップしているので、ここは questionText → translatedText を使わずに
    //      「類似表現を直接生成」する既存のプロンプトを使用（translatedText ではなく questionText 由来の意味でOKな設計なら、buildSimilarQuestionPromptの引数を translatedText にしても良い）
    final String seedForSimilar = (translatedText ?? questionText);
    
    // ② 問8：類似表現を生成（同一文は再生成）
    final avoidList = <String>[];
    if (rawInput != null && rawInput.trim().isNotEmpty) avoidList.add(rawInput);
    if (translatedText != null && translatedText!.trim().isNotEmpty) {
      avoidList.add(translatedText!);
    }
    String? userRomaji;
    if (_targetCode == 'ja' && rawInput != null && rawInput.trim().isNotEmpty) {
      userRomaji = await _romajiForJapanese(rawInput, loc);
    }

    String? similar = await _generateSimilarExpression(
      seed: seedForSimilar,
      targetLang: targetName,
      loc: loc,
      avoidList: avoidList,
    );

    if (similar == null || similar.trim().isEmpty) {
      print('❌ 問8の類似表現生成に失敗しました');
      return;
    }

    String? similarRomaji;
    if (_targetCode == 'ja' && userRomaji != null) {
      similarRomaji = await _romajiForJapanese(similar, loc);
      if (_isSameRomaji(similarRomaji, userRomaji)) {
        final retry = await _generateSimilarExpression(
          seed: seedForSimilar,
          targetLang: targetName,
          loc: loc,
          avoidList: [...avoidList, similar],
        );
        if (retry != null && retry.trim().isNotEmpty) {
          similar = retry;
          similarRomaji = await _romajiForJapanese(similar, loc);
        }
      }
    }

    // ③ 問10：同義の文の母語での訳を生成
    final prompt10 = PromptBuilders.buildSimilarQuestionInNativeLangPrompt(
      translatedText: similar,
      nativeLang: nativeName,
    );

    final String? nativeSimilar = await GptService.getChatResponse(
      prompt10,
      similar,
      loc,
    );

    if (nativeSimilar == null) {
      print('❌ 問10の母語での訳生成に失敗しました');
      return;
    }

    // 問12：同義の文の音声転写を作成する
    String? rawTranscription;
    final norm = widget.targetLang.replaceAll('-', '_').toLowerCase();
    if (norm == 'ja' && similarRomaji != null) {
      rawTranscription = similarRomaji;
    } else if (const {'ja', 'zh', 'zh_tw', 'ko'}.contains(norm)) {
      final prompt12 = PromptBuilders.buildSimilarQuestionTtsPrompt(
        translatedText: similar,
        targetLang: widget.targetLang,
      );
      rawTranscription = await GptService.getChatResponse(
        prompt12,
        similar,
        loc,
      );
    } else {
      rawTranscription = null;
    }

    // “null” 文字列は捨てて、その他はそのまま使う
    final String? transcription =
        (rawTranscription == null || rawTranscription.toLowerCase() == 'null')
            ? null
            : rawTranscription;

    // ★ ハイライト本文（類似表現＋転写＋母語訳を全部まとめる）
    final simLines = <String>[];
    simLines.add(similar);                         // 1行目：類似表現
    if (transcription != null && transcription.isNotEmpty) {
      simLines..add('')..add(transcription);      // ラベル不要なら転写だけ
    }
    if (nativeSimilar.isNotEmpty) {
      simLines..add('')..add(nativeSimilar);      // ラベル不要ならそのまま
    }

    // まとめて ChatBubble に表示
    setState(() {
      _messages.add({
        'role': 'bot',

        // 🔶 黄色ハイライト
        'highlightTitle': loc.similarExpressionHeader, // 例: 類似表現
        'highlightBody': simLines.join('\n'),

        // TTS は similar のみ
        'tts': similar,
        'showTtsBody': false,

        'targetLang': widget.targetLang,
        // 'nativeText':  nativeSimilar,   // ← ChatBubble で拾って表示
        // transcription が null のときはキーごと省略したい場合は
        // if (transcription != null) 'transcription': transcription,
      });
    });
  }

  void _cancelInput() {
    _controller.clear();
    setState(() {
      _hasInput = false;
      _isKeyboardMode = false;
    });
  }

  void _resetChat() async {
    await _speechService.stop();
    await _tts.stop(); // ← 追加：念のため現在のTTS停止
    _controller.clear();
    final loc = AppLocalizations.of(context)!;
    _loadQuestion(loc);
    // _speakIfListeningAfterBuild(); // ← 追加
  }

  void _openQuestionListFromRecommend() {
    final scene = widget.recommendedReturnScene ?? widget.scene;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuestionListScreen(
          selectedScene: scene,
          targetLang: widget.targetLang,
          mode: _mode,
        ),
      ),
    );
  }

  Widget _styledBackButton(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 20,
          color: Colors.black87,
        ),
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: () => Navigator.of(context).maybePop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isListening = _mode == QuizMode.listening;
    final canPop = Navigator.of(context).canPop();
    final topInset = MediaQuery.of(context).padding.top + (isListening ? 0 : kToolbarHeight);
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F9),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: isListening ? 0 : kToolbarHeight,
        leading: (!isListening && canPop)
            ? Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _styledBackButton(context),
              )
            : null,
        title: isListening
            ? null
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: scheme.surface.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: scheme.outlineVariant.withOpacity(0.4)),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _langPill(context, _displayLangCode(widget.nativeLang)), // 例: EN / JA
                      const SizedBox(width: 8),
                      const Icon(Icons.east_rounded, size: 20, color: Colors.grey),
                      const SizedBox(width: 8),
                      _langPill(context, _displayLangCode(widget.targetLang)), // 例: EN / JA
                    ],
                  ),
                ),
              ),
      ),

      body: Stack(
        children: [
          Positioned.fill(
            child: Image(
              image: AssetImage(CharacterAssetService.chatBackground(_selectedCharacter)),
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: topInset),
            child: Column(
              children: [
                if (widget.showRecommendedStartLink)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: Align(
                      alignment: Alignment.center,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.black.withOpacity(0.08)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.14),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextButton(
                          onPressed: _openQuestionListFromRecommend,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            foregroundColor: Colors.black87,
                          ),
                          child: const Text(
                            'おすすめから開始しました（問題を選び直す）',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // ★ 出題テキストを中央寄せ＆太字で表示（Readingモードのときだけ）
                if (_mode == QuizMode.reading && _currentNativeText.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 31.5,
                          backgroundImage: AssetImage(
                            CharacterAssetService.chatAvatar(_selectedCharacter),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isPromptExpanded = !_isPromptExpanded;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF0F5),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.pink.shade200.withOpacity(0.6),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _tsumugiQuestionText.isNotEmpty
                                        ? _tsumugiQuestionText
                                        : _currentNativeText,
                                    textAlign: TextAlign.left,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  if (tsumugi_prompt.formatPromptQuote(_nativeCode, _currentNativeText).isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    _ExpandablePromptText(
                                      text: tsumugi_prompt.formatPromptQuote(_nativeCode, _currentNativeText),
                                      isExpanded: _isPromptExpanded,
                                      maxLines: 2,
                                      expandLabel: loc.tapToExpand,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFE91E63),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Listening 見出し＋カード（Listeningのみ）
                if (_mode == QuizMode.listening) ...[
                  // 見出し
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),  // ★必須
                    child: Text(
                      loc.listeningPrompt,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  // ぼかし＋大きい再生ボタン
                  _listeningQuestionCard(),
                ],

                Expanded(child: MessageList(messages: _messages)),

                if (_isLoading)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)!.checking,
                          style: const TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ],
                    ),
                  ),

                MicArea(
                  isListening: _isListening,
                  isKeyboardMode: _isKeyboardMode,
                  hasInput: _hasInput,
                  hasSubmitted: _hasSubmitted,
                  waveformSamples: _ampQueue.toList(),
                  controller: _controller,
                  onMicTap: _isListening ? _confirmRecording : _startListening,
                  onRecordCancel: _cancelRecording,
                  onRecordConfirm: _confirmRecording,
                  onKeyboardTap: _activateKeyboardMode,
                  onSend: () {
                    setState(() => _revealListeningText = true); // ★ここで解除
                    _sendMessage();
                  },
                  onCancel: _cancelInput,
                  onReset: _resetChat,          // ← リロード時に再生も入れてある版
                  onNext: _loadNextQuestion,    // ← 次へで再生も入れてある版
                  onTextChanged: (text) => setState(() {
                    _hasInput = text.trim().isNotEmpty;
                  }),
                  focusNode: _inputFocusNode,
                  onDone: () {
                    if (_controller.text.trim().isEmpty) {
                      _cancelInput();
                    } else {
                      _speechService.stop(); // 念のためマイク停止
                      setState(() {
                        _isKeyboardMode = false;
                        _isListening    = false;
                      });
                    }
                  },
                ),

                KeyboardGuideButton(targetLanguage: widget.targetLang),
              ],
            ),
          ),
          if (isListening && canPop)
            Positioned(
              top: 0,
              left: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _styledBackButton(context),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ExpandablePromptText extends StatelessWidget {
  const _ExpandablePromptText({
    required this.text,
    required this.isExpanded,
    required this.maxLines,
    required this.expandLabel,
    required this.style,
  });

  final String text;
  final bool isExpanded;
  final int maxLines;
  final String expandLabel;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: maxLines,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: constraints.maxWidth);

        final isOverflowing = painter.didExceedMaxLines;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: style,
              maxLines: isExpanded ? null : maxLines,
              overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
            if (!isExpanded && isOverflowing)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  expandLabel,
                  style: style.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
