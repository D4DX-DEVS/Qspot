import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../themes/accent_tone.dart';
import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/common/soft_icon_tile.dart';
import '../../../widgets/common/surface_card.dart';
import '../../../widgets/common/tone_chip.dart';
import '../model/grade_entry.dart';
import '../model/grade_kind.dart';

/// One mark: what it was for, when, the score out of the total, and a
/// coloured percentage. An assignment also shows the teacher's comment.
class GradeTile extends StatelessWidget {
  const GradeTile({super.key, required this.entry});

  final GradeEntry entry;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    final (icon, tone) = switch (entry.kind) {
      GradeKind.quiz => (LucideIcons.pencilLine, palette.rose),
      GradeKind.lessonPractice => (LucideIcons.monitorPlay, palette.coral),
      GradeKind.assignment => (LucideIcons.clipboardList, palette.amber),
    };
    final date = entry.date;
    final meta = [
      entry.kind.label,
      if (date != null) DateFormat('d MMM yyyy').format(date.toLocal()),
    ].join(' · ');
    return Semantics(
      label:
          '${entry.title}. $meta. ${entry.scoreLabel}, ${entry.percentLabel}.',
      excludeSemantics: true,
      child: SurfaceCard(
        radius: 16,
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SoftIconTile(icon: icon, tone: tone, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    style: AppFonts.bold(
                      color: palette.text,
                      fontSize: 13.5,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    meta,
                    style: AppFonts.regular(
                      color: palette.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  if (entry.feedback.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Teacher: ${entry.feedback}',
                      style: AppFonts.regular(
                        color: palette.text,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  entry.scoreLabel,
                  style: AppFonts.bold(color: palette.text, fontSize: 15),
                ),
                const SizedBox(height: 4),
                ToneChip(label: entry.percentLabel, tone: _tone(palette)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Green from 80%, amber from 50%, otherwise coral.
  AccentTone _tone(HomePalette palette) {
    if (entry.percent >= 80) return palette.mint;
    if (entry.percent >= 50) return palette.amber;
    return palette.coral;
  }
}
