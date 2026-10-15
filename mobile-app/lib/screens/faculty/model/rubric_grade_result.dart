/// What a teacher entered when marking by parts.
class RubricGradeResult {
  const RubricGradeResult({required this.points, required this.feedback});

  /// One score per part, in the rubric's order.
  final List<int> points;
  final String feedback;
}
