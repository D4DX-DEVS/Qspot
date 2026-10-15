import 'package:flutter/foundation.dart';

import '../../../services/video_progress_service.dart';

/// Screen-local state for the video questions screen: current question,
/// chosen answers, submit progress, the graded result and the countdown.
class VideoQuestionsScreenProvider extends ChangeNotifier {
  VideoQuestionsScreenProvider({VideoQuizResult? priorResult})
    : _result = priorResult;

  int _index = 0;
  final Map<String, int> _answers = {};
  bool _submitting = false;
  VideoQuizResult? _result;
  String? _submitError;
  int? _remainingSeconds;

  int get index => _index;
  bool get submitting => _submitting;
  VideoQuizResult? get result => _result;
  String? get submitError => _submitError;
  int? get remainingSeconds => _remainingSeconds;

  int? answerFor(String questionId) => _answers[questionId];

  /// Answers in the shape the submit endpoint expects; unanswered = -1.
  List<Map<String, String>> answersPayload(List<VideoQuestionItem> questions) {
    return questions
        .map(
          (q) => {
            'questionId': q.id,
            'attemptedAnswer': (_answers[q.id] ?? -1).toString(),
          },
        )
        .toList();
  }

  void choose(String questionId, int optionIndex) {
    _answers[questionId] = optionIndex;
    notifyListeners();
  }

  void nextQuestion() {
    _index += 1;
    notifyListeners();
  }

  void setRemainingSeconds(int seconds) {
    _remainingSeconds = seconds;
    notifyListeners();
  }

  void decrementRemaining() {
    _remainingSeconds = _remainingSeconds! - 1;
    notifyListeners();
  }

  void startSubmit() {
    _submitting = true;
    _submitError = null;
    notifyListeners();
  }

  void finishSubmit(VideoQuizResult? result) {
    _submitting = false;
    _result = result;
    notifyListeners();
  }

  void failSubmit(String message) {
    _submitting = false;
    _submitError = message;
    notifyListeners();
  }
}
