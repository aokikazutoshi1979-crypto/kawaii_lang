import 'dart:math';
import 'package:flutter/material.dart';

class WaveAnimation extends StatefulWidget {
  final bool isListening;

  const WaveAnimation({required this.isListening, Key? key}) : super(key: key);

  @override
  _WaveAnimationState createState() => _WaveAnimationState();
}

class _WaveAnimationState extends State<WaveAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isListening) return const SizedBox.shrink();

    return SizedBox(
      height: 40, // ← 小さめに変更
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final scale = 1.0 + sin(_controller.value * pi * 2) * 0.3;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              return Container(
                width: 4, // ← 幅も小さめ
                height: 12 + scale * 12 * (1 - (i - 2).abs() * 0.2), // ← 高さも小さめ
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: Colors.pinkAccent,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
