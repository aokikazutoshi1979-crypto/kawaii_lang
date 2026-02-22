import 'dart:math' as math;
import 'package:flutter/material.dart';

/// タップ位置からパーティクルが放射状に飛び散るオーバーレイウィジェット。
/// IgnorePointer で包んでいるため、アニメーション中もタップを貫通させる。
class ParticleBurst extends StatefulWidget {
  final Offset center;
  final VoidCallback onDone;
  const ParticleBurst({super.key, required this.center, required this.onDone});

  @override
  State<ParticleBurst> createState() => _ParticleBurstState();
}

class _ParticleBurstState extends State<ParticleBurst>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;
  static final _rng = math.Random();

  static const _icons = ['★', '✦', '◆', '✿', '❋', '⬟'];
  static const _colors = [
    Color(0xFFFF69B4),
    Color(0xFFFFD700),
    Color(0xFF87CEEB),
    Color(0xFFFF85C2),
    Color(0xFFB39DDB),
    Color(0xFF80DEEA),
  ];

  @override
  void initState() {
    super.initState();
    _particles = List.generate(14, (_) {
      final angle = _rng.nextDouble() * 2 * math.pi;
      final speed = 60.0 + _rng.nextDouble() * 90.0;
      return _Particle(
        dx: math.cos(angle) * speed,
        dy: math.sin(angle) * speed,
        color: _colors[_rng.nextInt(_colors.length)],
        label: _icons[_rng.nextInt(_icons.length)],
        size: 12.0 + _rng.nextDouble() * 10.0,
      );
    });
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward().whenComplete(() {
        if (mounted) widget.onDone();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          final t = _controller.value;
          final fade = (1.0 - t).clamp(0.0, 1.0);
          return Stack(
            children: _particles.map((p) {
              final x = widget.center.dx + p.dx * t - p.size / 2;
              final y = widget.center.dy + p.dy * t - p.size / 2;
              return Positioned(
                left: x,
                top: y,
                child: Opacity(
                  opacity: fade,
                  child: Text(
                    p.label,
                    style: TextStyle(
                      fontSize: p.size,
                      color: p.color,
                      shadows: [
                        Shadow(
                          color: p.color.withOpacity(0.6),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _Particle {
  final double dx, dy, size;
  final Color color;
  final String label;
  const _Particle({
    required this.dx,
    required this.dy,
    required this.color,
    required this.label,
    required this.size,
  });
}
