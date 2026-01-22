import 'package:flutter/material.dart';

class SiriWaveAnimation extends StatefulWidget {
  final bool isListening;

  const SiriWaveAnimation({required this.isListening, Key? key}) : super(key: key);

  @override
  State<SiriWaveAnimation> createState() => _SiriWaveAnimationState();
}

class _SiriWaveAnimationState extends State<SiriWaveAnimation> with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();

    _controllers = List.generate(3, (i) {
      return AnimationController(
        vsync: this,
        duration: const Duration(seconds: 2),
      )..repeat(
          period: const Duration(milliseconds: 1500),
          reverse: false,
        );
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeOut,
      ));
    }).toList();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isListening) return const SizedBox.shrink();

    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _animations[i],
            builder: (_, __) {
              final scale = _animations[i].value;
              final opacity = 1.0 - scale;
              return Container(
                width: 80 * scale + 40,
                height: 80 * scale + 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.pinkAccent.withOpacity(opacity * 0.3),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
