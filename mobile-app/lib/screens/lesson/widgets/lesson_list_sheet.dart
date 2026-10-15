import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/common/home_sheet_shell.dart';
import '../../course/model/course_syllabus.dart';
import '../../course/model/syllabus_lesson.dart';
import '../../course/widgets/syllabus_lesson_tile.dart';

/// Every lesson of the course, chapter by chapter, with where the learner
/// stands on each. Open from the lesson page to jump to another lesson.
class LessonListSheet extends StatelessWidget {
  const LessonListSheet({
    super.key,
    required this.syllabus,
    required this.currentId,
    required this.onSelect,
  });

  final CourseSyllabus syllabus;

  /// The lesson being viewed, highlighted in the list.
  final String currentId;
  final ValueChanged<SyllabusLesson> onSelect;

  /// Opens the list. [onSelect] runs after the sheet has closed.
  static Future<void> show(
    BuildContext context, {
    required CourseSyllabus syllabus,
    required String currentId,
    required ValueChanged<SyllabusLesson> onSelect,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => HomeSheetShell(
      child: LessonListSheet(
        syllabus: syllabus,
        currentId: currentId,
        onSelect: (lesson) {
          Navigator.pop(sheetContext);
          onSelect(lesson);
        },
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.78,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Lessons',
                      style: AppFonts.bold(color: palette.text, fontSize: 18),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.x),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 12),
                children: [
                  for (final chapter in syllabus.chapters) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                      child: Text(
                        'Chapter ${chapter.number} · ${chapter.title}',
                        style: AppFonts.semiBold(
                          color: palette.textMuted,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    for (final lesson in chapter.lessons)
                      ColoredBox(
                        color: lesson.id == currentId
                            ? palette.brandSoft
                            : Colors.transparent,
                        child: SyllabusLessonTile(
                          lesson: lesson,
                          onTap: () => onSelect(lesson),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
