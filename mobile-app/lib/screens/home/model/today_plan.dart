import '../../../services/today_service.dart';
import 'today_section.dart';

/// What Today shows for one learner: their overdue, to-do and upcoming work,
/// the next step for the top card, and the order of the sections, so the
/// screen follows their own work instead of a fixed layout.
class TodayPlan {
  const TodayPlan({
    this.attention = const [],
    this.todo = const [],
    this.comingUp = const [],
    this.sections = const [TodaySection.jumpBackIn, TodaySection.subjects],
    this.heroItem,
    this.isCaughtUp = false,
  });

  /// Past-due work.
  final List<TodayLearningItem> attention;

  /// Work to do now.
  final List<TodayLearningItem> todo;

  /// Work that opens later.
  final List<TodayLearningItem> comingUp;

  /// Sections to show, first to last. Lesson and subject blocks hide
  /// themselves when they have nothing to list.
  final List<TodaySection> sections;

  /// The next step for the top card. Null when there is nothing left to do,
  /// or when the overview could not be loaded.
  final TodayLearningItem? heroItem;

  /// The overview loaded and nothing is left to do.
  final bool isCaughtUp;

  /// Assignment states that mean the learner already handed the work in.
  static const _doneStatuses = {
    'submitted',
    'late',
    'graded',
    'returned',
    'completed',
  };

  /// The first group that has work, for the third stat tile: overdue, then
  /// to do, then coming up.
  TodaySection get focus => attention.isNotEmpty
      ? TodaySection.attention
      : todo.isNotEmpty
      ? TodaySection.todo
      : TodaySection.comingUp;

  int get focusCount => switch (focus) {
    TodaySection.attention => attention.length,
    TodaySection.todo => todo.length,
    _ => comingUp.length,
  };

  /// Without an overview (not loaded, or the request failed) this is the
  /// plain layout: lessons, then subjects.
  factory TodayPlan.fromOverview(TodayOverview? overview) {
    if (overview == null) return const TodayPlan();

    final attention = <TodayLearningItem>[];
    // Quizzes the learner already started come first: finish what you began.
    final todo = <TodayLearningItem>[
      ...overview.continueItems.where((item) => item.kind == 'quiz'),
    ];
    final comingUp = <TodayLearningItem>[];
    for (final item in overview.upcoming) {
      if (_doneStatuses.contains(item.status)) continue;
      if (item.status == 'overdue') {
        attention.add(item);
      } else if (item.kind == 'assignment' ||
          (item.kind == 'quiz' && item.status == 'live')) {
        todo.add(item);
      } else {
        comingUp.add(item);
      }
    }

    final next = overview.next;
    final heroItem =
        next == null ||
            next.title.trim().isEmpty ||
            _doneStatuses.contains(next.status)
        ? null
        : next;
    final lessonsInProgress = overview.continueItems.any(
      (item) => item.kind == 'video',
    );

    return TodayPlan(
      attention: attention,
      todo: todo,
      comingUp: comingUp,
      sections: [
        if (attention.isNotEmpty) TodaySection.attention,
        if (todo.isNotEmpty) TodaySection.todo,
        // Lessons in progress rank above what is merely coming; a finished
        // list of lessons ranks below everything else.
        if (lessonsInProgress) TodaySection.jumpBackIn,
        if (comingUp.isNotEmpty) TodaySection.comingUp,
        TodaySection.subjects,
        if (!lessonsInProgress) TodaySection.jumpBackIn,
      ],
      heroItem: heroItem,
      isCaughtUp: heroItem == null,
    );
  }
}
