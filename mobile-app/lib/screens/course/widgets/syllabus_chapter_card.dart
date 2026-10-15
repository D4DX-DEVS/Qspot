import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/common/surface_card.dart';
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
      onTap: onToggle,
      label:
          'Chapter ${chapter.number}, ${chapter.title}, '
          '${progress.completed} of ${progress.total} lessons complete',
      child: InkWell(
        onTap: onToggle,
        child: Container(
          color: expanded ? palette.brandSoft : null,
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chapter ${chapter.number} · ${chapter.title}',
                      style: AppFonts.bold(
                        color: palette.text,
                        fontSize: 14,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      progress.total == 0
                          ? 'No lessons yet'
                          : '${progress.completed} of ${progress.total} '
                                'lesson${progress.total == 1 ? '' : 's'}',
                      style: AppFonts.regular(
                        color: palette.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ChapterStatusChip(status: progress.status),
              const SizedBox(width: 4),
              Icon(
                expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                size: 18,
                color: palette.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
