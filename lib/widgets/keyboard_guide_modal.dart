import 'package:flutter/material.dart';
import 'package:kawaii_lang/l10n/app_localizations.dart';

class KeyboardGuideModal {
  static void show(BuildContext context, {required String language}) {
    final loc = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(loc.keyboardGuideTitle),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                Text(
                  loc.keyboardGuideBody.replaceAll("〇〇", language),
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(loc.ok),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
