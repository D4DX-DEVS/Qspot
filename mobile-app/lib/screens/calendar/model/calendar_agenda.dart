import 'package:intl/intl.dart';

import '../../../services/today_service.dart';
import '../../home/model/today_plan.dart';
import 'calendar_dates.dart';
import 'calendar_event.dart';
import 'calendar_event_kind.dart';
import 'calendar_filter.dart';
import 'calendar_section.dart';

/// Everything dated that the learner still has to do, built from the same
/// overview Today loads, and the ways the Calendar reads it: grouped by day,
/// and which kinds fall on a day.
class CalendarAgenda {
  const CalendarAgenda(this.events);

  const CalendarAgenda.empty() : events = const [];

  /// Soonest first; entries with no date come last.
  final List<CalendarEvent> events;

  bool get isEmpty => events.isEmpty;

  /// Work already handed in is left out, like on Today. A quiz the learner
  /// has started sits in `continue` rather than `upcoming`, so both are read.
  factory CalendarAgenda.fromOverview(TodayOverview? overview) {
    if (overview == null) return const CalendarAgenda.empty();
    final seen = <String>{};
    final events = <CalendarEvent>[];
    final items = [
      for (final item in overview.continueItems)
        if (item.kind == 'quiz') item,
      ...overview.upcoming,
    ];
    for (final item in items) {
      if (TodayPlan.doneStatuses.contains(item.status)) continue;
      if (item.id.isNotEmpty && !seen.add('${item.kind}:${item.id}')) continue;
      final event = CalendarEvent.fromItem(item);
      if (event != null && event.title.isNotEmpty) events.add(event);
    }
    events.sort(_soonestFirst);
    return CalendarAgenda(events);
  }

  static int _soonestFirst(CalendarEvent a, CalendarEvent b) {
    final aWhen = a.when;
    final bWhen = b.when;
    if (aWhen == null && bWhen == null) return a.title.compareTo(b.title);
    if (aWhen == null) return 1;
    if (bWhen == null) return -1;
    final byTime = aWhen.compareTo(bWhen);
    return byTime != 0 ? byTime : a.title.compareTo(b.title);
  }

  /// The kinds with an entry on [day], each once, for the dots under it.
  List<CalendarEventKind> kindsOn(DateTime day, CalendarFilter filter) {
    final kinds = {
      for (final event in events)
        if (filter.matches(event.kind) && _isOn(event, day)) event.kind,
    };
    return [
      for (final kind in CalendarEventKind.values)
        if (kinds.contains(kind)) kind,
    ];
  }

  /// Whether anything happens on or after [day].
  bool hasEventOnOrAfter(DateTime day) {
    final start = day.dayOnly;
    return events.any((event) {
      final when = event.when;
      return when != null && !when.dayOnly.isBefore(start);
    });
  }

  /// The agenda the screen lists: overdue work first, then each day with
  /// something on it, then work with no date. With [day] set, only that day.
  List<CalendarSection> sections({
    required DateTime now,
    CalendarFilter filter = CalendarFilter.all,
    DateTime? day,
  }) {
    final shown = [
      for (final event in events)
        if (filter.matches(event.kind)) event,
    ];
    if (day != null) {
      final onDay = [
        for (final event in shown)
          if (_isOn(event, day)) event,
      ];
      return onDay.isEmpty
          ? const []
          : [CalendarSection(title: dayTitle(day, now), events: onDay)];
    }

    final overdue = [
      for (final event in shown)
        if (event.isOverdue) event,
    ];
    final undated = [
      for (final event in shown)
        if (!event.isOverdue && event.when == null) event,
    ];
    final byDay = <DateTime, List<CalendarEvent>>{};
    for (final event in shown) {
      final when = event.when;
      if (event.isOverdue || when == null) continue;
      byDay.putIfAbsent(when.dayOnly, () => []).add(event);
    }
    return [
      if (overdue.isNotEmpty)
        CalendarSection(title: 'OVERDUE', events: overdue, isOverdue: true),
      for (final entry in byDay.entries)
        CalendarSection(title: dayTitle(entry.key, now), events: entry.value),
      if (undated.isNotEmpty)
        CalendarSection(title: 'NO DATE', events: undated),
    ];
  }

  /// "TODAY · TUE 13 OCT", "TOMORROW · WED 14 OCT" or "THU 15 OCT".
  static String dayTitle(DateTime day, DateTime now) {
    final label = DateFormat('EEE d MMM').format(day).toUpperCase();
    if (day.isSameDay(now)) return 'TODAY · $label';
    if (day.isSameDay(now.plusDays(1))) return 'TOMORROW · $label';
    return label;
  }

  static bool _isOn(CalendarEvent event, DateTime day) {
    final when = event.when;
    return when != null && when.isSameDay(day);
  }
}
