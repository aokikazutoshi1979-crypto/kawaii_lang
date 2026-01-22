// lib/screens/auth_gate.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/subscription_service.dart';
import 'splash_screen.dart';
import 'login_screen.dart';
import 'language_selection_screen.dart';
import 'category_selection_screen.dart';

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
        return FutureBuilder<String?>(
          future: SharedPreferences.getInstance()
              .then((prefs) => prefs.getString('user_language')),
          builder: (context, langSnap) {
            if (langSnap.connectionState != ConnectionState.done) {
              return SplashScreen();
            }
            if (langSnap.data == null) {
              return LanguageSelectionScreen();
            }
            return CategorySelectionScreen();
          },
        );
      },
    );
  }
}
