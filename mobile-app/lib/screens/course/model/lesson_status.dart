/// Where one lesson stands for a learner inside a course.
enum LessonStatus {
  /// Watched to the end. Always open, so it can be revisited.
  completed,

  /// Started, not finished. This is where the learner left off.
  inProgress,

  /// Not started and open: the first lesson not yet finished.
  upNext,

  /// Closed until every lesson before it in the course is finished.
  locked,

  /// Not released yet.
  upcoming,
}
