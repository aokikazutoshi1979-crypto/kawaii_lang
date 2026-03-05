// lib/screens/auth_gate.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/subscription_service.dart';
import 'splash_screen.dart';
import 'login_screen.dart';
import 'language_selection_screen.dart';
import 'target_language_selection_screen.dart';
import 'home_screen.dart';
import 'level_selection_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final subService = SubscriptionService.instance;
  bool initialized = false;

  @override
  void initState() {
    super.initState();
    _initSubscription();
  }

  Future<void> _initSubscription() async {
    try {
      await subService.init();
      debugPrint('✅ SubscriptionService initialized');
    } catch (e) {
      debugPrint('❌ SubscriptionService failed: $e');
    }
    setState(() => initialized = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!initialized) {
      return SplashScreen();
    }
    return StreamBuilder<User?>(
      stream: AuthService().authState,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SplashScreen();
        }
        final user = snapshot.data;
        if (user == null) {
          return LoginScreen();
        }
        return FutureBuilder<SharedPreferences>(
          future: SharedPreferences.getInstance(),
          builder: (context, prefsSnap) {
            if (prefsSnap.connectionState != ConnectionState.done) {
              return SplashScreen();
            }
            final prefs = prefsSnap.data;
            if (prefs == null) return SplashScreen();
            final native = prefs.getString('user_language');
            final target = prefs.getString('target_language');
            if (native == null) {
              return LanguageSelectionScreen();
            }
            if (target == null) {
              return const TargetLanguageSelectionScreen();
            }
            final level = prefs.getString('user_level');
            if (level == null) {
              return const LevelSelectionScreen();
            }
            return const HomeScreen();
          },
        );
      },
    );
  }
}
