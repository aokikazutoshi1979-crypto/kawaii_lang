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
    return map[key] ??
        map[code] ??
        map['en'] ??
        (map.isNotEmpty ? map.values.first : null);
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
      case 'trial':
        return loc.sceneTrial;
      case 'todays_special':
        return loc.todaysSpecialTitle;
      case 'vocabulary':
        return loc.sceneVocabulary;
      case 'greeting':
        return loc.sceneGreeting;
      case 'travel':
        return loc.sceneTravel;
      case 'restaurant':
        return loc.sceneRestaurant;
      case 'shopping':
        return loc.sceneShopping;
      case 'dating':
        return loc.sceneDating;
      case 'culture_entertainment':
        return loc.sceneculture_entertainment;
      case 'community_life':
        return loc.scenecommunity_life;
      case 'work':
        return loc.sceneWork;
      case 'Social_interactions_hobbies':
        return loc.sceneSocial_interactions_hobbies;

      default:
        return scene;
    }
  }

  late String nativeLang;
  bool hasSubscription = false;
  bool isLoading = true;
  List<Question> questions = [];

  String _subSceneLabel(String id, AppLocalizations loc) {
    // ❌ NG: Localizations.localeOf(nativeLang);  // ← Stringを渡してた
    final locale = _localeFromAppCode(nativeLang); // ← これでOK
    final s = SceneCatalog.instance.labelForSubscene(id, locale);
    return s ?? id; // 見つからなければID表示
  }

  String _levelLabel(String level, AppLocalizations loc) {
    switch (level) {
      case 'starter':
        return loc.levelStarter;
      case 'beginner':
        return loc.levelBeginner;
      case 'intermediate':
        return loc.levelIntermediate;
      case 'advanced':
        return loc.levelAdvanced;
      case 'all':
      default:
        return loc.subsceneAll;
    }
  }

  String _topicLabel(String tag, AppLocalizations loc) {
    if (tag == 'all') return loc.subsceneAll;
    return _subSceneLabel(tag, loc);
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
        selectedColor: Colors.pink[100],
        backgroundColor: Colors.white,
        shape: StadiumBorder(side: BorderSide(color: Colors.pink.shade200)),
        labelStyle: TextStyle(
          color: selected ? Colors.pink.shade700 : Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSearchRow(AppLocalizations loc,
      {required bool showFilterButton}) {
    final hasActiveFilters = _selectedLevel != 'all' || _selectedTag != 'all';
    final hasSearch = _searchQuery.trim().isNotEmpty;
    final showClear = hasActiveFilters || hasSearch;
    return Row(
      children: [
        Expanded(
          child: TextField(
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
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
        ),
        if (showFilterButton) ...[
          const SizedBox(width: 8),
          Stack(
            clipBehavior: Clip.none,
            children: [
              InkWell(
                onTap: _openFilterSheet,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color:
                        hasActiveFilters ? Colors.pink.shade200 : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: hasActiveFilters
                        ? null
                        : Border.all(color: Colors.pink.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.filter_list,
                        size: 18,
                        color: hasActiveFilters
                            ? Colors.white
                            : Colors.pink.shade400,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        loc.filterButton,
                        style: TextStyle(
                          fontSize: 12,
                          color: hasActiveFilters
                              ? Colors.white
                              : Colors.pink.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (hasActiveFilters)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.pink.shade600,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          if (showClear) ...[
            const SizedBox(width: 6),
            TextButton(
              onPressed: () {
                _searchController.clear();
                _searchQuery = '';
                _selectedLevel = 'all';
                _selectedTag = 'all';
                _applyFilter();
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                backgroundColor: Colors.black.withOpacity(0.55),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.white.withOpacity(0.35)),
                ),
              ),
              child: Text(
                loc.filterClear,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget? _buildCompactFilterHint(AppLocalizations loc) {
    final hasActiveFilters = _selectedLevel != 'all' || _selectedTag != 'all';
    final hasSearch = _searchQuery.trim().isNotEmpty;
    if (!hasActiveFilters && !hasSearch) return null;
    final parts = <String>[];
    parts.add(loc.filterResultsCount(_filtered.length));
    if (_selectedLevel != 'all') parts.add(_levelLabel(_selectedLevel, loc));
    if (_selectedTag != 'all') parts.add(_topicLabel(_selectedTag, loc));
    final text = parts.join(' • ');
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Align(
        alignment: Alignment.center,
        child: FractionallySizedBox(
          widthFactor: 0.75,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              text,
              style: const TextStyle(fontSize: 11, color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  void _openFilterSheet() {
    final loc = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          loc.filterButton,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(loc.level,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade700)),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(
                            label: loc.subsceneAll,
                            selected: _selectedLevel == 'all',
                            onSelected: () {
                              _selectedLevel = 'all';
                              _applyFilter();
                              setModalState(() {});
                            },
                          ),
                          _buildFilterChip(
                            label: loc.levelStarter,
                            selected: _selectedLevel == 'starter',
                            onSelected: () {
                              _selectedLevel = 'starter';
                              _applyFilter();
                              setModalState(() {});
                            },
                          ),
                          _buildFilterChip(
                            label: loc.levelBeginner,
                            selected: _selectedLevel == 'beginner',
                            onSelected: () {
                              _selectedLevel = 'beginner';
                              _applyFilter();
                              setModalState(() {});
                            },
                          ),
                          _buildFilterChip(
                            label: loc.levelIntermediate,
                            selected: _selectedLevel == 'intermediate',
                            onSelected: () {
                              _selectedLevel = 'intermediate';
                              _applyFilter();
                              setModalState(() {});
                            },
                          ),
                          _buildFilterChip(
                            label: loc.levelAdvanced,
                            selected: _selectedLevel == 'advanced',
                            onSelected: () {
                              _selectedLevel = 'advanced';
                              _applyFilter();
                              setModalState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      loc.filterTopicLabel,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(
                            label: loc.subsceneAll,
                            selected: _selectedTag == 'all',
                            onSelected: () {
                              _selectedTag = 'all';
                              _applyFilter();
                              setModalState(() {});
                            },
                          ),
                          _buildFilterChip(
                            label: _subSceneLabel('aizuchi', loc),
                            selected: _selectedTag == 'aizuchi',
                            onSelected: () {
                              _selectedTag = 'aizuchi';
                              _applyFilter();
                              setModalState(() {});
                            },
                          ),
                          _buildFilterChip(
                            label: _subSceneLabel('greeting', loc),
                            selected: _selectedTag == 'greeting',
                            onSelected: () {
                              _selectedTag = 'greeting';
                              _applyFilter();
                              setModalState(() {});
                            },
                          ),
                          _buildFilterChip(
                            label: _subSceneLabel('phrases', loc),
                            selected: _selectedTag == 'phrases',
                            onSelected: () {
                              _selectedTag = 'phrases';
                              _applyFilter();
                              setModalState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Locale _localeFromAppCode(String code) {
    // 例: zh_Hant_TW / zh-TW / zh_TW → zh(言語) + TW(国) + Hant(スクリプト)
    final c = code.replaceAll('-', '_');
    switch (c) {
      case 'zh_Hant_TW':
      case 'zh_TW':
        return const Locale.fromSubtags(
            languageCode: 'zh', countryCode: 'TW', scriptCode: 'Hant');
    }

    final parts = c.split('_');
    if (parts.length == 1)
      return Locale(parts[0]); // ja / en / zh / ko / es / fr / de / vi / id
    if (parts.length == 2) return Locale(parts[0], parts[1]);
    // lang_script_country (基本使わないけど保険)
    return Locale.fromSubtags(
        languageCode: parts[0], scriptCode: parts[1], countryCode: parts[2]);
  }

  // SubscriptionService のシングルトンを参照
  late final SubscriptionService subscriptionService;

  Set<String> _clearedSet = {};

  @override
  void initState() {
    super.initState();
    _mode = widget.mode; // ← 初期値引き継ぎ

    // SubscriptionService のシングルトンを代入
    subscriptionService = SubscriptionService.instance; // ← ここを修正

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startTopControlsEntrance();
      _startDeferredInitialLoad();
    });
  }

  void _startTopControlsEntrance() {
    Future<void>.delayed(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      setState(() => _showTopControls = true);
    });
  }

  void _startDeferredInitialLoad() {
    // 画面遷移アニメーションが終わってから重い処理を開始して、見た目のカクつきを抑える
    Future<void>.delayed(const Duration(milliseconds: 520), () {
      if (!mounted) return;

      // scenes.json の読み込み & nativeLang のロードを同時に待つ
      Future.wait([
        // scenes.json の読み込み（非同期・完了後に再描画）
        SceneCatalog.instance.ensureLoaded(),

        // もともとの初期化処理
        _initAll(),
      ]).then((_) {
        if (!mounted) return;
        setState(() {}); // ラベル再描画
      });

      // オファリング読み込み
      _loadSubscriptionOfferings();
    });
  }

  Widget _buildAnimatedTopSearchRow(AppLocalizations loc) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.45),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        );
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: _showTopControls
          ? SizedBox(
              key: const ValueKey('search_row_visible'),
              child: _buildSearchRow(loc, showFilterButton: true),
            )
          : const SizedBox(
              key: ValueKey('search_row_hidden'),
              height: 0,
            ),
    );
  }

  Widget? _buildAnimatedCompactFilterHint(AppLocalizations loc) {
    final hint = _buildCompactFilterHint(loc);
    if (hint == null) return null;
    return AnimatedSlide(
      offset: _showTopControls ? Offset.zero : const Offset(0, 0.35),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: _showTopControls ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
        child: hint,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCleared() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final targetCode =
        getLangCode(widget.targetLang); // "English"でも"en"でもOKな実装想定
    final nativeCode = getLangCode(nativeLang);

    final cleared = await HistoryService.instance.getClearedQuestionsByCode(
      targetCode: targetCode,
      nativeCode: nativeCode,
      scene: widget.selectedScene, // シーン画面なら付けると精度↑（任意）
      // subScene: widget.selectedSubScene, // 必要なら
    );

    if (!mounted) return;
    setState(() {
      _clearedSet = cleared; // ← 既存の Set<String> をそのまま更新
    });
  }

  // ▼▼ 2) subScene フィルタ用の状態とヘルパー ▼▼
  String? _selectedSubScene; // null = ALL
  List<String> _availableSubScenes = []; // JSONから抽出した subScene 一覧
  List<Question> _filtered = []; // 表示用（questions のフィルタ結果）
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String _selectedLevel = 'all';
  String _selectedTag = 'all';
  bool _showTopControls = false;

  void _applyFilter() {
    final base = questions;
    Iterable<Question> filteredBySub = base;
    if (_selectedLevel != 'all') {
      filteredBySub = filteredBySub.where(
        (q) => q.level.toLowerCase() == _selectedLevel,
      );
    }
    if (widget.selectedScene == 'trial') {
      if (_selectedTag != 'all') {
        filteredBySub = filteredBySub.where(
          (q) => q.tags.contains(_selectedTag),
        );
      }
    }
    if (widget.selectedScene != 'trial') {
      filteredBySub = (_selectedSubScene == null)
          ? filteredBySub
          : filteredBySub.where((q) => q.subScene == _selectedSubScene);
    }
    final q = _searchQuery.trim();
    final next = q.isEmpty
        ? filteredBySub.toList()
        : filteredBySub
            .where((item) => item
                .getText(nativeLang)
                .toLowerCase()
                .contains(q.toLowerCase()))
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
      questions =
          arr.map((e) => Question.fromJson(e as Map<String, dynamic>)).toList();

      _selectedSubScene = null; // 初期表示はALL
      _prepareSubScenes(); // ← 追加：一覧抽出＆適用
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
        'id': qq.id, // ← ここを追加
        'scene': qq.scene, // ← 追加
        'subScene': qq.subScene, // ← 追加
        'level': qq.level, // ← 追加
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

  Future<void> _openSubscriptionFromUpsell(BuildContext dialogContext) async {
    Navigator.of(dialogContext).pop();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
    );
  }

  Future<void> _showSubscriptionUpsellDialog(AppLocalizations loc) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.97),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  loc.subscriptionUpsellTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2B2B2B),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'このカテゴリはベーシック限定です\n全カテゴリ解放\n7日間無料。期間内にキャンセルで請求なし',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    height: 1.5,
                    fontSize: 13.5,
                    color: Color(0xFF4A4A4A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _openSubscriptionFromUpsell(dialogContext),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    '7日間無料で試す',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => _openSubscriptionFromUpsell(dialogContext),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4A4A4A),
                    side: BorderSide(color: Colors.grey.shade400),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'プラン詳細を見る',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    '今はしない',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
    // トライアルシーンかどうか
    final isTrial = widget.selectedScene == 'trial' ||
        widget.selectedScene == 'todays_special';
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
    final package =
        hasPackages ? _offerings!.current!.availablePackages.first : null;
    final canPop = Navigator.of(context).canPop();

    if (isLoading) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: canPop
              ? Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: DecoratedBox(
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
                      tooltip:
                          MaterialLocalizations.of(context).backButtonTooltip,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                )
              : null,
          title: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildAnimatedTopSearchRow(loc),
          ),
        ),
        body: const Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                      'assets/images/characters/tumugi_questions.png'),
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
            ),
            Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.6,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final topInset = MediaQuery.of(context).padding.top + kToolbarHeight;
    final baseTitleSize =
        Theme.of(context).textTheme.titleLarge?.fontSize ?? 20.0;
    final freePreviewTitleSize = baseTitleSize * 1.2;
    const questionListBottomInset = 164.0;
    final hasScrollableQuestions = _filtered.length > 4;
    final scrollHintBottom = questionListBottomInset;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: canPop
            ? Padding(
                padding: const EdgeInsets.only(left: 8),
                child: DecoratedBox(
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
                    tooltip:
                        MaterialLocalizations.of(context).backButtonTooltip,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
              )
            : null,
        title: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _buildAnimatedTopSearchRow(loc),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              image: DecorationImage(
                image:
                    AssetImage('assets/images/characters/tumugi_questions.png'),
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
          ),
          Padding(
            padding:
                EdgeInsets.only(top: topInset, bottom: questionListBottomInset),
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: ListView(
                padding: EdgeInsets.zero,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 30, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (isTrial) ...[
                          Text(
                            loc.todaysSpecialTitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: freePreviewTitleSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            loc.freePreviewSubtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.78),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ] else ...[
                          Text(
                            _sceneLabel(widget.selectedScene, loc),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: freePreviewTitleSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (QuizModeToggleConfig.showInQuestionList)
                    ModeToggleBar(
                      value: _mode,
                      onChanged: (m) => setState(() => _mode = m),
                      compact: true,
                    ),

                  // ▼▼ ここから フィルタ ▼▼
                  const SizedBox(height: 12),
                  if (_buildAnimatedCompactFilterHint(loc) != null)
                    _buildAnimatedCompactFilterHint(loc)!,
                  const SizedBox(height: 8),
                  // ▲▲ ここまで フィルタ ▲▲
                  const SizedBox(height: 16),

                  Transform.translate(
                    offset: const Offset(0, -50),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                      child: Column(
                        children: _filtered.asMap().entries.map((entry) {
                          final idxFiltered = entry.key;
                          final q = entry.value;

                          final originalIndex =
                              questions.indexWhere((qq) => qq.id == q.id);
                          final idx =
                              originalIndex == -1 ? idxFiltered : originalIndex;

                          final questionId = q.id;
                          final text = q.getText(nativeLang);
                          final done = _clearedSet.contains(questionId);

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Column(
                              children: [
                                Align(
                                  alignment: Alignment.center,
                                  child: FractionallySizedBox(
                                    widthFactor: 0.75,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () {
                                        if (locked) {
                                          final loc =
                                              AppLocalizations.of(context)!;
                                          _showSubscriptionUpsellDialog(loc);
                                          return;
                                        }
                                        _onQuestionTap(q, idx);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12, horizontal: 8),
                                        child: Row(
                                          children: [
                                            const Text(
                                              '▶',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                text,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 17.6,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            if (done)
                                              const Padding(
                                                padding:
                                                    EdgeInsets.only(left: 6),
                                                child: Icon(
                                                  Icons.task_alt_rounded,
                                                  size: 20,
                                                  color: Colors.white,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (hasScrollableQuestions)
            Positioned(
              left: 0,
              right: 0,
              bottom: scrollHintBottom,
              child: IgnorePointer(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: 240,
                    height: 26,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x00FFFFFF), Color(0x99FFFFFF)],
                      ),
                    ),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.white,
                        size: 16,
                        shadows: [
                          Shadow(
                            color: Color(0xAA000000),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
