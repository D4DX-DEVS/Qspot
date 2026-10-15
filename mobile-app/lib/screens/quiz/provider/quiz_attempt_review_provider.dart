import 'package:flutter/foundation.dart';

import '../../../services/api_client.dart';
import '../../../services/quiz_attempt_service.dart';
import '../model/quiz_model.dart';

/// Loads a finished exam attempt with its answers, for "Review Answers" on a
/// result opened from the quiz list (that summary carries no answers).
class QuizAttemptReviewProvider extends ChangeNotifier {
  QuizAttemptReviewProvider({
    Future<QuizAttemptResult> Function(String attemptId)? fetch,
  }) : _fetch = fetch ?? QuizAttemptService.fetch;

  final Future<QuizAttemptResult> Function(String attemptId) _fetch;

  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;

  /// The attempt with its per-question results, or null when it could not be
  /// loaded or the answers are not available yet ([error] says why).
  Future<QuizAttemptResult?> load(String attemptId) async {
    if (_loading) return null;
    _loading = true;
    _error = null;
    notifyListeners();
    QuizAttemptResult? attempt;
    try {
      attempt = await _fetch(attemptId);
      if (attempt.results.isEmpty) {
        _error = "The answers aren't available yet.";
        attempt = null;
      }
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error =
          "Couldn't load your answers. Check your connection and try again.";
    }
    _loading = false;
    notifyListeners();
    return attempt;
  }
}
