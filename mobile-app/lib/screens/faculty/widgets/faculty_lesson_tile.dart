import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/common/soft_icon_tile.dart';
import '../../../widgets/common/surface_card.dart';
import '../../../widgets/common/tone_chip.dart';

/// One of the teacher's lessons: tinted play icon, title, subject, and
/// whether students can see it yet.
class FacultyLessonTile extends StatelessWidget {
  const FacultyLessonTile({
    super.key,
    required this.title,
    this.subject = '',
    required this.isPublished,
    this.durationSeconds,
  });

  final String title;
  final String subject;
  final bool isPublished;
  final int? durationSeconds;

  @override
  Widget build(BuildContext context) {
    final p = HomePalette.of(context);
    final minutes = durationSeconds == null || durationSeconds! <= 0
        ? null
        : (durationSeconds! / 60).ceil();
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SoftIconTile(icon: LucideIcons.circlePlay, tone: p.rose, size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppFonts.bold(color: p.text, fontSize: 15.5),
                ),
                if (subject.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    subject,
                    style: AppFonts.regular(color: p.textMuted, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ToneChip(
                      label: isPublished ? 'Published' : 'Draft',
                      tone: isPublished ? p.mint : p.slate,
                    ),
                    if (minutes != null)
                      Text(
                        '$minutes min',
                        style: AppFonts.regular(
                          color: p.textMuted,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
