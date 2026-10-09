import 'package:flutter/foundation.dart';

/// Which countdown ran out on a [QuizQuestionScreenProvider.tick].
enum QuizTimerExpiry { none, overall, question }

/// Screen-local state for the quiz question screen: the countdowns shown in
/// the header and whether a submission is in flight. The periodic timer
/// itself stays in the screen (its callback needs to trigger a submit).
///
/// The whole-quiz and per-question countdowns run independently, so moving
/// to the next question only refills the per-question one.
class QuizQuestionScreenProvider extends ChangeNotifier {
  bool _submitting = false;
  bool _timerStarted = false;
  int? _overallRemaining;
  int? _questionRemaining;
  int? _perQuestionLimit;

  bool get submitting => _submitting;
  bool get timerStarted => _timerStarted;
  int? get overallRemaining => _overallRemaining;
  int? get questionRemaining => _questionRemaining;

  /// "m:ss" label for a countdown value.
  static String timerLabel(int seconds) =>
      '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

  void setSubmitting(bool value) {
    _submitting = value;
    notifyListeners();
  }

  /// Starts the countdowns that are set: [overall] for the whole quiz and
  /// [perQuestion] for each question. Called from build, so it deliberately
  /// does not notify (the same build reads the new values).
  void startTimers({int? overall, int? perQuestion}) {
    _timerStarted = true;
    _overallRemaining = overall;
    _perQuestionLimit = perQuestion;
    _questionRemaining = perQuestion;
  }

  /// Gives the new current question the full per-question time.
  void resetQuestionTimer() {
    if (_perQuestionLimit == null) return;
    _questionRemaining = _perQuestionLimit;
    notifyListeners();
  }

  /// Counts the running countdowns down by one second and reports which one
  /// just reached zero (the whole-quiz one wins if both do). A countdown
  /// already at zero stays there and is not reported again.
  QuizTimerExpiry tick() {
    var expired = QuizTimerExpiry.none;
    var changed = false;
    final overall = _overallRemaining;
    if (overall != null && overall > 0) {
      _overallRemaining = overall - 1;
      changed = true;
      if (overall == 1) expired = QuizTimerExpiry.overall;
    }
    final question = _questionRemaining;
    if (question != null && question > 0) {
      _questionRemaining = question - 1;
      changed = true;
      if (question == 1 && expired == QuizTimerExpiry.none) {
        expired = QuizTimerExpiry.question;
      }
    }
    if (changed) notifyListeners();
    return expired;
  }
}
