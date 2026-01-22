import 'package:flutter/material.dart';
import 'mic_button.dart';
import 'reset_arrow_button.dart';
import 'next_arrow_button.dart';

class MicArea extends StatelessWidget {
  final bool isListening;
  final bool isKeyboardMode;
  final bool hasInput;
  final bool hasSubmitted;

  final TextEditingController controller;
  final VoidCallback onMicTap;
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
    required this.controller,
    required this.onMicTap,
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
            Row(
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
