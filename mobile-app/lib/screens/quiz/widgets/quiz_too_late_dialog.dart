import 'package:flutter/material.dart';

import '../../../themes/app_colors.dart';
import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';

/// Tells the student their answers reached the server after the quiz closed,
/// so they could not be marked.
class QuizTooLateDialog extends StatelessWidget {
  const QuizTooLateDialog({super.key, required this.palette, this.endsAt});

  final HomePalette palette;

  /// The quiz's end time, shown in the message when known.
  final DateTime? endsAt;

  static Future<void> show(BuildContext context, {DateTime? endsAt}) {
    final palette = HomePalette.of(context);
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => QuizTooLateDialog(palette: palette, endsAt: endsAt),
    );
  }

  /// The explanation, with the closing time when known.
  static String message(BuildContext context, DateTime? endsAt) {
    final closed = endsAt == null
        ? 'This quiz has closed'
        : 'This quiz closed at '
              '${TimeOfDay.fromDateTime(endsAt.toLocal()).format(context)}';
    return '$closed, and your answers reached us after that, so they could '
        'not be marked. Please speak to your teacher.';
  }

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return AlertDialog(
      backgroundColor: p.card,
      title: Text(
        'Submitted Too Late',
        style: AppFonts.bold(color: p.text, fontSize: 18),
      ),
      content: Text(
        message(context, endsAt),
        style: AppFonts.regular(color: p.textMuted, fontSize: 14, height: 1.5),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: p.brand,
            foregroundColor: AppColors.white,
          ),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
