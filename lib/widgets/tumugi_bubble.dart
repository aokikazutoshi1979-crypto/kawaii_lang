import 'package:flutter/material.dart';

class TumugiBubble extends StatefulWidget {
  const TumugiBubble({
    Key? key,
    required this.text,
    this.avatarPath,
  }) : super(key: key);

  final String text;
  final String? avatarPath;

  @override
  State<TumugiBubble> createState() => _TumugiBubbleState();
}

class _TumugiBubbleState extends State<TumugiBubble> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bubbleColor = isDark
        ? scheme.surface.withOpacity(0.92)
        : const Color(0xFFFFF4F7).withOpacity(0.96);
    final borderColor = scheme.primary.withOpacity(isDark ? 0.35 : 0.28);

    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 21,
          backgroundColor: Colors.white,
          foregroundImage: widget.avatarPath != null
              ? AssetImage(widget.avatarPath!)
              : null,
        ),
        const SizedBox(width: 10),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.74,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.08 : 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              widget.text,
              style: const TextStyle(fontSize: 16, height: 1.4),
            ),
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        offset: _visible ? Offset.zero : const Offset(0, 0.08),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          opacity: _visible ? 1.0 : 0.0,
          child: content,
        ),
      ),
    );
  }
}
