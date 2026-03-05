import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/character_asset_service.dart';
import 'category_selection_screen.dart';
import 'daily_practice_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCharacter = CharacterAssetService.defaultCharacter;
  int _streakDays = 0;
  String _nativeCode = 'ja';

  static const _streakDaysKey = 'streak_days';
  static const _streakDateKey = 'streak_last_date';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final character = await CharacterAssetService.loadSelectedCharacter();
    final today = _todayStr();
    final lastDate = prefs.getString(_streakDateKey) ?? '';
    int streak = prefs.getInt(_streakDaysKey) ?? 0;

    // ストリーク計算（アプリを開いた日に更新）
    if (lastDate == today) {
      // 今日既にカウント済み
    } else if (_isYesterday(lastDate, today)) {
      // 昨日練習していた → 連続を維持、今日もカウント
      streak += 1;
      await prefs.setInt(_streakDaysKey, streak);
      await prefs.setString(_streakDateKey, today);
    } else if (lastDate.isEmpty) {
      // 初回
      streak = 1;
      await prefs.setInt(_streakDaysKey, streak);
      await prefs.setString(_streakDateKey, today);
    } else {
      // 2日以上空いた → リセット
      streak = 1;
      await prefs.setInt(_streakDaysKey, streak);
      await prefs.setString(_streakDateKey, today);
    }

    final lang = prefs.getString('user_language') ?? 'en';
    if (!mounted) return;
    setState(() {
      _selectedCharacter = character;
      _streakDays = streak;
      _nativeCode = lang;
    });
  }

  String _todayStr() =>
      DateTime.now().toLocal().toString().substring(0, 10);

  bool _isYesterday(String dateStr, String todayStr) {
    try {
      final d = DateTime.parse(dateStr);
      final today = DateTime.parse(todayStr);
      return today.difference(d).inDays == 1;
    } catch (_) {
      return false;
    }
  }

  bool get _isJa => _nativeCode == 'ja';

  List<Map<String, dynamic>> _getMissions() {
    final dayIndex = DateTime.now().weekday % 3;
    if (_isJa) {
      return [
        {
          'icon': '🗣️',
          'title': '今日の練習',
          'subtitle': dayIndex == 0
              ? '駅で道を聞こう（3問）'
              : dayIndex == 1
                  ? 'レストランで注文しよう（3問）'
                  : 'ショッピングで話そう（3問）',
          'color': const Color(0xFFFCE4EC),
        },
        {
          'icon': '📚',
          'title': 'カテゴリー練習',
          'subtitle': 'テーマ別にスピーキング＆リスニング',
          'color': const Color(0xFFE8F5E9),
        },
        {
          'icon': '✨',
          'title': '自由会話',
          'subtitle': _isJa
              ? (_selectedCharacter == 'kasumi'
                  ? 'かすみと話してみよう'
                  : 'つむぎと話してみよう')
              : (_selectedCharacter == 'kasumi'
                  ? 'Chat with Kasumi'
                  : 'Chat with Tsumugi'),
          'color': const Color(0xFFF3E5F5),
        },
      ];
    } else {
      return [
        {
          'icon': '🗣️',
          'title': "Today's Practice",
          'subtitle': dayIndex == 0
              ? 'Ask for directions at the station (3 questions)'
              : dayIndex == 1
                  ? 'Order at a restaurant (3 questions)'
                  : 'Shop and talk (3 questions)',
          'color': const Color(0xFFFCE4EC),
        },
        {
          'icon': '📚',
          'title': 'Category Practice',
          'subtitle': 'Speaking & Listening by topic',
          'color': const Color(0xFFE8F5E9),
        },
        {
          'icon': '✨',
          'title': 'Free Chat',
          'subtitle': _selectedCharacter == 'kasumi'
              ? 'Chat with Kasumi'
              : 'Chat with Tsumugi',
          'color': const Color(0xFFF3E5F5),
        },
      ];
    }
  }

  void _goToDailyPractice() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DailyPracticeScreen()),
    ).then((_) {
      _loadPrefs();
    });
  }

  void _goToPractice() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CategorySelectionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final missions = _getMissions();
    final charAvatar = CharacterAssetService.chatAvatar(_selectedCharacter);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // キャラクター挨拶
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundImage: AssetImage(charAvatar),
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.pink.shade200.withOpacity(0.6)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        _isJa
                            ? '今日も一緒に練習しよう！☺️'
                            : "Let's practice together today! ☺️",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ストリーク表示
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade300, Colors.deepOrange.shade300],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_streakDays${_isJa ? '日' : ' day'}${(!_isJa && _streakDays != 1) ? 's' : ''}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          _isJa ? '連続練習中！' : 'streak!',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ミッションタイトル
              Text(
                _isJa ? '今日のミッション' : "Today's Missions",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),

              const SizedBox(height: 12),

              // ミッションカード3枚
              ...missions.asMap().entries.map((entry) {
                final index = entry.key;
                final m = entry.value;
                return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: index == 0 ? _goToDailyPractice : _goToPractice,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: m['color'] as Color,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Text(m['icon'] as String,
                                style: const TextStyle(fontSize: 24)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m['title'] as String,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    m['subtitle'] as String,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios_rounded,
                                size: 16, color: Colors.grey.shade500),
                          ],
                        ),
                      ),
                    ),
                  );
              }),

              const SizedBox(height: 24),

              // 始めるボタン
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _goToPractice,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink.shade400,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 3,
                  ),
                  child: Text(
                    _isJa ? '練習を始める' : 'Start Practice',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
