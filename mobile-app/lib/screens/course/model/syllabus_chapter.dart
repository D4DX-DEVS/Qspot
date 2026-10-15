import '../../subject/model/chapter_progress.dart';
import '../../subject/model/subject_model.dart';
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
}
