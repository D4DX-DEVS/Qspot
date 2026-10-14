import 'package:flutter/material.dart';

import '../../../themes/home_palette.dart';

/// Bottom bar with one button that carries on with the next lesson.
class CourseContinueBar extends StatelessWidget {
  const CourseContinueBar({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.card,
        border: Border(top: BorderSide(color: palette.cardBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: palette.brand,
                foregroundColor: palette.card,
                minimumSize: const Size(0, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: onPressed,
              child: Text(label),
            ),
          ),
        ),
      ),
    );
  }
}
