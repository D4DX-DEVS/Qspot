import 'package:flutter/material.dart';

import '../../../themes/app_colors.dart';
import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';

/// Explains the "quiz closes soon" reminder before the phone asks for
/// notification permission. Resolves to true for "Allow".
class QuizReminderPermissionDialog extends StatelessWidget {
  const QuizReminderPermissionDialog({super.key, required this.palette});

  final HomePalette palette;

  static Future<bool> show(BuildContext context) async {
    final palette = HomePalette.of(context);
    final allow = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => QuizReminderPermissionDialog(palette: palette),
    );
    return allow ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return AlertDialog(
      backgroundColor: p.card,
      title: Text(
        'Quiz Reminders',
        style: AppFonts.bold(color: p.text, fontSize: 18),
      ),
      content: Text(
        "Get a reminder 5 minutes before a quiz you've started closes, so you "
        "don't miss submitting it. You can change this later in Settings.",
        style: AppFonts.regular(color: p.textMuted, fontSize: 14, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Not Now', style: AppFonts.medium(color: p.textMuted)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: p.brand,
            foregroundColor: AppColors.white,
          ),
          child: const Text('Allow'),
        ),
      ],
    );
  }
}
