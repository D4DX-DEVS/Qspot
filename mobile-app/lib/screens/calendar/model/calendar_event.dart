import 'package:intl/intl.dart';

import '../../../services/today_service.dart';
import 'calendar_event_kind.dart';

/// One dated entry on the Calendar: an assignment due, a quiz opening or
/// closing, a live class, or a lesson that opens later.
class CalendarEvent {
  const CalendarEvent({
    required this.kind,
    required this.id,
    required this.title,
    required this.action,
    this.subject = '',
    this.when,
    this.isOverdue = false,
    this.isPractical = false,
  });

  final CalendarEventKind kind;
  final String id;
  final String title;

  /// Short word for what happens at [when]: "Due", "Starts", "Live"...
  final String action;
  final String subject;

  /// Local time it happens. Null when nobody set a date.
  final DateTime? when;
  final bool isOverdue;

  /// A quiz that is a practical exam rather than a plain quiz.
  final bool isPractical;

  /// "Assignment", "Practical exam"... plus the subject when there is one.
  String get detail => [
    isPractical ? 'Practical exam' : kind.label,
    if (subject.isNotEmpty) subject,
  ].join(' · ');

  /// What to tell a learner who taps a lesson that has not opened yet.
  String get notOpenMessage {
    final opensAt = when;
    if (opensAt == null) return 'This lesson is not open yet.';
    return 'This lesson opens on ${DateFormat('EEE d MMM').format(opensAt)} '
        'at ${DateFormat('h:mm a').format(opensAt).toLowerCase()}.';
  }

  /// The entry for a Today item, or null for a kind the Calendar does not
  /// show.
  static CalendarEvent? fromItem(TodayLearningItem item) {
    final release = item.releaseAt?.toLocal();
    final due = item.dueAt?.toLocal();
    final CalendarEventKind kind;
    final String action;
    final DateTime? when;
    switch (item.kind) {
      case 'assignment':
        kind = CalendarEventKind.assignment;
        // Due is what matters; an assignment with no deadline sits at the
        // day it opened.
        action = due != null ? 'Due' : 'Opens';
        when = due ?? release;
      case 'quiz':
        kind = CalendarEventKind.quiz;
        // A quiz not open yet matters when it opens; an open one when it
        // closes.
        final notOpen = item.status == 'upcoming' && release != null;
        action = notOpen ? 'Starts' : 'Closes';
        when = notOpen ? release : (due ?? release);
      case 'schedule':
        kind = CalendarEventKind.liveClass;
        action = 'Live';
        when = release ?? due;
      case 'video':
        kind = CalendarEventKind.lesson;
        action = 'Opens';
        when = release ?? due;
      default:
        return null;
    }
    final overdue = item.status == 'overdue';
    return CalendarEvent(
      kind: kind,
      id: item.id,
      title: item.title.trim(),
      action: overdue ? 'Overdue' : action,
      subject: item.subject,
      when: when,
      isOverdue: overdue,
      isPractical:
          kind == CalendarEventKind.quiz && item.assessmentType == 'practical',
    );
  }
}
