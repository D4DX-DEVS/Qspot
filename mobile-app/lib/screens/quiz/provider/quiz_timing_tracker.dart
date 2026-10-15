import 'dart:math';

import '../model/question_timing.dart';

/// Keeps the clock for one quiz: per-question timings and the deadlines of
/// the whole-quiz and per-question countdowns. Used by `QuizProvider`; it
/// does no I/O and takes the current time as an argument, so it is easy to
/// test.
///
/// The whole-quiz clock starts when the server first handed out the questions
/// (lined up with the phone's clock through [_offsetMs]); a question's clock
/// starts when it is first shown. Both keep running while the app is in the
/// background or closed, so neither can be refilled. The quiz also closes at
/// its end time ([closingDeadline]), whatever time limits it has.
class QuizTimingTracker {
  final Map<String, QuestionTiming> _timings = {};
  DateTime? _serverStartedAt;
  DateTime? _endsAt;
  int _offsetMs = 0;
  DateTime _localStart = DateTime.fromMillisecondsSinceEpoch(0);
  int? _overallLimit;
  int? _perQuestionLimit;

  /// Starts tracking [questionIds]. [saved] timings from an earlier visit are
  /// kept for questions still in the quiz; a question that was on screen when
  /// the app stopped is closed at [savedAt], the last moment the app was known
  /// to be running.
  void load({
    required List<String> questionIds,
    required DateTime localStart,
    Map<String, QuestionTiming> saved = const {},
    DateTime? savedAt,
    DateTime? serverStartedAt,
    DateTime? endsAt,
    int offsetMs = 0,
    int? overallLimit,
    int? perQuestionLimit,
  }) {
    _timings.clear();
    for (final id in questionIds) {
      final timing = saved[id];
      if (timing == null) continue;
      final since = timing.visibleSince;
      _timings[id] = since == null
          ? timing
          : timing.hidden(
              savedAt != null && savedAt.isAfter(since) ? savedAt : since,
            );
    }
    _serverStartedAt = serverStartedAt;
    _endsAt = endsAt;
    _offsetMs = offsetMs;
    _localStart = localStart;
    _overallLimit = overallLimit;
    _perQuestionLimit = perQuestionLimit;
  }

  Map<String, QuestionTiming> get timings => Map.unmodifiable(_timings);
  DateTime? get serverStartedAt => _serverStartedAt;
  int get offsetMs => _offsetMs;

  QuestionTiming timingOf(String id) => _timings[id] ?? const QuestionTiming();

  /// When the quiz started, on the phone's clock.
  DateTime get quizStart =>
      _serverStartedAt?.subtract(Duration(milliseconds: _offsetMs)) ??
      _localStart;

  DateTime? get overallDeadline => _overallLimit == null
      ? null
      : quizStart.add(Duration(seconds: _overallLimit!));

  /// When the quiz itself closes (its end time), on the phone's clock.
  DateTime? get closingDeadline =>
      _endsAt?.subtract(Duration(milliseconds: _offsetMs));

  /// Null when questions have no time limit or [id] was never shown.
  DateTime? questionDeadline(String id) {
    final shown = timingOf(id).firstShownAt;
    if (_perQuestionLimit == null || shown == null) return null;
    return shown.add(Duration(seconds: _perQuestionLimit!));
  }

  /// Whether [id] can still be answered at [now].
  bool isOpen(String id, DateTime now) {
    if (timingOf(id).timedOut) return false;
    return [
      questionDeadline(id),
      overallDeadline,
      closingDeadline,
    ].every((deadline) => deadline == null || now.isBefore(deadline));
  }

  /// Whole seconds since the quiz started.
  int secondsSinceStart(DateTime now) =>
      max(0, now.difference(quizStart).inSeconds);

  void show(String id, DateTime now) => _timings[id] = timingOf(id).shown(now);
  void hide(String id, DateTime now) => _timings[id] = timingOf(id).hidden(now);
  void resume(String id, DateTime now) =>
      _timings[id] = timingOf(id).resumed(now);

  void answered(
    String id,
    DateTime now, {
    int? previous,
    required int choice,
  }) => _timings[id] = timingOf(
    id,
  ).answered(now, previous: previous, choice: choice);

  /// [id]'s countdown ran out: it took its full time.
  void expire(String id, DateTime now) {
    final deadline = questionDeadline(id);
    final limit = _perQuestionLimit;
    _timings[id] = timingOf(id).expiredAt(
      deadline != null && deadline.isBefore(now) ? deadline : now,
      limitMs: limit == null ? null : limit * 1000,
    );
  }
}
