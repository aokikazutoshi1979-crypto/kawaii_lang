import 'package:flutter/material.dart';

class UserInputPreview extends StatelessWidget {
  final String text;

  const UserInputPreview({required this.text, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            // 吹き出し本体
            FractionallySizedBox(
              widthFactor: 0.9,
              child: Container(
                padding: const EdgeInsets.all(12),
                height: 120, // ← 3〜4行表示できる想定
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 14,
                      spreadRadius: 2,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                alignment: Alignment.topLeft,
                child: Text(
                  text.isNotEmpty ? text : '',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),

            // ▼（中央下に白色で表示）
            Positioned.fill(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Transform.translate(
                  offset: const Offset(0, 14),
                  child: const Icon(
                    Icons.arrow_drop_down,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
