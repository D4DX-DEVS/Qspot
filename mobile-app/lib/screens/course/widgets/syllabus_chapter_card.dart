import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/common/surface_card.dart';
import '../../../widgets/common/tone_chip.dart';
import '../../subject/widgets/chapter_status_chip.dart';
import '../model/syllabus_chapter.dart';
import '../model/syllabus_lesson.dart';
import 'syllabus_lesson_tile.dart';

/// One chapter of the syllabus. Tapping the header opens or closes its lesson
/// list.
class SyllabusChapterCard extends StatelessWidget {
  const SyllabusChapterCard({
    super.key,
    required this.chapter,
    required this.expanded,
    required this.onToggle,
    required this.onLessonTap,
  });

  final SyllabusChapter chapter;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<SyllabusLesson> onLessonTap;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _header(palette),
          if (expanded) ...[
            Divider(height: 1, color: palette.cardBorder),
            if (chapter.lessons.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No lessons yet',
                  style: AppFonts.medium(
                    color: palette.textMuted,
                    fontSize: 12,
                  ),
                ),
              ),
            for (var i = 0; i < chapter.lessons.length; i++) ...[
              if (i > 0) Divider(height: 1, color: palette.cardBorder),
              SyllabusLessonTile(
                lesson: chapter.lessons[i],
                onTap: () => onLessonTap(chapter.lessons[i]),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _header(HomePalette palette) {
    final progress = chapter.progress;
    return Semantics(
      button: true,
      expanded: expanded,
      excludeSemantics: true,
      label:
          'Chapter ${chapter.number}, ${chapter.title}, '
          '${progress.completed} of ${progress.total} lessons complete',
      child: InkWell(
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Chapter ${chapter.number}',
                          style: AppFonts.semiBold(
                            color: palette.brand,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (chapter.isLocked)
                          ToneChip(label: 'Locked', tone: palette.slate)
                        else
                          ChapterStatusChip(status: progress.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      chapter.title,
                      style: AppFonts.bold(
                        color: palette.text,
                        fontSize: 15,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      progress.total == 0
                          ? 'No Lessons Yet'
                          : '${progress.completed}/${progress.total} Lessons',
                      style: AppFonts.semiBold(
                        color: palette.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                size: 20,
                color: palette.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
