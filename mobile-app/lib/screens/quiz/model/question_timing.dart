import 'dart:math';

/// How long one question took. The server receives only [timeTakenMs]; the
/// other fields stay on the phone to run the question's countdown.
///
/// Time is counted while the question is on screen with the app in front.
/// Immutable: every change returns a new value, so the copy saved on the phone
/// is always a complete snapshot.
class QuestionTiming {
  const QuestionTiming({
    this.firstShownAt,
    this.visibleSince,
    this.spentMs = 0,
    this.answerSpentMs,
    this.timedOut = false,
  });

  /// Starts the question's countdown (phone clock).
  final DateTime? firstShownAt;

  /// Set while the question is on screen with the app in front; the time
  /// since then is not yet in [spentMs].
  final DateTime? visibleSince;
  final int spentMs;

  /// Time on screen when the final answer was picked.
  final int? answerSpentMs;
  final bool timedOut;

  /// Time taken to answer; for an unanswered question, its time on screen
  /// (the full limit when its time ran out).
  int get timeTakenMs => answerSpentMs ?? spentMs;

  /// Milliseconds on screen up to [now], including the visit in progress.
  int spentMsAt(DateTime now) =>
      spentMs +
      (visibleSince == null
          ? 0
          : max(0, now.difference(visibleSince!).inMilliseconds));

  QuestionTiming _with({
    DateTime? firstShownAt,
    DateTime? visibleSince,
    bool clearVisible = false,
    int? spentMs,
    int? answerSpentMs,
    bool? timedOut,
  }) => QuestionTiming(
    firstShownAt: firstShownAt ?? this.firstShownAt,
    visibleSince: clearVisible ? null : (visibleSince ?? this.visibleSince),
    spentMs: spentMs ?? this.spentMs,
    answerSpentMs: answerSpentMs ?? this.answerSpentMs,
    timedOut: timedOut ?? this.timedOut,
  );

  /// The student moved to this question.
  QuestionTiming shown(DateTime now) =>
      _with(firstShownAt: firstShownAt ?? now, visibleSince: now);

  /// The student moved away, or the app went to the background.
  QuestionTiming hidden(DateTime now) => visibleSince == null
      ? this
      : _with(spentMs: spentMsAt(now), clearVisible: true);

  /// The app came back to the front with this question on screen.
  QuestionTiming resumed(DateTime now) =>
      visibleSince == null ? _with(visibleSince: now) : this;

  /// An option was picked. Picking the option already chosen changes nothing.
  QuestionTiming answered(
    DateTime now, {
    required int? previous,
    required int choice,
  }) => previous == choice ? this : _with(answerSpentMs: spentMsAt(now));

  /// The question's countdown reached [deadline]: it took its full [limitMs].
  QuestionTiming expiredAt(DateTime deadline, {int? limitMs}) {
    final stopped = hidden(deadline);
    return stopped._with(spentMs: limitMs ?? stopped.spentMs, timedOut: true);
  }

  /// What the server receives for this question: seconds, one decimal.
  Map<String, dynamic> toSubmission() => {
    'duration': (timeTakenMs / 100).round() / 10,
  };

  Map<String, dynamic> toJson() => {
    'firstShownAt': firstShownAt?.toIso8601String(),
    'visibleSince': visibleSince?.toIso8601String(),
    'spentMs': spentMs,
    'answerSpentMs': answerSpentMs,
    'timedOut': timedOut,
  };

  static QuestionTiming fromJson(Object? json) {
    if (json is! Map) return const QuestionTiming();
    DateTime? date(String key) => DateTime.tryParse('${json[key] ?? ''}');
    final answer = json['answerSpentMs'];
    return QuestionTiming(
      firstShownAt: date('firstShownAt'),
      visibleSince: date('visibleSince'),
      spentMs: json['spentMs'] is int ? max(0, json['spentMs'] as int) : 0,
      answerSpentMs: answer is int ? max(0, answer) : null,
      timedOut: json['timedOut'] == true,
    );
  }
}
