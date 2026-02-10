import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'mic_button.dart';
import 'reset_arrow_button.dart';
import 'next_arrow_button.dart';

class MicArea extends StatelessWidget {
  final bool isListening;
  final bool isKeyboardMode;
  final bool hasInput;
  final bool hasSubmitted;
  final List<double> waveformSamples;

  final TextEditingController controller;
  final VoidCallback onMicTap;
  final VoidCallback onRecordCancel;
  final VoidCallback onRecordConfirm;
  final VoidCallback onKeyboardTap;
  final VoidCallback onSend;
  final VoidCallback onCancel;
  final VoidCallback onReset;
  final VoidCallback onNext;
  final ValueChanged<String> onTextChanged;
  final FocusNode? focusNode;
  final VoidCallback? onDone;

  const MicArea({
    Key? key,
    required this.isListening,
    required this.isKeyboardMode,
    required this.hasInput,
    required this.hasSubmitted,
    required this.waveformSamples,
    required this.controller,
    required this.onMicTap,
    required this.onRecordCancel,
    required this.onRecordConfirm,
    required this.onKeyboardTap,
    required this.onSend,
    required this.onCancel,
    required this.onReset,
    required this.onNext,
    required this.onTextChanged,
    this.focusNode,
    this.onDone,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final showTextField = !hasSubmitted && (isKeyboardMode || hasInput);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showTextField) ...[
            EditableUserInput(
              controller: controller,
              onChanged: onTextChanged,
              focusNode: focusNode,
              onDone: () {
                if (controller.text.trim().isEmpty) {
                  onCancel();
                } else {
                  onDone?.call();
                }
              },
            ),
            const SizedBox(height: 12),
          ],

          if (!hasSubmitted)
            isListening
                ? _RecordingBar(
                    samples: waveformSamples,
                    onCancel: onRecordCancel,
                    onConfirm: onRecordConfirm,
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (hasInput)
                        IconButton(
                          icon: const Icon(Icons.cancel),
                          onPressed: onCancel,
                        ),
                      const SizedBox(width: 8),

                      if (!isKeyboardMode)
                        MicButton(
                          isListening: isListening,
                          onTap: onMicTap,
                        ),
                      const SizedBox(width: 8),

                      if (!isListening && !isKeyboardMode)
                        GestureDetector(
                          onTap: onKeyboardTap,
                          child: Container(
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
                            child: const Center(
                              child: Icon(
                                Icons.keyboard,
                                size: 40,
                                color: Colors.pinkAccent,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),

                      if (hasInput)
                        ElevatedButton(
                          onPressed: onSend,
                          style: ElevatedButton.styleFrom(
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(12),
                            foregroundColor: Colors.green, // ← ✅ アイコンの色をここで指定！
                          ),
                          child: const Icon(Icons.send), // ← これは const でもOK！
                        ),
                    ],
                  ),

          if (hasSubmitted)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ResetArrowButton(onPressed: onReset),
                const SizedBox(width: 16),
                NextArrowButton(onPressed: onNext),
              ],
            ),
        ],
      ),
    );
  }
}

class EditableUserInput extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final FocusNode? focusNode;
  final VoidCallback? onDone;

  const EditableUserInput({
    Key? key,
    required this.controller,
    required this.onChanged,
    this.focusNode,
    this.onDone,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        maxLines: null,
        textInputAction: TextInputAction.done,
        onEditingComplete: () {
          onDone?.call();
          FocusScope.of(context).unfocus();
        },
        style: const TextStyle(fontSize: 16),
        decoration: const InputDecoration.collapsed(hintText: ''),
      ),
    );
  }
}

class _RecordingBar extends StatelessWidget {
  final List<double> samples;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const _RecordingBar({
    required this.samples,
    required this.onCancel,
    required this.onConfirm,
  });

  static const Color _brandPink = Color(0xFFE91E63);
  static const double _buttonSize = 46;
  static const double _plateHeight = 48;
  static const double _plateWidth = 240;
  static const double _plateRadius = 22;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _CircleIconButton(
          icon: Icons.close,
          onTap: onCancel,
          color: Colors.white.withOpacity(0.9),
          iconColor: Colors.grey.shade700,
          borderColor: _brandPink.withOpacity(0.25),
        ),
        const SizedBox(width: 8),
        Container(
          width: _plateWidth,
          height: _plateHeight,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _brandPink.withOpacity(0.14),
            borderRadius: BorderRadius.circular(_plateRadius),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.08),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: CustomPaint(
            painter: _WaveformPainter(
              samples: samples,
              color: const Color(0xFFFFF1F5),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _CircleIconButton(
          icon: Icons.check,
          onTap: onConfirm,
          color: _brandPink,
          iconColor: Colors.white,
          borderColor: _brandPink.withOpacity(0.4),
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final Color iconColor;
  final Color borderColor;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    required this.color,
    required this.iconColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: _RecordingBar._buttonSize,
        height: _RecordingBar._buttonSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(color: borderColor),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> samples;
  final Color color;
  const _WaveformPainter({required this.samples, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const barCount = 96;
    const gap = 1.2;
    final totalGap = gap * (barCount - 1);
    final barWidth = (size.width - totalGap) / barCount;
    if (barWidth <= 0) return;

    final paint = Paint()..color = color;
    final values = List<double>.filled(barCount, 0.0);
    if (samples.isNotEmpty) {
      final rawLen = samples.length;
      for (var i = 0; i < barCount; i++) {
        final t = (barCount == 1) ? 0.0 : i / (barCount - 1);
        final pos = (rawLen == 1) ? 0.0 : t * (rawLen - 1);
        final idx = pos.floor();
        final frac = pos - idx;
        final v0 = samples[idx].clamp(0.0, 1.0);
        final v1 = samples[math.min(idx + 1, rawLen - 1)].clamp(0.0, 1.0);
        final v = v0 + (v1 - v0) * frac;
        final edge = 0.4 + 0.6 * math.sin(math.pi * t);
        values[i] = (v * edge).clamp(0.0, 1.0);
      }
    }

    final centerY = size.height / 2;
    var x = 0.0;
    for (var i = 0; i < barCount; i++) {
      final v = values[i];
      final h = math.max(1.5, v * (size.height / 2));
      final rect = Rect.fromLTWH(x, centerY - h, barWidth, h * 2);
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(2));
      canvas.drawRRect(rrect, paint);
      x += barWidth + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.samples != samples;
  }
}
