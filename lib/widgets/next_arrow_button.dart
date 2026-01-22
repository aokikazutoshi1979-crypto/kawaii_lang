import 'package:flutter/material.dart';

class NextArrowButton extends StatelessWidget {
  final VoidCallback onPressed;

  const NextArrowButton({required this.onPressed, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: const Icon(Icons.arrow_forward, size: 36, color: Colors.green),
      tooltip: '次へ',
    );
  }
}
