/// What a grade was earned on.
enum GradeKind {
  /// An exam or quiz taken from the Practice tab.
  quiz('Quiz'),

  /// The questions at the end of a lesson.
  lessonPractice('Lesson Practice'),

  /// An assignment marked by a teacher.
  assignment('Assignment');

  const GradeKind(this.label);

  final String label;
}
