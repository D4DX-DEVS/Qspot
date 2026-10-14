import 'package:flutter/material.dart';

import '../../../themes/app_colors.dart';
import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';

/// Shown when Submit could not reach the server. Reassures the student that
/// their answers are safe on the phone and lets them try again or leave.
class QuizSubmitFailedDialog extends StatelessWidget {
  const QuizSubmitFailedDialog({super.key, required this.palette});

  final HomePalette palette;

  /// Resolves to true for "Try Again", false for "Later" (or the back button).
  static Future<bool> show(BuildContext context) async {
    final palette = HomePalette.of(context);
    final retry = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => QuizSubmitFailedDialog(palette: palette),
    );
    return retry ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return AlertDialog(
      backgroundColor: p.card,
      title: Text(
        "Couldn't Submit Yet",
        style: AppFonts.bold(color: p.text, fontSize: 18),
      ),
      content: Text(
        'Your answers are saved on this phone, so nothing is lost.\n\n'
        'Check your connection and try again. If you leave now, they will be '
        'sent automatically the next time you open Quiz with a connection.',
        style: AppFonts.regular(color: p.textMuted, fontSize: 14, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Later', style: AppFonts.medium(color: p.textMuted)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: p.brand,
            foregroundColor: AppColors.white,
          ),
          child: const Text('Try Again'),
        ),
      ],
    );
  }
}
