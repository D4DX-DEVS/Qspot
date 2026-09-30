import 'package:flutter/foundation.dart';

/// Screen-local state for the quiz question screen: the countdown value shown
/// in the header and whether a submission is in flight. The periodic timer
/// itself stays in the screen (its callback needs to trigger a submit).
class QuizQuestionScreenProvider extends ChangeNotifier {
  bool _submitting = false;
  int? _remainingSeconds;
  bool _timerStarted = false;

  bool get submitting => _submitting;
  int? get remainingSeconds => _remainingSeconds;
  bool get timerStarted => _timerStarted;

  /// "m:ss" label for the current countdown value.
  String get timerLabel {
    final seconds = _remainingSeconds ?? 0;
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  void setSubmitting(bool value) {
    _submitting = value;
    notifyListeners();
  }

  /// Marks the timer as running with [initial] seconds. Called from build, so
  /// it deliberately does not notify (the same build reads the new value).
  void startTimer(int initial) {
    _timerStarted = true;
    _remainingSeconds = initial;
  }

  void setRemainingSeconds(int seconds) {
    _remainingSeconds = seconds;
    notifyListeners();
  }
}
