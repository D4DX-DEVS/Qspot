import 'package:flutter/foundation.dart';

import '../../assignment/model/rubric_score.dart';
import '../model/rubric_grade_result.dart';
import '../model/rubric_spec.dart';

/// The scores and feedback in the "mark by parts" dialog.
class RubricGradeProvider extends ChangeNotifier {
  RubricGradeProvider({
    required this.rubric,
    List<RubricScore> initialScores = const [],
    String feedback = '',
  }) : _scores = [
         for (var i = 0; i < rubric.parts.length; i++)
           i < initialScores.length &&
                   initialScores[i].points >= 0 &&
                   initialScores[i].points <= rubric.parts[i].maxPoints
               ? initialScores[i].points.round()
               : null,
       ],
       _feedback = feedback;

  final RubricSpec rubric;
  final List<int?> _scores;
  String _feedback;

  int? scoreFor(int index) => _scores[index];
  String get feedback => _feedback;
  int get total => _scores.fold(0, (sum, s) => sum + (s ?? 0));
  bool get isComplete => _scores.every((s) => s != null);

  void setScore(int index, int? value) {
    final max = rubric.parts[index].maxPoints;
    _scores[index] = value == null || value < 0 || value > max ? null : value;
    notifyListeners();
  }

  void setFeedback(String value) => _feedback = value;

  /// Null until every part has a score.
  RubricGradeResult? get result => isComplete
      ? RubricGradeResult(
          points: _scores.map((s) => s!).toList(),
          feedback: _feedback.trim(),
        )
      : null;
}
