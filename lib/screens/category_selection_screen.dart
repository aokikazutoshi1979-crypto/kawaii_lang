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
import 'package:kawaii_lang/widgets/mode_toggle_bar.dart';
import 'package:kawaii_lang/config/quiz_mode_config.dart';
import '../models/quiz_mode.dart';
import 'package:flutter/foundation.dart'; // kReleaseMode
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../services/subscription_state.dart';
import 'chat_screen.dart';
import '../services/history_service.dart';

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
  int _todayCorrect = 0;
  int _streakDays = 0;

  @override
  void initState() {
    super.initState();
    selectedSceneKey = 'trial';
    _loadLanguage();
    _loadTargetLanguage();
    _loadScenesJson();   // ← 追加
    _loadDailyStats();
    
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

  String _getSceneImagePath(String key) => 'assets/images/backgrounds/$key.png';

  Future<void> _loadDailyStats() async {
    final stats = await HistoryService.instance.getTodayCorrectAndStreak();
    if (!mounted) return;
    setState(() {
      _todayCorrect = stats.todayCorrect;
      _streakDays = stats.streakDays;
    });
  }

  Widget _buildDailyStats(AppLocalizations loc) {
    Widget statChip(String text) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.pink.shade100),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Row(
      children: [
        Expanded(child: statChip(loc.todayCorrectCount(_todayCorrect))),
        const SizedBox(width: 8),
        Expanded(child: statChip(loc.streakDaysCount(_streakDays))),
      ],
    );
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
    ).then((_) => _loadDailyStats());
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
      ).then((_) => _loadDailyStats());
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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ).then((_) {
                // 設定画面から戻ってきたときに母語を再読み込み
                _loadLanguage();
                _loadTargetLanguage();
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          _buildDailyStats(loc),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(loc.scene, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          SizedBox(
            height: 360, // お好みで 200〜240
            child: GridView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              itemCount: sceneItems.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,      // 上下2列
                mainAxisSpacing: 8,     // 横方向の間隔
                crossAxisSpacing: 8,    // 縦方向の間隔
                mainAxisExtent: 190,    // カードの“横幅”（180〜200で調整）
              ),
              itemBuilder: (context, index) {
                final item   = sceneItems[index];
                final key    = item['key']!;
                final label  = item['label']!;
                final count  = _counts[key];
                final active = selectedSceneKey == key;
                final isFree = key == 'trial';
                final showLock = !hasSubOnDevice && !isFree;

                return GestureDetector(
                  onTap: () => setState(() => selectedSceneKey = key),
                  child: Card(
                    color: Colors.white,
                    clipBehavior: Clip.hardEdge,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: active ? Colors.pink.shade300 : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                _getSceneImagePath(key),
                                height: 70,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                label,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              if (count == null)
                                const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2))
                              else
                                Text(
                                  '($count)',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                                  textAlign: TextAlign.center,
                                ),
                            ],
                          ),
                        ),
                        if (isFree)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.pink.shade300,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'FREE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ),
                        if (showLock)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Icon(
                                Icons.lock_rounded,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ).animate().fade(duration: 300.ms).slideX(begin: 0.1);
              },
            ),
          ), // ← ここで SizedBox を閉じる
            const SizedBox(height: 20),

            if (QuizModeToggleConfig.showInCategorySelection)
              ModeToggleBar(
                value: selectedMode,
                onChanged: (m) => setState(() => selectedMode = m),
                readingLabel:   loc.readingLabel,   // ← ARB
                listeningLabel: loc.listeningLabel, // ← ARB
              ),

            const SizedBox(height: 12),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.pink.shade500,
                foregroundColor: Colors.white,
                elevation: 2,
                shadowColor: Colors.pink.shade200,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                addBreadcrumb();
                // 実機テスト時だけ手動で切り替え
                // triggerFatalCrash();   // ← 落ちる（致命）
                // triggerNonFatal();     // ← 落ちない（非致命）
                _onSubmit();             // 本来の処理
              },
              child: Text(loc.start, style: const TextStyle(fontSize: 18)),
            ).animate().scale(duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
