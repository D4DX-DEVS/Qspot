import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/common/tinted_pill_link.dart';

/// Tells the student their answers were not accepted and why, with OK to
/// dismiss the notice and, when the quiz can be taken again, a button for it.
class QuizRefusedBanner extends StatelessWidget {
  const QuizRefusedBanner({
    super.key,
    required this.message,
    required this.onDismiss,
    this.onReopen,
  });

  final String message;
  final VoidCallback onDismiss;

  /// Shown as "Open Quiz Again" when set.
  final VoidCallback? onReopen;

  @override
  Widget build(BuildContext context) {
    final p = HomePalette.of(context);
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: p.coral.soft,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.circleAlert, color: p.coral.color, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: AppFonts.regular(
                      color: p.text,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  if (onReopen != null)
                    TintedPillLink(
                      label: 'Open Quiz Again',
                      tone: p.mint,
                      onTap: onReopen,
                    ),
                  TintedPillLink(label: 'OK', tone: p.coral, onTap: onDismiss),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
