import '../../subject/model/chapter_progress.dart';

/// Lesson counts for a whole course, added up from its chapters.
class CourseLessonSummary {
  const CourseLessonSummary({
    required this.chapterCount,
    required this.lessons,
  });

  factory CourseLessonSummary.from(Iterable<ChapterProgress> chapters) {
    var count = 0;
    var total = 0;
    var completed = 0;
    var started = 0;
    for (final chapter in chapters) {
      count++;
      total += chapter.total;
      completed += chapter.completed;
      started += chapter.started;
    }
    return CourseLessonSummary(
      chapterCount: count,
      lessons: ChapterProgress(
        total: total,
        completed: completed,
        started: started,
      ),
    );
  }

  final int chapterCount;
  final ChapterProgress lessons;

  /// "6 Chapters · 14/40 Lessons", or just the chapters while the course has
  /// no lessons yet.
  String get subtitle {
    final chapters = '$chapterCount Chapter${chapterCount == 1 ? '' : 's'}';
    if (lessons.total == 0) return chapters;
    return '$chapters · ${lessons.completed}/${lessons.total} Lessons';
  }
}
