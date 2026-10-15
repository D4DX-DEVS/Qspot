/// The blocks Today can show. Which ones appear, and in what order, depends
/// on the learner's own work (see `TodayPlan`).
enum TodaySection {
  /// Past-due work.
  attention,

  /// Work to do now: open assignments, live and half-done quizzes.
  todo,

  /// Lessons the learner has already started.
  jumpBackIn,

  /// Sessions, quizzes and lessons that open later.
  comingUp,

  /// All subjects, to start something new.
  subjects,
}
