import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../themes/accent_tone.dart';
import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/common/soft_icon_tile.dart';
import '../../../widgets/common/tone_chip.dart';
import '../model/lesson_status.dart';
import '../model/syllabus_lesson.dart';

/// One lesson row in a chapter: a status icon, "3. Title", a short line about
/// it and a chip saying what to do with it.
class SyllabusLessonTile extends StatelessWidget {
  const SyllabusLessonTile({
    super.key,
    required this.lesson,
    required this.onTap,
  });

  final SyllabusLesson lesson;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    final (icon, tone, chip) = _look(palette);
    final closed = !lesson.isOpenable;
    return Semantics(
      button: true,
      excludeSemantics: true,
      label: '${lesson.number}. ${lesson.title}. $chip',
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              SoftIconTile(icon: icon, tone: tone, size: 38, circle: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${lesson.number}. ${lesson.title}',
                      style: AppFonts.semiBold(
                        color: closed ? palette.textMuted : palette.text,
                        fontSize: 14,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _meta(),
                      style: AppFonts.regular(
                        color: palette.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ToneChip(label: chip, tone: tone),
            ],
          ),
        ),
      ),
    );
  }

  (IconData, AccentTone, String) _look(HomePalette palette) =>
      switch (lesson.status) {
        LessonStatus.completed => (
          LucideIcons.circleCheck,
          palette.mint,
          'Done',
        ),
        LessonStatus.inProgress => (LucideIcons.play, palette.rose, 'Resume'),
        LessonStatus.upNext => (LucideIcons.play, palette.amber, 'Start'),
        LessonStatus.locked => (LucideIcons.lock, palette.slate, 'Locked'),
        LessonStatus.upcoming => (LucideIcons.clock, palette.slate, 'Soon'),
      };

  String _meta() {
    final duration = lesson.video.formattedDuration;
    final parts = <String>[
      'Video',
      if (duration != '--:--') duration,
      if (lesson.status == LessonStatus.inProgress && lesson.progress > 0)
        '${(lesson.progress * 100).round()}% watched',
    ];
    return parts.join(' · ');
  }
}
