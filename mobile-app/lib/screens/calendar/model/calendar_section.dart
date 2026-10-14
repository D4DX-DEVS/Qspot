import 'calendar_event.dart';

/// A heading and the entries under it, e.g. "TODAY · TUE 13 OCT". The
/// overdue block is marked so the screen can colour its heading.
class CalendarSection {
  const CalendarSection({
    required this.title,
    required this.events,
    this.isOverdue = false,
  });

  final String title;
  final List<CalendarEvent> events;
  final bool isOverdue;
}
