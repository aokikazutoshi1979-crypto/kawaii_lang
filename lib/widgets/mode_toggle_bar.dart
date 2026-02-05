import 'package:flutter/material.dart';
import 'package:kawaii_lang/models/quiz_mode.dart';

class ModeToggleBar extends StatelessWidget {
  final QuizMode value;
  final ValueChanged<QuizMode> onChanged;
  final EdgeInsetsGeometry? padding;
  final bool compact; // true:高さ控えめ

  // ★ 追加: ラベルを外部（ARB）から受け取る
  final String? readingLabel;
  final String? listeningLabel;

  const ModeToggleBar({
    super.key,
    required this.value,
    required this.onChanged,
    this.padding,
    this.compact = false,
    this.readingLabel,
    this.listeningLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isReading   = value == QuizMode.reading;
    final isListening = value == QuizMode.listening;

    final activeBorder = Colors.pink.shade300;
    final inactiveBorder = Colors.grey.shade300;

    final btnStyle = ElevatedButton.styleFrom(
      elevation: 0,
      padding: EdgeInsets.symmetric(
        vertical: compact ? 10 : 14,
        horizontal: 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: inactiveBorder,
          width: 2,
        ),
      ),
    );

    Widget buildBtn(String label, IconData icon, bool active, QuizMode mode) {
      return Expanded(
        child: ElevatedButton.icon(
          icon: Icon(icon),
          label: Text(label),
          style: btnStyle.copyWith(
            // Flutter のバージョンによっては MaterialStateProperty を使ってください
            backgroundColor: WidgetStateProperty.resolveWith(
              (_) => Colors.white,
            ),
            foregroundColor: WidgetStateProperty.resolveWith(
              (_) => Colors.black87,
            ),
            side: WidgetStateProperty.resolveWith(
              (_) => BorderSide(
                color: active ? activeBorder : inactiveBorder,
                width: 2,
              ),
            ),
          ),
          onPressed: () => onChanged(mode),
        ),
      );
    }

    // ★ 渡されなかった場合のフォールバック（英語）
    final rLabel = readingLabel   ?? 'Reading';
    final lLabel = listeningLabel ?? 'Listening';

    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          buildBtn(rLabel, Icons.menu_book_rounded, isReading, QuizMode.reading),
          const SizedBox(width: 8),
          buildBtn(lLabel, Icons.hearing_rounded, isListening, QuizMode.listening),
        ],
      ),
    );
  }
}
