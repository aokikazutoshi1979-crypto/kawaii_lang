import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:kawaii_lang/l10n/app_localizations.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  String _email = '';
  String _password = '';
  bool _isLoading = false;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _error = null; });
    final cred = await _authService.upgradeAnonymousToEmail(_email, _password);
    if (cred != null) {
      Navigator.pushReplacementNamed(context, '/category');
    } else {
      setState(() { _error = AppLocalizations.of(context)!.registerFailed; });
    }
    setState(() { _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(loc.registerAccount)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: InputDecoration(labelText: loc.email),
                    onChanged: (v) => _email = v,
                    validator: (v) => v != null && v.contains('@')
                        ? null
                        : loc.invalidEmail,
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
                          child: Text(loc.register),
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
