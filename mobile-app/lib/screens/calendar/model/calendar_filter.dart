import 'calendar_event_kind.dart';

/// Which entries the Calendar agenda shows.
enum CalendarFilter {
  all('All'),
  assignments('Assignments'),
  liveClasses('Live classes'),
  quizzes('Quizzes'),
  lessons('Lessons');

  const CalendarFilter(this.label);

  final String label;

  bool matches(CalendarEventKind kind) => switch (this) {
    CalendarFilter.all => true,
    CalendarFilter.assignments => kind == CalendarEventKind.assignment,
    CalendarFilter.liveClasses => kind == CalendarEventKind.liveClass,
    CalendarFilter.quizzes => kind == CalendarEventKind.quiz,
    CalendarFilter.lessons => kind == CalendarEventKind.lesson,
  };
}
