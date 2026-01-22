import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../services/auth_service.dart';
import '../services/idle_service.dart';
import 'language_selection_screen.dart';
import 'category_selection_screen.dart';
import 'package:kawaii_lang/config.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  int _dotIndex = 0;
  late List<String> _loadingDots;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    // ドットアニメーションの初期化
    _loadingDots = ['.', '..', '...'];
    _timer = Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) {
        if (!mounted) return;
        setState(() {
          _dotIndex = (_dotIndex + 1) % _loadingDots.length;
        });
      },
    );

    // アプリ初期化と画面遷移を開始
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // 1) 匿名ログイン＆セッション更新





      // ① 匿名サインイン＋Firestore 書き込み
      await AuthService.signInAnonymouslyIfNeeded(force: isTestReset);




      // 2) RevenueCat 設定
      Purchases.setDebugLogsEnabled(true);
      await Purchases.configure(
        PurchasesConfiguration('appl_dEZMvMgsqmnwhWGCcICYJlBjgwe'),
      );

      // 3) IdleService 初期化
      await IdleService.ensureInitialized();

      // 4) 最低表示時間を確保
      await Future.delayed(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('⚠️ スプラッシュ初期化で例外を無視: $e');
    }
    if (!mounted) return;

    // 5) 次の画面へ
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString('user_language');

    if (savedLang == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LanguageSelectionScreen(),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CategorySelectionScreen(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Image.asset(
              'assets/images/splash_logo.png',
              width: screenWidth * 0.9,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Your Kawaii Trainer is loading',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 4),
              Text(
                _loadingDots[_dotIndex],
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
