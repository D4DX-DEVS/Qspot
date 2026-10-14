import 'grade_kind.dart';

/// One mark a learner has earned: a quiz, the practice questions of a lesson
/// or an assignment a teacher has marked.
class GradeEntry {
  const GradeEntry({
    required this.kind,
    required this.title,
    required this.score,
    required this.outOf,
    this.date,
    this.videoId,
    this.subjectId,
    this.courseId,
    this.feedback = '',
  });

  final GradeKind kind;
  final String title;
  final num score;
  final num outOf;

  /// When it was earned.
  final DateTime? date;

  /// For lesson practice: the lesson it belongs to.
  final String? videoId;

  /// For an assignment: the chapter and course the teacher linked it to.
  final String? subjectId;
  final String? courseId;

  /// The teacher's comment on an assignment.
  final String feedback;

  /// 0 to 100.
  double get percent =>
      outOf <= 0 ? 0 : (score / outOf * 100).clamp(0, 100).toDouble();

  String get percentLabel => '${percent.round()}%';

  /// "8/10", or "82.5/100" when the mark is not a whole number.
  String get scoreLabel => '${_points(score)}/${_points(outOf)}';

  static String _points(num value) =>
      value % 1 == 0 ? '${value.toInt()}' : value.toStringAsFixed(1);
}
