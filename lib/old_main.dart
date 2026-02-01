import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kawaii_lang/l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/idle_service.dart';
import 'screens/auth_gate.dart';
import 'screens/login_screen.dart';
import 'screens/category_selection_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/idle_gate_screen.dart';
import 'services/subscription_service.dart';  // ← 追加
import 'screens/register_screen.dart'; // ← 追加
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:kawaii_lang/config.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'dart:ui'; // PlatformDispatcher を使う場合

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- Firebase 初期化 ---
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Crashlytics 収集を有効化（デバッグでも送る場合は true に）
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

  // Flutter 框組のエラー
  FlutterError.onError = (FlutterErrorDetails details) {
    FirebaseCrashlytics.instance.recordFlutterError(details);
  };

  // フレーム外（非同期）エラー
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true; // 既定のクラッシュを止める
  };

  // --- 先に必要な初期化（例：RevenueCat） ---
  // ※ ここは await して確実に完了させるのがクラッシュ防止のカギ
  try {
    await SubscriptionService.instance.init(); // ← RCのconfigureを内包
  } catch (e, st) {
    // 初期化失敗も Crashlytics に送っておく
    await FirebaseCrashlytics.instance.recordError(e, st, reason: 'RC init failed');
  }

  // ユーザー設定読み込み
  final prefs = await SharedPreferences.getInstance();
  final savedLang = prefs.getString('user_language');
  final initialLocale = savedLang != null
      ? Locale(savedLang)
      : PlatformDispatcher.instance.locale;

  // runApp は 1 回だけ、runZonedGuarded で包む
  runZonedGuarded(() {
    runApp(MyApp(initialLocale: initialLocale));
  }, (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack);
  });
}

class MyApp extends StatefulWidget {
  final Locale initialLocale;
  const MyApp({Key? key, required this.initialLocale}) : super(key: key);

  static void setLocale(BuildContext context, Locale newLocale) {
    final state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(newLocale);
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late Locale _locale;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _locale = widget.initialLocale;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      IdleService.saveExitTime();
    }
  }

  void setLocale(Locale newLocale) {
    setState(() {
      _locale = newLocale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Kawaii Lang',
      debugShowCheckedModeBanner: false,
      locale: _locale,
      supportedLocales: const [
        Locale('ja'),               // 日本語
        Locale('en'),               // 英語
        Locale('zh'),               // 中国語（簡体）
        Locale('zh', 'TW'),         // 中国語（繁体／台湾）
        Locale('ko'),               // 韓国語
        Locale('es'),               // スペイン語
        Locale('fr'),               // フランス語
        Locale('de'),               // ドイツ語
        Locale('vi'),               // ベトナム語
        Locale('id'),               // インドネシア語
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (deviceLocale, supportedLocales) {
        if (supportedLocales.contains(_locale)) return _locale;
        if (deviceLocale != null && supportedLocales.contains(Locale(deviceLocale.languageCode))) {
          return deviceLocale;
        }
        return const Locale('ja');
      },
      // home: IdleGateScreen(),
      home: SplashScreen(),
      routes: {
        '/idle': (_) => IdleGateScreen(),  // 必要に応じて名前を付けておく
        '/login': (_) => LoginScreen(),
        '/register': (_) => RegisterScreen(), // ← 追加済み
        '/category': (_) => CategorySelectionScreen(),
        '/settings': (_) => SettingsScreen(),
        '/splash': (_) => SplashScreen(),  // ← 追加
      },
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.pink,
      ),
    );
  }
}
