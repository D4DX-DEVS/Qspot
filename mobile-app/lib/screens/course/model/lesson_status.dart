/// Where one lesson stands for a learner inside a course.
enum LessonStatus {
  /// Watched to the end. Always open, so it can be revisited.
  completed,

  /// Started, not finished. This is where the learner left off.
  inProgress,

  /// Open and not started yet.
  notStarted,

  /// Not released yet.
  upcoming,
}
