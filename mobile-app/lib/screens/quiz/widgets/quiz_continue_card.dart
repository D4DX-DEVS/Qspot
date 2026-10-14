import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/common/soft_icon_tile.dart';
import '../../../widgets/common/surface_card.dart';
import '../../../widgets/common/tinted_pill_link.dart';

/// A quiz the student started on this phone and can carry on with: title,
/// how many questions are answered, and a "Continue" action.
class QuizContinueCard extends StatelessWidget {
  const QuizContinueCard({
    super.key,
    required this.title,
    required this.answered,
    required this.total,
    required this.onTap,
  });

  final String title;
  final int answered;
  final int total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = HomePalette.of(context);
    final progress = 'In progress · $answered of $total answered';
    return Semantics(
      button: true,
      label: '$title. $progress. Continue',
      excludeSemantics: true,
      child: SurfaceCard(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            SoftIconTile(icon: LucideIcons.pencilLine, tone: p.mint, size: 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.isEmpty ? 'Your quiz' : title,
                    style: AppFonts.bold(color: p.text, fontSize: 15.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    progress,
                    style: AppFonts.regular(color: p.textMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TintedPillLink(label: 'Continue', tone: p.mint),
          ],
        ),
      ),
    );
  }
}
