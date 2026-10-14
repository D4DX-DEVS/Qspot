import 'grade_kind.dart';

/// Which grades the My Grades list shows.
enum GradeFilter {
  all('All'),
  quizzes('Quizzes'),
  lessons('Lessons'),
  assignments('Assignments');

  const GradeFilter(this.label);

  final String label;

  bool matches(GradeKind kind) => switch (this) {
    GradeFilter.all => true,
    GradeFilter.quizzes => kind == GradeKind.quiz,
    GradeFilter.lessons => kind == GradeKind.lessonPractice,
    GradeFilter.assignments => kind == GradeKind.assignment,
  };
}
