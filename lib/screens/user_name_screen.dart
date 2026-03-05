import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kawaii_lang/l10n/app_localizations.dart';
import 'category_selection_screen.dart';
import 'level_selection_screen.dart';

class UserNameScreen extends StatefulWidget {
  const UserNameScreen({
    Key? key,
    this.isOnboarding = true,
    this.initialName,
  }) : super(key: key);

  final bool isOnboarding;
  final String? initialName;

  @override
  State<UserNameScreen> createState() => _UserNameScreenState();
}

class _UserNameScreenState extends State<UserNameScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialName ?? '';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_display_name', name);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await user.updateDisplayName(name);
      } catch (_) {}
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(
            {
              'displayName': name,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
    }

    if (!mounted) return;
    if (widget.isOnboarding) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LevelSelectionScreen()),
      );
    } else {
      Navigator.pop(context, name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final buttonLabel = widget.isOnboarding
        ? loc.userNameContinue
        : loc.userNameSave;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.userNameTitle),
        automaticallyImplyLeading: !widget.isOnboarding,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.userNameIntro,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLength: 20,
              decoration: InputDecoration(
                hintText: loc.userNameHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveName,
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(buttonLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
