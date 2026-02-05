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

class CategorySelectionScreen extends StatefulWidget {
  const CategorySelectionScreen({Key? key}) : super(key: key);

  @override
  _CategorySelectionScreenState createState() => _CategorySelectionScreenState();
}

class _CategorySelectionScreenState extends State<CategorySelectionScreen> {
  String? selectedTargetLang;
  String? selectedSceneKey;
  String? selectedNativeLang;

  List<Scene> _allScenes = [];

  // シーンごとの問題数を保存
  Map<String, int> _counts = {};

  QuizMode selectedMode = QuizMode.reading;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    _loadTargetLanguage();
    _loadScenesJson();   // ← 追加
    
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

  void _onSubmit() {
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

    // ③ OKなら画面遷移
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
        title: Text(loc.categoryTitle),
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

                return GestureDetector(
                  onTap: () => setState(() => selectedSceneKey = key),
                  child: Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: active ? Colors.pink.shade300 : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Padding(
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
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
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
