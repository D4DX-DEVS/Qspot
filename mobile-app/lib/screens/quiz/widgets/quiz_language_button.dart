import 'package:flutter/material.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';

/// Pill button for one language choice in the quiz language dialog.
class QuizLanguageButton extends StatelessWidget {
  const QuizLanguageButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = HomePalette.of(context);
    return SizedBox(
      height: 50,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: p.brand,
          foregroundColor: p.card,
          shape: const StadiumBorder(),
        ),
        child: Text(label, style: AppFonts.semiBold(fontSize: 15)),
      ),
    );
  }
}
