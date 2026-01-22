import 'package:flutter/material.dart';

class ResetArrowButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ResetArrowButton({required this.onPressed, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: const Icon(Icons.refresh, size: 36, color: Colors.orange),
      tooltip: 'やり直す',
    );
  }
}
