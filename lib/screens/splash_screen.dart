import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../services/auth_service.dart';
import '../services/idle_service.dart';
import 'category_selection_screen.dart';
import 'user_name_screen.dart';
import 'package:kawaii_lang/config.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const Set<String> _supportedUserLangCodes = {
    'ja',
    'en',
    'zh',
    'zh_TW',
    'ko',
    'es',
    'fr',
    'de',
    'vi',
    'id',
  };

  String _detectDeviceLanguageCode() {
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    if (locale.languageCode == 'zh' &&
        locale.countryCode?.toUpperCase() == 'TW') {
      return 'zh_TW';
    }
    if (_supportedUserLangCodes.contains(locale.languageCode)) {
      return locale.languageCode;
    }
    return 'en';
  }

  void _startPostNavigationInit() {
    Future<void>.delayed(const Duration(milliseconds: 100), () async {
      try {
        Purchases.setDebugLogsEnabled(true);
        await Purchases.configure(
          PurchasesConfiguration('appl_dEZMvMgsqmnwhWGCcICYJlBjgwe'),
        );
        await IdleService.ensureInitialized();
      } catch (e) {
        debugPrint('⚠️ Post-navigation init ignored: $e');
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // アプリ初期化と画面遷移を開始
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // 1) 匿名ログイン＆セッション更新





      // ① 匿名サインイン＋Firestore 書き込み
      await AuthService.signInAnonymouslyIfNeeded(force: isTestReset);

      // 2) 次画面の背景を先読みして遷移時の引っかかりを軽減
      final dpr = MediaQuery.of(context).devicePixelRatio;
      final w = (MediaQuery.of(context).size.width * dpr).round();
      await precacheImage(
        ResizeImage(
          const AssetImage('assets/images/characters/tumugi_menu.png'),
          width: w,
        ),
        context,
      );

      // 3) 最低表示時間を確保
      await Future.delayed(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('⚠️ スプラッシュ初期化で例外を無視: $e');
    }
    if (!mounted) return;

    // 5) 次の画面へ
    final prefs = await SharedPreferences.getInstance();
    var savedLang = prefs.getString('user_language');
    var savedTarget = prefs.getString('target_language');
    final savedName = prefs.getString('user_display_name')?.trim();

    if (savedLang == null) {
      savedLang = _detectDeviceLanguageCode();
      await prefs.setString('user_language', savedLang);
    }

    if (savedTarget == null) {
      savedTarget = (savedLang == 'ja') ? 'en' : 'ja';
      await prefs.setString('target_language', savedTarget);
    }

    if (savedName == null || savedName.isEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const UserNameScreen(isOnboarding: true),
        ),
      );
      _startPostNavigationInit();
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CategorySelectionScreen(),
        ),
      );
      _startPostNavigationInit();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/images/characters/tumugi_splash.png',
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
