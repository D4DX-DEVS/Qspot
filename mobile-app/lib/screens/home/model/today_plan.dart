import '../../../services/today_service.dart';
import 'today_item_text.dart';
import 'today_section.dart';

/// What Today shows for one learner: their ending-soon, to-do and upcoming work,
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

  /// Open work whose deadline is less than an hour away. Past-due work is
  /// not listed anywhere: its time is over and it can no longer be sent.
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
  static const doneStatuses = {'submitted', 'late', 'graded', 'completed'};

  /// The first group that has work, for the third stat tile: ending soon,
  /// then to do, then coming up.
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

  int get openItemCount => attention.length + todo.length + comingUp.length;

  /// Without an overview (not loaded, or the request failed) this is the
  /// plain layout: lessons, then subjects.
  factory TodayPlan.fromOverview(TodayOverview? overview, {DateTime? now}) {
    if (overview == null) return const TodayPlan();
    final at = now ?? DateTime.now();

    final attention = <TodayLearningItem>[];
    final todo = <TodayLearningItem>[];
    final comingUp = <TodayLearningItem>[];

    // The API can return the same item in `continue` and `upcoming`. Keep one
    // actionable copy across those sources while preserving the server's
    // ordering inside a single list. The hero may intentionally repeat the
    // first item so the learner can see it and its detailed row together.
    final blocked = <String>{};
    final continueSeen = <String>{};
    void addContinuation(TodayLearningItem item) {
      final key = '${item.kind}:${item.id}';
      if (item.id.isEmpty || continueSeen.add(key)) {
        (item.isEndingSoon(at) ? attention : todo).add(item);
        if (item.id.isNotEmpty) blocked.add(key);
      }
    }

    final next = overview.next;

    // Quizzes the learner already started come first: finish what you began.
    for (final item in overview.continueItems) {
      if (item.kind == 'quiz' && !doneStatuses.contains(item.status)) {
        addContinuation(item);
      }
    }

    for (final item in overview.upcoming) {
      if (doneStatuses.contains(item.status) || item.status == 'overdue') {
        continue;
      }
      final key = '${item.kind}:${item.id}';
      if (item.id.isNotEmpty && blocked.contains(key)) continue;
      if (item.kind == 'assignment' ||
          (item.kind == 'quiz' && item.status == 'live')) {
        (item.isEndingSoon(at) ? attention : todo).add(item);
      } else {
        comingUp.add(item);
      }
    }

    bool isActionable(TodayLearningItem item) =>
        item.title.trim().isNotEmpty &&
        !doneStatuses.contains(item.status) &&
        item.status != 'overdue';
    TodayLearningItem? firstActionable(List<TodayLearningItem> items) {
      for (final item in items) {
        if (isActionable(item)) return item;
      }
      return null;
    }

    // Work ending within the hour beats the server's pick.
    final heroItem =
        firstActionable(attention) ??
        (next != null && isActionable(next) ? next : null) ??
        firstActionable(todo) ??
        firstActionable(comingUp);
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
      // A missing `next` is not proof that the learner is caught up: older
      // API responses may still provide overdue or queued work in the lists.
      isCaughtUp:
          heroItem == null &&
          attention.isEmpty &&
          todo.isEmpty &&
          comingUp.isEmpty &&
          !lessonsInProgress,
    );
  }
}
