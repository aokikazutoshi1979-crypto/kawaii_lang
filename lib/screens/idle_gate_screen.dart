// lib/screens/idle_gate_screen.dart
import 'package:flutter/material.dart';
import 'package:kawaii_lang/services/idle_service.dart';
import 'package:kawaii_lang/screens/splash_screen.dart';
import 'package:kawaii_lang/screens/auth_gate.dart';

class IdleGateScreen extends StatefulWidget {
  const IdleGateScreen({Key? key}) : super(key: key);

  @override
  State<IdleGateScreen> createState() => _IdleGateScreenState();
}

class _IdleGateScreenState extends State<IdleGateScreen> with WidgetsBindingObserver {
  static const _idleLimitMinutes = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkIdleTime();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      IdleService.saveExitTime();
    }
  }

  Future<void> _checkIdleTime() async {
    final minutes = await IdleService.getIdleMinutes();
    // 初回起動または保存なしの場合もSplashへ
    if (minutes < 0 || minutes >= _idleLimitMinutes) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SplashScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthGate()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
