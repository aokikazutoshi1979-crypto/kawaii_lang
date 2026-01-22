import 'package:flutter/material.dart';
import 'package:kawaii_lang/l10n/app_localizations.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localization.privacyPolicy),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(
            localization.privacyPolicyContent,
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
