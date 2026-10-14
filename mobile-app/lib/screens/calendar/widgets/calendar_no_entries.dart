import 'package:flutter/material.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';

/// Short note under the filters when nothing matches them, with an optional
/// link to get back to everything.
class CalendarNoEntries extends StatelessWidget {
  const CalendarNoEntries({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppFonts.bold(color: palette.text, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppFonts.regular(
              color: palette.textMuted,
              fontSize: 13.5,
              height: 1.4,
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: AppFonts.semiBold(color: palette.brand, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}
