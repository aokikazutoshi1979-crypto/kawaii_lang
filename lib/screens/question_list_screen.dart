// lib/screens/question_list_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kawaii_lang/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';
import '../services/subscription_state.dart';
import '../services/subscription_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart' show Offerings;
import 'subscription_screen.dart';
import 'package:kawaii_lang/models/language.dart';
import '../services/scene_catalog.dart';
import 'package:kawaii_lang/config/quiz_mode_config.dart';
import 'package:kawaii_lang/widgets/mode_toggle_bar.dart';
import '../models/quiz_mode.dart';
import '../common/scene_label.dart';
import '../services/history_service.dart';
import '../utils/lang_utils.dart'; // getLangCode を使うなら

class QuestionListScreen extends StatefulWidget {
  final String selectedScene;
  final String targetLang;
  final QuizMode mode; // ★追加
  const QuestionListScreen({
    Key? key,
    required this.selectedScene,
    required this.targetLang,
    required this.mode,
  }) : super(key: key);

  @override
  _QuestionListScreenState createState() => _QuestionListScreenState();
}

class SceneCatalog with ChangeNotifier {
  SceneCatalog._();
  static final SceneCatalog instance = SceneCatalog._();

  bool _loaded = false;

  /// subSceneId → { 'ja': '挨拶', 'en': 'Greeting', ... }
  final Map<String, Map<String, String>> _subsceneLabels = {};

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final raw = await rootBundle.loadString('assets/questions/scenes.json');
    final List<dynamic> arr = json.decode(raw) as List<dynamic>;

    for (final s in arr) {
      final subScenes = (s as Map)['subScenes'] as List<dynamic>? ?? const [];
      for (final ss in subScenes) {
        final m = ss as Map<String, dynamic>;
        final id = (m['id'] ?? '').toString();
        final label = (m['label'] as Map?)?.map(
              (k, v) => MapEntry(k.toString(), v.toString()),
            ) ??
            const <String, String>{};
        if (id.isNotEmpty && label.isNotEmpty) {
          _subsceneLabels[id] = label.cast<String, String>();
        }
      }
    }

    _loaded = true;
    notifyListeners();
  }

  // ロケールからキーを作って取得
  String? labelForSubscene(String subSceneId, Locale locale) {
    final map = _subsceneLabels[subSceneId];
    if (map == null) return null;

    // zh-TW / Hant は zh_TW に寄せる、それ以外は languageCode 優先
    final script = (locale.scriptCode ?? '').toLowerCase();
    final cc = (locale.countryCode ?? '').toUpperCase();
    if (locale.languageCode == 'zh') {
      final key = (cc == 'TW' || script == 'hant') ? 'zh_TW' : 'zh';
      return map[key] ?? map['en'] ?? map.values.first;
    }
    return map[locale.languageCode] ?? map['en'] ?? map.values.first;
  }

  // 言語コード文字列（ja, ja_JP, en-US, zh-Hant-TW etc.）から取得
  String? labelForSubsceneByCode(String subSceneId, String code) {
    final map = _subsceneLabels[subSceneId];
    if (map == null) return null;
    final key = _normalizeCode(code);
    return map[key] ?? map[code] ?? map['en'] ?? (map.isNotEmpty ? map.values.first : null);
  }

  String _normalizeCode(String code) {
    final c = code.replaceAll('-', '_'); // en-US → en_US
    if (c == 'zh_TW' || c == 'zh_Hant_TW') return 'zh_TW';
    if (c.startsWith('zh')) return 'zh'; // zh_CN, zh_Hans → zh
    final parts = c.split('_');
    return parts.first; // ja_JP → ja, en_US → en
  }

  // 🔧 デバッグ用：今回のprintで使うメソッド
  int get debugSubsceneCount => _subsceneLabels.length;
  Map<String, String>? debugLabelsFor(String id) => _subsceneLabels[id];
}

class _QuestionListScreenState extends SubscriptionState<QuestionListScreen> {
  Set<String> _cleared = {};
  bool _loadingCleared = false;
  bool _wroteHistory = false;

  late QuizMode _mode;
  // Helper to map scene key to localized label
  String _sceneLabel(String scene, AppLocalizations loc) {
    switch (scene) {
      case 'trial': return loc.sceneTrial;
      case 'vocabulary': return loc.sceneVocabulary;
      case 'greeting': return loc.sceneGreeting;
      case 'travel': return loc.sceneTravel;
      case 'restaurant': return loc.sceneRestaurant;
      case 'shopping': return loc.sceneShopping;
      case 'dating': return loc.sceneDating;
      case 'culture_entertainment': return loc.sceneculture_entertainment;
      case 'community_life': return loc.scenecommunity_life;
      case 'work': return loc.sceneWork;
      case 'Social_interactions_hobbies': return loc.sceneSocial_interactions_hobbies;  

      default: return scene;
    }
  }
  late String nativeLang;
  bool hasSubscription = false;
  bool isLoading = true;
  List<Question> questions = [];

  String _subSceneLabel(String id, AppLocalizations loc) {
    // ❌ NG: Localizations.localeOf(nativeLang);  // ← Stringを渡してた
    final locale = _localeFromAppCode(nativeLang);  // ← これでOK
    final s = SceneCatalog.instance.labelForSubscene(id, locale);
    return s ?? id; // 見つからなければID表示
  }

  Locale _localeFromAppCode(String code) {
    // 例: zh_Hant_TW / zh-TW / zh_TW → zh(言語) + TW(国) + Hant(スクリプト)
    final c = code.replaceAll('-', '_');
    switch (c) {
      case 'zh_Hant_TW':
      case 'zh_TW':
        return const Locale.fromSubtags(languageCode: 'zh', countryCode: 'TW', scriptCode: 'Hant');
    }

    final parts = c.split('_');
    if (parts.length == 1) return Locale(parts[0]); // ja / en / zh / ko / es / fr / de / vi / id
    if (parts.length == 2) return Locale(parts[0], parts[1]);
    // lang_script_country (基本使わないけど保険)
    return Locale.fromSubtags(languageCode: parts[0], scriptCode: parts[1], countryCode: parts[2]);
  }

  // SubscriptionService のシングルトンを参照
  late final SubscriptionService subscriptionService;

  Set<String> _clearedSet = {};

  @override
  void initState() {
    super.initState();
    _loadCleared();
    _mode = widget.mode; // ← 初期値引き継ぎ

    // SubscriptionService のシングルトンを代入
    subscriptionService = SubscriptionService.instance;  // ← ここを修正

    // scenes.json の読み込み & nativeLang のロードを同時に待つ
    Future.wait([
      // scenes.json の読み込み（非同期・完了後に再描画）
      SceneCatalog.instance.ensureLoaded(),

      // もともとの初期化処理
      _initAll(),
    ]).then((_) {
      // ここなら両方完了済み
      final nl = nativeLang;
      final labelMap = SceneCatalog.instance.debugLabelsFor("aizuchi");
      final resolved = SceneCatalog.instance.labelForSubsceneByCode("aizuchi", nl);

      setState(() {}); // ラベル再描画
    });

    // オファリング読み込み
    _loadSubscriptionOfferings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCleared() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final targetCode = getLangCode(widget.targetLang); // "English"でも"en"でもOKな実装想定
    final nativeCode = getLangCode(nativeLang);

    final cleared = await HistoryService.instance.getClearedQuestionsByCode(
      targetCode: targetCode,
      nativeCode: nativeCode,
      scene: widget.selectedScene,   // シーン画面なら付けると精度↑（任意）
      // subScene: widget.selectedSubScene, // 必要なら
    );

    if (!mounted) return;
    setState(() {
      _clearedSet = cleared; // ← 既存の Set<String> をそのまま更新
    });
  }

  // ▼▼ 2) subScene フィルタ用の状態とヘルパー ▼▼
  String? _selectedSubScene;            // null = ALL
  List<String> _availableSubScenes = []; // JSONから抽出した subScene 一覧
  List<Question> _filtered = [];         // 表示用（questions のフィルタ結果）
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  void _applyFilter() {
    final base = questions;
    final filteredBySub = (_selectedSubScene == null)
        ? base
        : base.where((q) => q.subScene == _selectedSubScene).toList();
    final q = _searchQuery.trim();
    final next = q.isEmpty
        ? filteredBySub
        : filteredBySub
            .where((item) => item.getText(nativeLang).toLowerCase().contains(q.toLowerCase()))
            .toList();
    setState(() {
      _filtered = next;
    });
  }

  void _prepareSubScenes() {
    final set = <String>{};
    for (final q in questions) {
      if (q.subScene.isNotEmpty) set.add(q.subScene);
    }
    final list = set.toList()..sort();

    setState(() {
      _availableSubScenes = list;
    });

    _applyFilter(); // 初期表示のため適用
  }
  // ▲▲ ここまで ▼▼

  Future<void> _initAll() async {
    // 1) ユーザー設定（言語）をロード
    final prefs = await SharedPreferences.getInstance();
    nativeLang = prefs.getString('user_language') ?? 'ja';

    // 2) サブスク状態をチェック（匿名ユーザーはスキップ）

    // 3) JSON から問題リストをロード
    try {
      final raw = await rootBundle.loadString(
        'assets/questions/${widget.selectedScene}.json',
      );
      final arr = json.decode(raw) as List<dynamic>;
      questions = arr
          .map((e) => Question.fromJson(e as Map<String, dynamic>))
          .toList();

      _selectedSubScene = null; // 初期表示はALL
      _prepareSubScenes();      // ← 追加：一覧抽出＆適用
    } catch (e) {
      print('❌ 問題リストロードエラー: $e');
      questions = [];
      _availableSubScenes = [];
      _filtered = [];
    }

    // 4) ロード完了フラグを立てて画面再描画
    if (!mounted) return;
    setState(() => isLoading = false);

    // ★ 学習履歴を読み込み（言語が出揃った後）
    await _loadCleared();
  }

  void _onQuestionTap(Question q, int idx) {
    final promptText = q.getText(nativeLang);
    final correctText = q.getText(widget.targetLang);
    final questionList = questions.map((qq) {
      return {
        'id':              qq.id,                       // ← ここを追加
        'scene':     qq.scene,      // ← 追加
        'subScene':  qq.subScene,   // ← 追加
        'level':     qq.level,      // ← 追加
        nativeLang: qq.getText(nativeLang),
        widget.targetLang: qq.getText(widget.targetLang)
      };
    }).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          nativeLang: nativeLang,
          targetLang: widget.targetLang,
          scene: widget.selectedScene,
          promptLang: nativeLang,
          isNativePrompt: true,
          selectedQuestionText: promptText,
          correctAnswerText: correctText,
          questionList: questionList,
          selectedIndex: idx,
          mode: _mode, // ★ここで渡す
        ),
      ),
    ).then((_) => _loadCleared()); // ★ 戻り時に更新
  }

  /// RevenueCat のオファリング（販売プラン）を読み込んでいる最中かどうか
  bool _loadingOfferings = false;

  /// 読み込んだオファリング情報を保持する
  Offerings? _offerings;

  /// オファリングを取得して状態をセットするヘルパー
  Future<void> _loadSubscriptionOfferings() async {
    setState(() {
      _loadingOfferings = true;
    });
    try {
      final offs = await SubscriptionService.instance.getOfferings();
      setState(() {
        _offerings = offs;
      });
    } finally {
      setState(() {
        _loadingOfferings = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    // --- ここだけ！サブスク有無だけで判定 ---
    // サブスクが無ければボタンを表示、あれば非表示
    final bool hasSub = hasSubOnDevice;
    final showSubscribeButton = !hasSub;
    // トライアルシーンかどうか
    final isTrial = widget.selectedScene == 'trial';
    // トライアル以外かつ未加入のときだけロック
    final locked = !isTrial && !hasSub;
    // ---------------------------------------

    // ① セッションミスマッチ時はエラー画面のみ表示
    if (subscriptionService.isSessionMismatch) {
      return Scaffold(
        body: Center(
          child: Text(
            AppLocalizations.of(context)!.errorSessionMismatch,
          ),
        ),
      );
    }

    final user = FirebaseAuth.instance.currentUser;
    final hasPackages = !_loadingOfferings &&
        (_offerings?.current?.availablePackages.isNotEmpty ?? false);
    final package = hasPackages
        ? _offerings!.current!.availablePackages.first
        : null;

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
  _sceneLabel(widget.selectedScene, loc),
),
      ),
      body: ListView(
        children: [
            // 新コード：サブスクリプション画面へ遷移するタイルに変更
            if (showSubscribeButton && !isTrial)
              ListTile(
                leading: SizedBox(
                  width: 60,
                  height: 60,
                  child: Image.asset(
                    'assets/images/icon/basic_plan002.png',
                    fit: BoxFit.contain,
                  ),
                ),
                title: Text(loc.subscriptionManageTitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
                  );
                },
              ),
            const Divider(height: 32),

            if (QuizModeToggleConfig.showInQuestionList)
              ModeToggleBar(
                value: _mode,
                onChanged: (m) => setState(() => _mode = m),
                compact: true,
              ),

          // ▼▼ ここから subScene フィルタ ▼▼
          if (_availableSubScenes.isNotEmpty) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              onChanged: (value) {
                _searchQuery = value;
                _applyFilter();
              },
              decoration: InputDecoration(
                hintText: 'フレーズを検索',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  '絞り込み：',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                const Spacer(),
                Text(
                  _filtered.length == questions.length
                      ? '${questions.length}問'
                      : '${questions.length}問（絞り込み後 ${_filtered.length}問）',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // ALL ボタン
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(loc.subsceneAll),
                      selected: _selectedSubScene == null,
                      onSelected: (_) {
                        _selectedSubScene = null;
                        _applyFilter();
                      },
                      selectedColor: Colors.pink[100],
                      backgroundColor: Colors.white,
                      shape: StadiumBorder(side: BorderSide(color: Colors.pink.shade200)),
                      labelStyle: TextStyle(
                        color: _selectedSubScene == null ? Colors.pink.shade700 : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // subScene ごとのボタン
                  ..._availableSubScenes.map((key) {
                    final selected = _selectedSubScene == key;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(_subSceneLabel(key, loc)),
                        selected: selected,
                        onSelected: (_) {
                          _selectedSubScene = key;
                          _applyFilter();
                        },
                        selectedColor: Colors.pink[100],
                        backgroundColor: Colors.white,
                        shape: StadiumBorder(side: BorderSide(color: Colors.pink.shade200)),
                        labelStyle: TextStyle(
                          color: selected ? Colors.pink.shade700 : Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          // ▲▲ ここまで subScene フィルタ ▲▲

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: _filtered.asMap().entries.map((entry) {
                final idxFiltered = entry.key;
                final q = entry.value;

                // 元の全体リストでのインデックスを特定
                final originalIndex = questions.indexWhere((qq) => qq.id == q.id);
                final idx = originalIndex == -1 ? idxFiltered : originalIndex;

                final questionId = q.id; // ★ 追加
                final text = q.getText(nativeLang);
                final done = _clearedSet.contains(questionId);

                // ✅ 判定
                // final displayText = _clearedSet.contains(questionId)
                //     ? '✅ $text'
                //     : text;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    children: [
                      if (entry.key == 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            loc.questionListGuide,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      Stack(
                        children: [
                          Card(
                            elevation: 0,
                            color: locked ? Colors.grey[100] : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: locked ? null : () => _onQuestionTap(q, idx),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            text,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: locked ? Colors.grey : Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            loc.tapToPractice,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (locked)
                                      const Icon(Icons.lock, color: Colors.grey)
                                    else
                                      const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                                    if (done)
                                      const Padding(
                                        padding: EdgeInsets.only(left: 6),
                                        child: Icon(
                                          Icons.task_alt_rounded,
                                          size: 20,
                                          color: Colors.green,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // ロック時だけポップアップを表示する透明レイヤー
                          if (locked)
                            Positioned.fill(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  splashColor: Colors.transparent,
                                  highlightColor: Colors.transparent,
                                  onTap: () {
                                    final loc = AppLocalizations.of(context)!;
                                    showDialog<void>(
                                      context: context,
                                      barrierDismissible: true, // 外側タップで閉じられる
                                      builder: (context) {
                                        return AlertDialog(
                                          title: Text(loc.subscriptionUpsellTitle),
                                          content: Text(loc.subscriptionUpsellMessage),
                                          // actions は無し
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
