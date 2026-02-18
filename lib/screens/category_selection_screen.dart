// lib/screens/category_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kawaii_lang/l10n/app_localizations.dart';
import 'question_list_screen.dart';
import 'settings_screen.dart';
import '../services/subscription_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:kawaii_lang/models/language.dart';
import 'dart:convert';                     // jsonDecode
import 'package:flutter/services.dart';    // rootBundle
import '../models/quiz_mode.dart';
import 'package:flutter/foundation.dart'; // kReleaseMode
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../services/subscription_state.dart';
import 'chat_screen.dart';
import '../services/tsumugi_quote_service.dart';

class CategorySelectionScreen extends StatefulWidget {
  const CategorySelectionScreen({Key? key}) : super(key: key);

  @override
  _CategorySelectionScreenState createState() => _CategorySelectionScreenState();
}

class _CategorySelectionScreenState extends SubscriptionState<CategorySelectionScreen> {
  String? selectedTargetLang;
  String? selectedSceneKey;
  String? selectedNativeLang;

  List<Scene> _allScenes = [];

  // シーンごとの問題数を保存
  Map<String, int> _counts = {};

  QuizMode selectedMode = QuizMode.reading;
  static const String _quickStartPrefKey = 'has_used_quick_start';
  static const String _quizModePrefKey = 'quiz_mode';
  String? _tsumugiQuote;
  @override
  void initState() {
    super.initState();
    selectedSceneKey = 'trial';
    _loadLanguage();
    _loadTargetLanguage();
    _loadQuizMode();
    _loadScenesJson();   // ← 追加
    _loadTsumugiQuote();
    
    // 🔑 サブスク検証サービスを初期化
    // maybeInitSubscription(); // 🔑 追加：サブスク状態を1日1回だけ確認
  }

  // scenes.json をパースして _allScenes にセット
  Future<void> _loadScenesJson() async {
    final jsonStr = await rootBundle.loadString('assets/questions/scenes.json');
    final List<dynamic> jsonList = jsonDecode(jsonStr) as List<dynamic>;
    final loaded = jsonList
      .map((e) => Scene.fromJson(e as Map<String,dynamic>))
      .toList();
    // print('▶ loaded scenes:  [38;5;2m${loaded.map((s) => s.id).toList()} [0m');

    // print('▶ loaded scenes: ${loaded.map((s) => s.id).toList()}');

    if (!mounted) return;
    setState(() => _allScenes = loaded);

    // 件数をまとめて取得
    final entries = await Future.wait(loaded.map((s) async {
      final c = await _loadQuestionCountForScene(s.id);
      return MapEntry(s.id, c);
    }));

    if (!mounted) return;
    setState(() => _counts = Map.fromEntries(entries));
  }

  Future<int> _loadQuestionCountForScene(String sceneId) async {
    try {
      // 例: assets/questions/trial.json, assets/questions/greeting.json ...
      final path = 'assets/questions/$sceneId.json';
      final jsonStr = await rootBundle.loadString(path);
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list.length;
    } catch (e) {
      debugPrint('count load failed for $sceneId: $e');
      return 0; // ファイル無しなどは0件扱い
    }
  }

  Future<void> maybeInitSubscription() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheck = prefs.getInt('last_subscription_check') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    // const oneDayInMillis = 86400000; // 24時間 = 86400000ms
    const oneDayInMillis = 600000; // 10分間おきにレシートチェック

    if (now - lastCheck > oneDayInMillis) {
      try {
        await SubscriptionService.instance.init();
        await prefs.setInt('last_subscription_check', now);
        print('✅ サブスク状態を更新しました');
      } catch (e) {
        print('❌ サブスク状態の更新に失敗しました: $e');
      }
    } else {
      print('🔁 サブスクチェックは24時間以内のためスキップ');
    }
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedNativeLang = prefs.getString('user_language') ?? 'ja';
    });
  }

  Future<void> _loadTargetLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedTargetLang = prefs.getString('target_language');
    });
  }

  Future<void> _loadQuizMode() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_quizModePrefKey);
    final mode = raw == QuizMode.listening.name ? QuizMode.listening : QuizMode.reading;
    if (!mounted) return;
    setState(() => selectedMode = mode);
  }

  Future<void> _loadTsumugiQuote() async {
    final quote = await TsumugiQuoteService.instance.getNextQuote();
    if (!mounted) return;
    setState(() => _tsumugiQuote = quote);
  }

  Future<void> _onSubmit() async {
    final loc = AppLocalizations.of(context)!;

    // ① 未選択チェック
    if ([selectedNativeLang, selectedTargetLang, selectedSceneKey].contains(null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.selectPrompt)),
      );
      return;
    }

    // ② ネイティブ言語とターゲット言語が同じチェック
    if (selectedNativeLang == selectedTargetLang) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.selectPrompt)),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final hasUsedQuickStart = prefs.getBool(_quickStartPrefKey) ?? false;

    if (!hasUsedQuickStart) {
      await prefs.setBool(_quickStartPrefKey, true);
      await _goToRecommendedChat();
      return;
    }

    // ③ OKなら通常の出題選択画面へ
    _goToQuestionList();
  }

  Future<void> _onSceneTap(String key) async {
    setState(() => selectedSceneKey = key);
    addBreadcrumb();
    await _onSubmit();
  }

  IconData _sceneIcon(String key) {
    switch (key) {
      case 'trial':
        return Icons.local_cafe_rounded;
      case 'travel':
        return Icons.flight_rounded;
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'hotel':
        return Icons.hotel_rounded;
      case 'hospital':
        return Icons.local_hospital_rounded;
      case 'emergency':
        return Icons.warning_rounded;
      case 'taxi':
        return Icons.local_taxi_rounded;
      case 'business':
        return Icons.work_rounded;
      case 'daily':
        return Icons.home_rounded;
      default:
        return Icons.menu_book_rounded;
    }
  }

  // ① 強制クラッシュ（致命的クラッシュを送る）
  void triggerFatalCrash() {
    if (kReleaseMode) return; // 本番では無効
    FirebaseCrashlytics.instance.crash();
  }

  // ② 非致命エラー（アプリは落とさず送る）
  void triggerNonFatal() async {
    if (kReleaseMode) return;
    try {
      throw StateError('Test non-fatal error');
    } catch (e, st) {
      await FirebaseCrashlytics.instance.recordError(
        e, st,
        reason: 'manual test non-fatal',
        information: ['screen: Home', 'tap: TestButton'],
      );
    }
  }

  // ③ ついでにパンくずログ
  void addBreadcrumb() {
    FirebaseCrashlytics.instance.log('User tapped Start button');
  }

  void _goToQuestionList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuestionListScreen(
          selectedScene: selectedSceneKey!,
          targetLang: selectedTargetLang!,
          mode: selectedMode, // ★追加
        ),
      ),
    );
  }

  Future<void> _goToRecommendedChat() async {
    final nativeLang = selectedNativeLang;
    final targetLang = selectedTargetLang;
    if (nativeLang == null || targetLang == null) return;

    try {
      final raw = await rootBundle.loadString('assets/questions/trial.json');
      final arr = jsonDecode(raw) as List<dynamic>;
      final questions = arr
          .map((e) => Question.fromJson(e as Map<String, dynamic>))
          .toList();

      if (questions.isEmpty) {
        _goToQuestionList();
        return;
      }

      const previewId = 'trial_greeting_001';
      var selectedIndex = questions.indexWhere((q) => q.id == previewId);
      if (selectedIndex == -1) {
        selectedIndex = questions.indexWhere(
          (q) => q.getText('ja').contains('はじめまして'),
        );
        if (selectedIndex == -1) selectedIndex = 0;
      }

      final questionList = questions.map((qq) {
        return {
          'id': qq.id,
          'scene': qq.scene,
          'subScene': qq.subScene,
          'level': qq.level,
          nativeLang: qq.getText(nativeLang),
          targetLang: qq.getText(targetLang),
        };
      }).toList();

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            nativeLang: nativeLang,
            targetLang: targetLang,
            scene: 'trial',
            promptLang: nativeLang,
            isNativePrompt: true,
            selectedQuestionText: questions[selectedIndex].getText(nativeLang),
            correctAnswerText: questions[selectedIndex].getText(targetLang),
            questionList: questionList,
            selectedIndex: selectedIndex,
            mode: selectedMode,
            showRecommendedStartLink: true,
            recommendedReturnScene: selectedSceneKey,
          ),
        ),
      );
    } catch (e) {
      debugPrint('recommended chat load failed: $e');
      _goToQuestionList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    // JSON読込み後の動的リストを作成
    final sceneItems = _allScenes.map((scene) => {
      'key':   scene.id,                                // ex. "trial","travel"...
      'label': scene.label[loc.localeName] ?? scene.id, // ロケール対応ラベル
    }).toList();

    // ここを追加
    // print('▶ sceneItems: ${sceneItems.map((i) => i['key']).toList()}');

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.settings_rounded,
                color: Colors.black87,
                size: 22,
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ).then((_) {
                // 設定画面から戻ってきたときに母語を再読み込み
                _loadLanguage();
                _loadTargetLanguage();
                _loadQuizMode();
                _loadTsumugiQuote();
              });
            },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/characters/tumugi_menu.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const specialHeight = 68.0;
                const specialGap = 8.0;
                const bottomGap = 20.0;
                const modeHeight = 0.0;
                const rowHeight = 58.0;
                const dividerHeight = 1.0;
                const rowsVisible = 5;
                const quoteHeight = 64.0;
                const paddingTop = 8.0;
                const paddingBottom = 24.0;
                final hasQuote = _tsumugiQuote != null;
                final paperHeight = (rowHeight * rowsVisible) + (dividerHeight * (rowsVisible - 1));
                final availableHeight = constraints.maxHeight - paddingTop - paddingBottom;
                final desiredQuoteTop = availableHeight * 0.40;
                final desiredSpecialTop = availableHeight * 0.50;
                final gapBetween = hasQuote
                    ? (desiredSpecialTop - desiredQuoteTop - quoteHeight).clamp(0.0, 120.0)
                    : 0.0;

                var topGap = hasQuote ? desiredQuoteTop : desiredSpecialTop;
                final totalHeight = topGap
                    + (hasQuote ? quoteHeight : 0.0)
                    + gapBetween
                    + specialHeight
                    + specialGap
                    + paperHeight
                    + bottomGap
                    + modeHeight;
                final overflow = totalHeight - availableHeight;
                if (overflow > 0) {
                  topGap = (topGap - overflow).clamp(0.0, topGap);
                }

                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: topGap),
                      if (_tsumugiQuote != null)
                        Align(
                          alignment: Alignment.center,
                          child: SizedBox(
                            width: constraints.maxWidth * 0.624,
                            height: quoteHeight,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF0F5),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.pink.shade200.withOpacity(0.6),
                                ),
                              ),
                              child: Text(
                                _tsumugiQuote!,
                                maxLines: 2,
                                overflow: TextOverflow.clip,
                                softWrap: true,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 14, height: 1.35),
                              ),
                            ),
                          ),
                        ),
                      if (_tsumugiQuote != null)
                        SizedBox(height: gapBetween),
                      Align(
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: constraints.maxWidth * 0.624,
                          child: Container(
                            height: specialHeight,
                            alignment: Alignment.center,
                            margin: const EdgeInsets.only(bottom: specialGap),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEE5DB),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFDCD6CE)),
                            ),
                            child: const Text(
                              "Today's Special (1 min)",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: constraints.maxWidth * 0.546,
                          child: Container(
                            height: paperHeight,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEE5DB),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFDCD6CE)),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: ListView.separated(
                                padding: EdgeInsets.zero,
                                physics: const BouncingScrollPhysics(),
                                itemCount: sceneItems.length,
                                separatorBuilder: (context, index) => Divider(
                                  height: 1,
                                  color: const Color(0xFFE3DED8).withOpacity(0.8),
                                ),
                                itemBuilder: (context, index) {
                                  final item   = sceneItems[index];
                                  final key    = item['key'] as String;
                                  final label  = item['label'] as String;
                                  final count  = _counts[key];
                                  final active = selectedSceneKey == key;

                                  return Material(
                                    color: active ? const Color(0xFFEAE6E1).withOpacity(0.8) : Colors.transparent,
                                    child: InkWell(
                                      onTap: () => _onSceneTap(key),
                                      splashColor: const Color(0xFFE0DBD6).withOpacity(0.5),
                                      highlightColor: const Color(0xFFE6E1DB).withOpacity(0.5),
                                      child: SizedBox(
                                        height: 58,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 14),
                                          child: Row(
                                            children: [
                                              Icon(
                                                _sceneIcon(key),
                                                size: 20,
                                                color: Colors.pink.shade400,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      label,
                                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 2),
                                                    if (count == null)
                                                      const SizedBox(
                                                        height: 12,
                                                        width: 12,
                                                        child: CircularProgressIndicator(strokeWidth: 2),
                                                      )
                                                    else
                                                      Text(
                                                        '($count)',
                                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              const Icon(
                                                Icons.chevron_right,
                                                size: 20,
                                                color: Colors.grey,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ).animate().fade(duration: 300.ms).slideX(begin: 0.05),
                      const SizedBox(height: bottomGap),

                      const SizedBox(height: 12),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
