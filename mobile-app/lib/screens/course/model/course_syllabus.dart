import '../../../services/video_progress_service.dart';
import '../../subject/model/chapter_progress.dart';
import '../../subject/model/subject_model.dart';
import '../../video/model/video_model.dart';
import 'course_lesson_summary.dart';
import 'lesson_status.dart';
import 'syllabus_chapter.dart';
import 'syllabus_lesson.dart';

/// A course laid out in teaching order, chapter by chapter. Every released
/// lesson is open, in any order; the order only decides what "carry on" means.
/// A lesson that has not been released yet stays closed.
class CourseSyllabus {
  const CourseSyllabus({required this.chapters});

  /// [subjects] are the course's chapters, [lessonsFor] gives one chapter's
  /// lessons in teaching order, and [progress] is the learner's watch state
  /// by lesson id.
  factory CourseSyllabus.build({
    required Iterable<SubjectModel> subjects,
    required List<VideoModel> Function(String subjectId) lessonsFor,
    required Map<String, VideoProgressStatus> progress,
  }) {
    final ordered = subjects.toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    final chapters = <SyllabusChapter>[];

    for (var c = 0; c < ordered.length; c++) {
      final subject = ordered[c];
      final lessons = <SyllabusLesson>[];
      var total = 0;
      var completed = 0;
      var started = 0;

      final videos = lessonsFor(subject.id);
      for (var i = 0; i < videos.length; i++) {
        final video = videos[i];
        final watch = progress[video.id];
        final done = !video.isUpcoming && watch?.completed == true;
        final begun = !done && (watch?.positionSeconds ?? 0) > 0;
        if (!video.isUpcoming) total++;
        if (done) completed++;
        if (begun) started++;

        final LessonStatus status = done
            ? LessonStatus.completed
            : video.isUpcoming
            ? LessonStatus.upcoming
            : begun
            ? LessonStatus.inProgress
            : LessonStatus.notStarted;

        lessons.add(
          SyllabusLesson(
            video: video,
            number: i + 1,
            chapterNumber: c + 1,
            status: status,
            progress: watch?.percent ?? 0,
          ),
        );
      }

      chapters.add(
        SyllabusChapter(
          subject: subject,
          number: c + 1,
          lessons: lessons,
          progress: ChapterProgress(
            total: total,
            completed: completed,
            started: started,
          ),
        ),
      );
    }
    return CourseSyllabus(chapters: chapters);
  }

  /// The syllabus of the course a chapter belongs to. A chapter that is not
  /// part of a course stands alone. Empty when [subjectId] is not in
  /// [subjects].
  factory CourseSyllabus.forChapter({
    required String subjectId,
    required Iterable<SubjectModel> subjects,
    required List<VideoModel> Function(String subjectId) lessonsFor,
    required Map<String, VideoProgressStatus> progress,
  }) {
    final chapter = subjects.where((s) => s.id == subjectId).firstOrNull;
    if (chapter == null) return const CourseSyllabus(chapters: []);
    final courseId = chapter.courseId;
    final inCourse = courseId == null || courseId.isEmpty
        ? [chapter]
        : subjects.where((s) => s.courseId == courseId);
    return CourseSyllabus.build(
      subjects: inCourse,
      lessonsFor: lessonsFor,
      progress: progress,
    );
  }

  final List<SyllabusChapter> chapters;

  /// The lesson with this video id, or null when it is not in the syllabus.
  SyllabusLesson? lessonFor(String videoId) =>
      lessons.where((lesson) => lesson.id == videoId).firstOrNull;

  /// The chapter that holds this video, or null.
  SyllabusChapter? chapterOf(String videoId) => chapters
      .where((chapter) => chapter.lessons.any((l) => l.id == videoId))
      .firstOrNull;

  /// The lesson just before this one in the course, or null for the first.
  SyllabusLesson? previousOf(String videoId) {
    SyllabusLesson? before;
    for (final lesson in lessons) {
      if (lesson.id == videoId) return before;
      before = lesson;
    }
    return null;
  }

  /// The lesson just after this one in the course, or null for the last.
  SyllabusLesson? nextOf(String videoId) {
    var found = false;
    for (final lesson in lessons) {
      if (found) return lesson;
      if (lesson.id == videoId) found = true;
    }
    return null;
  }

  bool get isEmpty => chapters.every((chapter) => chapter.lessons.isEmpty);

  CourseLessonSummary get summary =>
      CourseLessonSummary.from(chapters.map((chapter) => chapter.progress));

  Iterable<SyllabusLesson> get lessons =>
      chapters.expand((chapter) => chapter.lessons);

  /// The lesson to carry on with: the first one, in teaching order, that is
  /// open and not finished. Null when the learner has finished everything
  /// that is released.
  SyllabusLesson? get next {
    for (final lesson in lessons) {
      if (lesson.status == LessonStatus.inProgress ||
          lesson.status == LessonStatus.notStarted) {
        return lesson;
      }
    }
    return null;
  }
}
