import 'package:flutter/material.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import 'quiz_language_button.dart';

/// Asks which language to take a quiz in. Pops `'en'` or `'ml'`.
class QuizLanguageDialog extends StatelessWidget {
  const QuizLanguageDialog({super.key});

  /// Shows the dialog; null when it is closed without a choice.
  static Future<String?> show(BuildContext context) => showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const QuizLanguageDialog(),
  );

  @override
  Widget build(BuildContext context) {
    final p = HomePalette.of(context);
    return Dialog(
      backgroundColor: p.card,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: p.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select quiz language',
              style: AppFonts.bold(color: p.text, fontSize: 19),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'This cannot be changed once the quiz starts.',
              style: AppFonts.regular(color: p.textMuted, fontSize: 13.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: QuizLanguageButton(
                    label: 'English',
                    onTap: () => Navigator.pop(context, 'en'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: QuizLanguageButton(
                    label: 'മലയാളം',
                    onTap: () => Navigator.pop(context, 'ml'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
