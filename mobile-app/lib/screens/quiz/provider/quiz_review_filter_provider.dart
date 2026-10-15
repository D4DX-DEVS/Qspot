import 'package:flutter/foundation.dart';

import '../model/quiz_model.dart';

enum ReviewFilter { all, wrong }

/// Which questions the answer review shows: all of them, or only the ones
/// the learner got wrong. Question numbers stay those of the full attempt.
class QuizReviewFilterProvider extends ChangeNotifier {
  QuizReviewFilterProvider(this._results);

  final List<QuestionResult> _results;
  ReviewFilter _filter = ReviewFilter.all;

  ReviewFilter get filter => _filter;
  int get total => _results.length;
  int get wrongCount => _results.where((r) => !r.isCorrect).length;

  /// The filter only helps when some, but not all, answers were wrong.
  bool get showsFilter => wrongCount > 0 && wrongCount < total;

  /// (question number, result) pairs to show.
  List<(int, QuestionResult)> get visible => [
    for (final (i, r) in _results.indexed)
      if (_filter == ReviewFilter.all || !r.isCorrect) (i + 1, r),
  ];

  String labelFor(ReviewFilter f) =>
      f == ReviewFilter.all ? 'All $total' : 'Wrong $wrongCount';

  void select(ReviewFilter f) {
    if (f == _filter) return;
    _filter = f;
    notifyListeners();
  }
}
