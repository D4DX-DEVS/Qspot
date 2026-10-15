/// What a calendar entry is. Decides its icon-free label, its colour and
/// which filter chip it falls under.
enum CalendarEventKind {
  assignment('Assignment'),
  quiz('Quiz'),
  liveClass('Live class'),
  lesson('Lesson');

  const CalendarEventKind(this.label);

  final String label;
}
