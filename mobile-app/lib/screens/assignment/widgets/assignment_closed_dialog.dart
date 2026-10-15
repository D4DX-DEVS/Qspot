import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../themes/app_colors.dart';
import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../../common/widgets/home_theme_scope.dart';

/// Tells the learner the deadline has passed and the work can no longer be
/// sent.
class AssignmentClosedDialog extends StatelessWidget {
  const AssignmentClosedDialog({super.key});

  static Future<void> show(BuildContext context) => showDialog<void>(
    context: context,
    builder: (_) => const HomeThemeScope(child: AssignmentClosedDialog()),
  );

  @override
  Widget build(BuildContext context) {
    final p = HomePalette.of(context);
    return AlertDialog(
      backgroundColor: p.card,
      icon: CircleAvatar(
        radius: 26,
        backgroundColor: p.coral.soft,
        child: Icon(LucideIcons.timerOff, color: p.coral.color, size: 26),
      ),
      title: Text(
        'Time Is Over',
        textAlign: TextAlign.center,
        style: AppFonts.bold(color: p.text, fontSize: 18),
      ),
      content: Text(
        'The time for this assignment is over, so you can no longer '
        'submit your answer.',
        textAlign: TextAlign.center,
        style: AppFonts.regular(color: p.textMuted, fontSize: 14, height: 1.5),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: p.brand,
            foregroundColor: AppColors.white,
            minimumSize: const Size(120, 44),
          ),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
