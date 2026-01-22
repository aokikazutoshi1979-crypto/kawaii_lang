import 'package:flutter/material.dart';

class SendCancelButtons extends StatelessWidget {
  final VoidCallback onSend;
  final VoidCallback onCancel;

  const SendCancelButtons({
    required this.onSend,
    required this.onCancel,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: onCancel,
          icon: const Icon(Icons.close),
          tooltip: 'キャンセル',
          color: Colors.black,
          iconSize: 28,
        ),
        const SizedBox(width: 24),
        IconButton(
          onPressed: onSend,
          icon: const Icon(Icons.send),
          tooltip: '送信',
          color: Colors.green,
          iconSize: 28,
        ),
      ],
    );
  }
}
