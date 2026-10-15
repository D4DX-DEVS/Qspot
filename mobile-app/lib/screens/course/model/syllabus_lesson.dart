import '../../video/model/video_model.dart';
import 'lesson_status.dart';

/// One lesson in a course syllabus, with its place in the chapter and where
/// the learner stands on it.
class SyllabusLesson {
  const SyllabusLesson({
    required this.video,
    required this.number,
    required this.chapterNumber,
    required this.status,
    this.progress = 0,
    this.lockHint = '',
  });

  final VideoModel video;

  /// 1-based position inside its chapter.
  final int number;
  final int chapterNumber;
  final LessonStatus status;

  /// 0 to 1, how far the learner got.
  final double progress;

  /// Why a locked lesson is closed, e.g. `Finish "Rules of Madd" first.`
  final String lockHint;

  String get id => video.id;
  String get title => video.displayTitle;

  /// Whether the learner can play it now.
  bool get isOpenable =>
      status == LessonStatus.completed ||
      status == LessonStatus.inProgress ||
      status == LessonStatus.upNext;

  /// Closed until the lessons before it are finished.
  bool get isLocked => status == LessonStatus.locked;

  /// Why it cannot be opened, or null when it can.
  String? get blockedMessage => switch (status) {
    LessonStatus.locked => lockHint,
    LessonStatus.upcoming => 'This lesson has not opened yet.',
    _ => null,
  };
}
