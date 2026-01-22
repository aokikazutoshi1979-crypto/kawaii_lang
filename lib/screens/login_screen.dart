import 'package:flutter/material.dart';
import 'package:kawaii_lang/services/auth_service.dart';
import 'package:kawaii_lang/screens/reset_password_screen.dart';
import 'package:kawaii_lang/l10n/app_localizations.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:kawaii_lang/services/subscription_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  String _email = '';
  String _password = '';
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final cred = await _authService.loginWithEmail(_email, _password);
      if (cred != null) {
        // 1) RevenueCat から復元（必要なら）
        try {
          await SubscriptionService.instance.restorePurchases();
          await Purchases.restorePurchases();
        } catch (e) {
          debugPrint('⚠️ サブスク復元に失敗しました: $e');
        }

        // 2) 端末上の最新サブスク状態を取得
        final isActive =
            await SubscriptionService.instance.checkSubscriptionOnDevice();

        // 3) Firebase に保存（必要なら）
        await FirebaseFirestore.instance
            .collection('users')
            .doc(cred.user!.uid)
            .set({
              'hasSubscription': isActive,
              // ent.expirationDate が非 null なら書き込む例
              'expirationDate': isActive
                ? Timestamp.fromDate(DateTime.now().add(Duration(days:30)))
                : null,
            }, SetOptions(merge: true));

        // 4) 次画面へ
        Navigator.pushReplacementNamed(context, '/category');
      } else {
        setState(() => _errorMessage =
            AppLocalizations.of(context)!.loginFailed);
      }
    } catch (e) {
      setState(() => _errorMessage =
          '${AppLocalizations.of(context)!.loginError}: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _goToRegister() {
    Navigator.pushNamed(context, '/register');
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(loc.login)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 8),
            ],
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: InputDecoration(labelText: loc.email),
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (v) => _email = v,
                    validator: (v) =>
                        v != null && v.contains('@') ? null : loc.invalidEmail,
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: loc.password),
                    obscureText: true,
                    onChanged: (v) => _password = v,
                    validator: (v) => v != null && v.length >= 6
                        ? null
                        : loc.passwordTooShort,
                  ),
                  const SizedBox(height: 16),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _submit,
                          child: Text(loc.login),
                        ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _goToRegister,
                    child: Text(loc.noAccountRegister),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ResetPasswordScreen()),
                      );
                    },
                    child: Text(loc.resetPassword),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
