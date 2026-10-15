import '../../subject/model/chapter_progress.dart';
import '../../subject/model/subject_model.dart';
import 'lesson_status.dart';
import 'syllabus_lesson.dart';

/// One chapter of a course syllabus: its lessons in order and its counts.
class SyllabusChapter {
  const SyllabusChapter({
    required this.subject,
    required this.number,
    required this.lessons,
    required this.progress,
  });

  final SubjectModel subject;

  /// 1-based position inside the course.
  final int number;
  final List<SyllabusLesson> lessons;
  final ChapterProgress progress;

  String get id => subject.id;
  String get title => subject.displayName;

  /// Every lesson in the chapter is closed, so the whole chapter is.
  bool get isLocked =>
      lessons.isNotEmpty &&
      lessons.every(
        (lesson) =>
            lesson.status == LessonStatus.locked ||
            lesson.status == LessonStatus.upcoming,
      ) &&
      lessons.any((lesson) => lesson.status == LessonStatus.locked);
}
