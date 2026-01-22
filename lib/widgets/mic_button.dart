import 'package:flutter/material.dart';
import 'siri_wave_animation.dart';
import 'wave_animation.dart';

class MicButton extends StatelessWidget {
  final bool isListening;
  final VoidCallback onTap;

  const MicButton({
    required this.isListening,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SiriWaveAnimation(isListening: isListening),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: isListening
                    ? WaveAnimation(isListening: true)
                    : const Icon(
                        Icons.mic_none,
                        size: 40,
                        color: Colors.pinkAccent,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
