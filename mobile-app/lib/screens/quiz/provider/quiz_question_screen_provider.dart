import 'dart:math';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';

/// Which countdown ran out on a [QuizQuestionScreenProvider.tick]: the whole
/// quiz's time limit, the quiz closing at its end time, or the question's.
enum QuizTimerExpiry { none, overall, closing, question }

/// Screen-local state for the quiz question screen: the countdowns shown in
/// the header and whether a submission is in flight. The periodic timer
/// itself stays in the screen (its callback needs to trigger a submit).
///
/// Each countdown runs to a fixed deadline and every tick reads the clock, so
/// time that passes while the app is in the background, closed, or the timer
/// is late still counts. The whole-quiz and per-question deadlines are
/// independent: a new question only gets a new per-question deadline.
class QuizQuestionScreenProvider extends ChangeNotifier {
  /// How long before the quiz closes the "Closes in" warning shows.
  static const int closingWarningSeconds = 5 * 60;

  bool _submitting = false;
  bool _timerStarted = false;
  DateTime? _overallDeadline;
  DateTime? _questionDeadline;
  DateTime? _closingDeadline;
  int? _overallRemaining;
  int? _questionRemaining;
  int? _closingRemaining;
  bool _overallReported = false;
  bool _questionReported = false;
  bool _closingReported = false;

  bool get submitting => _submitting;
  bool get timerStarted => _timerStarted;
  int? get overallRemaining => _overallRemaining;
  int? get questionRemaining => _questionRemaining;

  /// Seconds until the quiz closes, shown only in the last few minutes and
  /// only when it comes before the quiz's own time limit runs out.
  int? get closingWarning {
    final closing = _closingRemaining;
    if (closing == null || closing > closingWarningSeconds) return null;
    final overall = _overallRemaining;
    return overall != null && overall <= closing ? null : closing;
  }

  /// "m:ss" label for a countdown value.
  static String timerLabel(int seconds) =>
      '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

  /// Whole seconds left until [deadline], rounded up, never below zero.
  static int secondsUntil(DateTime deadline) =>
      max(0, (deadline.difference(clock.now()).inMilliseconds / 1000).ceil());

  void setSubmitting(bool value) {
    _submitting = value;
    notifyListeners();
  }

  /// Starts the countdowns that are set. Called from build, so it
  /// deliberately does not notify (the same build reads the new values).
  void startTimers({
    DateTime? overallDeadline,
    DateTime? questionDeadline,
    DateTime? closingDeadline,
  }) {
    _timerStarted = true;
    _overallDeadline = overallDeadline;
    _questionDeadline = questionDeadline;
    _closingDeadline = closingDeadline;
    _overallReported = false;
    _questionReported = false;
    _closingReported = false;
    _refresh();
  }

  /// The current question changed: count down to its own deadline (null when
  /// questions have no time limit).
  void setQuestionDeadline(DateTime? deadline) {
    if (deadline == _questionDeadline) return;
    _questionDeadline = deadline;
    _questionReported = false;
    _refresh();
    notifyListeners();
  }

  bool _refresh() {
    final overall = _overallDeadline == null
        ? null
        : secondsUntil(_overallDeadline!);
    final question = _questionDeadline == null
        ? null
        : secondsUntil(_questionDeadline!);
    final closing = _closingDeadline == null
        ? null
        : secondsUntil(_closingDeadline!);
    final changed =
        overall != _overallRemaining ||
        question != _questionRemaining ||
        closing != _closingRemaining;
    _overallRemaining = overall;
    _questionRemaining = question;
    _closingRemaining = closing;
    return changed;
  }

  /// Re-reads the clock and reports a countdown that has just reached zero
  /// (the whole-quiz ones win over the question's). Each is reported once.
  QuizTimerExpiry tick() {
    final changed = _refresh();
    var expired = QuizTimerExpiry.none;
    if (_overallRemaining == 0 && !_overallReported) {
      _overallReported = true;
      expired = QuizTimerExpiry.overall;
    }
    if (_closingRemaining == 0 && !_closingReported) {
      _closingReported = true;
      if (expired == QuizTimerExpiry.none) expired = QuizTimerExpiry.closing;
    }
    if (_questionRemaining == 0 && !_questionReported) {
      _questionReported = true;
      if (expired == QuizTimerExpiry.none) expired = QuizTimerExpiry.question;
    }
    if (changed) notifyListeners();
    return expired;
  }
}
