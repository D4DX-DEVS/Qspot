import 'package:flutter_test/flutter_test.dart';
import 'package:qspot/screens/calendar/model/calendar_agenda.dart';
import 'package:qspot/screens/calendar/model/calendar_dates.dart';
import 'package:qspot/screens/calendar/model/calendar_event.dart';
import 'package:qspot/screens/calendar/model/calendar_event_kind.dart';
import 'package:qspot/screens/calendar/model/calendar_filter.dart';
import 'package:qspot/screens/calendar/provider/calendar_provider.dart';
import 'package:qspot/services/today_service.dart';

/// Wednesday 14 October 2026, 10:00 on the phone.
final _now = DateTime(2026, 10, 14, 10);

TodayLearningItem _item(
  String kind,
  String id, {
  String title = '',
  String status = 'upcoming',
  String subject = '',
  DateTime? releaseAt,
  DateTime? dueAt,
  String assessmentType = 'quiz',
}) => TodayLearningItem(
  kind: kind,
  id: id,
  title: title.isEmpty ? 'Item $id' : title,
  status: status,
  subject: subject,
  releaseAt: releaseAt,
  dueAt: dueAt,
  assessmentType: assessmentType,
);

TodayOverview _overview(
  List<TodayLearningItem> upcoming, {
  List<TodayLearningItem> continueItems = const [],
}) => TodayOverview(upcoming: upcoming, continueItems: continueItems);

void main() {
  group('CalendarDates', () {
    test('a week starts on Monday', () {
      expect(DateTime(2026, 10, 14, 15).weekStart, DateTime(2026, 10, 12));
      expect(DateTime(2026, 10, 12).weekStart, DateTime(2026, 10, 12));
      // Sunday belongs to the week before it.
      expect(DateTime(2026, 10, 18).weekStart, DateTime(2026, 10, 12));
    });

    test('a week can start in the month before', () {
      expect(DateTime(2026, 11, 1).weekStart, DateTime(2026, 10, 26));
      expect(DateTime(2027, 1, 1).weekStart, DateTime(2026, 12, 28));
    });

    test('adding days rolls over months and compares by day', () {
      expect(DateTime(2026, 10, 30).plusDays(3), DateTime(2026, 11, 2));
      expect(
        DateTime(2026, 10, 14, 23, 59).isSameDay(DateTime(2026, 10, 14, 0, 1)),
        isTrue,
      );
      expect(DateTime(2026, 10, 14).isSameDay(DateTime(2026, 11, 14)), isFalse);
    });
  });

  group('CalendarEvent', () {
    test('an assignment sits on its due time', () {
      final event = CalendarEvent.fromItem(
        _item(
          'assignment',
          'a1',
          title: ' Steps of wudu ',
          releaseAt: DateTime(2026, 10, 1, 9),
          dueAt: DateTime(2026, 10, 14, 18),
        ),
      )!;

      expect(event.kind, CalendarEventKind.assignment);
      expect(event.title, 'Steps of wudu');
      expect(event.action, 'Due');
      expect(event.when, DateTime(2026, 10, 14, 18));
      expect(event.detail, 'Assignment');
    });

    test('an assignment with no deadline sits on the day it opened', () {
      final event = CalendarEvent.fromItem(
        _item('assignment', 'a1', releaseAt: DateTime(2026, 10, 15, 9)),
      )!;

      expect(event.action, 'Opens');
      expect(event.when, DateTime(2026, 10, 15, 9));
    });

    test('a past-due assignment is marked overdue', () {
      final event = CalendarEvent.fromItem(
        _item(
          'assignment',
          'a1',
          status: 'overdue',
          dueAt: DateTime(2026, 10, 10, 18),
        ),
      )!;

      expect(event.isOverdue, isTrue);
      expect(event.action, 'Overdue');
    });

    test('a quiz not open yet sits on its start, an open one on its end', () {
      final notOpen = CalendarEvent.fromItem(
        _item(
          'quiz',
          'q1',
          releaseAt: DateTime(2026, 10, 16, 9),
          dueAt: DateTime(2026, 10, 20, 9),
        ),
      )!;
      final open = CalendarEvent.fromItem(
        _item(
          'quiz',
          'q2',
          status: 'live',
          releaseAt: DateTime(2026, 10, 10, 9),
          dueAt: DateTime(2026, 10, 20, 9),
        ),
      )!;

      expect(notOpen.action, 'Starts');
      expect(notOpen.when, DateTime(2026, 10, 16, 9));
      expect(open.action, 'Closes');
      expect(open.when, DateTime(2026, 10, 20, 9));
    });

    test('a practical exam says so', () {
      final event = CalendarEvent.fromItem(
        _item('quiz', 'q1', assessmentType: 'practical'),
      )!;

      expect(event.isPractical, isTrue);
      expect(event.detail, 'Practical exam');
    });

    test('a live class and a lesson that opens later', () {
      final live = CalendarEvent.fromItem(
        _item('schedule', 's1', releaseAt: DateTime(2026, 10, 15, 19)),
      )!;
      final lesson = CalendarEvent.fromItem(
        _item(
          'video',
          'v1',
          subject: 'Tajweed',
          releaseAt: DateTime(2026, 10, 16, 6),
        ),
      )!;

      expect(live.kind, CalendarEventKind.liveClass);
      expect(live.action, 'Live');
      expect(lesson.kind, CalendarEventKind.lesson);
      expect(lesson.action, 'Opens');
      expect(lesson.detail, 'Lesson · Tajweed');
    });

    test('a kind the Calendar does not know is skipped', () {
      expect(CalendarEvent.fromItem(_item('mystery', 'x')), isNull);
    });

    test('tells a learner when a lesson opens', () {
      final lesson = CalendarEvent.fromItem(
        _item('video', 'v1', releaseAt: DateTime(2026, 10, 16, 6)),
      )!;
      final undated = CalendarEvent.fromItem(_item('video', 'v2'))!;

      expect(
        lesson.notOpenMessage,
        'This lesson opens on Fri 16 Oct at 6:00 am.',
      );
      expect(undated.notOpenMessage, 'This lesson is not open yet.');
    });
  });

  group('CalendarAgenda', () {
    test('no overview means an empty agenda', () {
      expect(CalendarAgenda.fromOverview(null).isEmpty, isTrue);
    });

    test('leaves out work already handed in', () {
      final agenda = CalendarAgenda.fromOverview(
        _overview([
          for (final status in ['submitted', 'late', 'graded'])
            _item(
              'assignment',
              status,
              status: status,
              dueAt: DateTime(2026, 10, 15),
            ),
          _item('assignment', 'open', dueAt: DateTime(2026, 10, 15)),
        ]),
      );

      expect(agenda.events.map((e) => e.id), ['open']);
    });

    test('adds a quiz the learner has started, but not a lesson', () {
      final agenda = CalendarAgenda.fromOverview(
        _overview(
          [_item('assignment', 'a1', dueAt: DateTime(2026, 10, 15))],
          continueItems: [
            _item('quiz', 'q1', status: 'live', dueAt: DateTime(2026, 10, 16)),
            _item('video', 'v1', status: 'in-progress'),
          ],
        ),
      );

      expect(agenda.events.map((e) => e.id), ['a1', 'q1']);
    });

    test('shows the same item once', () {
      final agenda = CalendarAgenda.fromOverview(
        _overview(
          [_item('quiz', 'q1', releaseAt: DateTime(2026, 10, 16))],
          continueItems: [
            _item('quiz', 'q1', status: 'live', dueAt: DateTime(2026, 10, 18)),
          ],
        ),
      );

      expect(agenda.events, hasLength(1));
    });

    test('lists the soonest first and undated last', () {
      final agenda = CalendarAgenda.fromOverview(
        _overview([
          _item('assignment', 'undated'),
          _item('schedule', 'later', releaseAt: DateTime(2026, 10, 20, 9)),
          _item('schedule', 'sooner', releaseAt: DateTime(2026, 10, 15, 9)),
        ]),
      );

      expect(agenda.events.map((e) => e.id), ['sooner', 'later', 'undated']);
    });

    test('groups by day with Today and Tomorrow named', () {
      final agenda = CalendarAgenda.fromOverview(
        _overview([
          _item('assignment', 'a1', dueAt: DateTime(2026, 10, 14, 18)),
          _item('schedule', 's1', releaseAt: DateTime(2026, 10, 15, 19)),
          _item('quiz', 'q1', releaseAt: DateTime(2026, 10, 15, 21)),
          _item('assignment', 'a2', dueAt: DateTime(2026, 10, 19, 23, 59)),
        ]),
      );

      final sections = agenda.sections(now: _now);

      expect(sections.map((s) => s.title), [
        'TODAY · WED 14 OCT',
        'TOMORROW · THU 15 OCT',
        'MON 19 OCT',
      ]);
      expect(sections[1].events.map((e) => e.id), ['s1', 'q1']);
    });

    test('puts overdue work first and undated work last', () {
      final agenda = CalendarAgenda.fromOverview(
        _overview([
          _item('assignment', 'undated'),
          _item(
            'assignment',
            'late',
            status: 'overdue',
            dueAt: DateTime(2026, 10, 9),
          ),
          _item('schedule', 's1', releaseAt: DateTime(2026, 10, 15, 19)),
        ]),
      );

      final sections = agenda.sections(now: _now);

      expect(sections.first.title, 'OVERDUE');
      expect(sections.first.isOverdue, isTrue);
      expect(sections.first.events.single.id, 'late');
      expect(sections.last.title, 'NO DATE');
      expect(sections.last.events.single.id, 'undated');
      expect(sections, hasLength(3));
    });

    test('a filter keeps only that kind', () {
      final agenda = CalendarAgenda.fromOverview(
        _overview([
          _item('assignment', 'a1', dueAt: DateTime(2026, 10, 14, 18)),
          _item('schedule', 's1', releaseAt: DateTime(2026, 10, 15, 19)),
        ]),
      );

      final sections = agenda.sections(
        now: _now,
        filter: CalendarFilter.liveClasses,
      );

      expect(sections.single.events.single.id, 's1');
    });

    test('a chosen day shows only that day, or nothing', () {
      final agenda = CalendarAgenda.fromOverview(
        _overview([
          _item('assignment', 'a1', dueAt: DateTime(2026, 10, 14, 18)),
          _item('schedule', 's1', releaseAt: DateTime(2026, 10, 15, 19)),
        ]),
      );

      final thursday = agenda.sections(now: _now, day: DateTime(2026, 10, 15));
      final friday = agenda.sections(now: _now, day: DateTime(2026, 10, 16));

      expect(thursday.single.title, 'TOMORROW · THU 15 OCT');
      expect(thursday.single.events.single.id, 's1');
      expect(friday, isEmpty);
    });

    test('dots show each kind once, in a fixed order', () {
      final agenda = CalendarAgenda.fromOverview(
        _overview([
          _item('schedule', 's1', releaseAt: DateTime(2026, 10, 15, 9)),
          _item('assignment', 'a1', dueAt: DateTime(2026, 10, 15, 12)),
          _item('assignment', 'a2', dueAt: DateTime(2026, 10, 15, 18)),
        ]),
      );
      final day = DateTime(2026, 10, 15);

      expect(agenda.kindsOn(day, CalendarFilter.all), [
        CalendarEventKind.assignment,
        CalendarEventKind.liveClass,
      ]);
      expect(agenda.kindsOn(day, CalendarFilter.quizzes), isEmpty);
      expect(
        agenda.kindsOn(DateTime(2026, 10, 16), CalendarFilter.all),
        isEmpty,
      );
    });

    test('knows whether anything is left on or after a day', () {
      final agenda = CalendarAgenda.fromOverview(
        _overview([
          _item('schedule', 's1', releaseAt: DateTime(2026, 10, 20, 9)),
        ]),
      );

      expect(agenda.hasEventOnOrAfter(DateTime(2026, 10, 20)), isTrue);
      expect(agenda.hasEventOnOrAfter(DateTime(2026, 10, 21)), isFalse);
    });
  });

  group('CalendarProvider', () {
    CalendarProvider make({
      Future<TodayOverview?> Function()? fetch,
      DateTime? now,
    }) => CalendarProvider(
      fetch: fetch ?? () async => _overview(const []),
      clock: () => now ?? _now,
    );

    final later = _overview([
      _item('assignment', 'a1', dueAt: DateTime(2026, 10, 14, 18)),
      _item('schedule', 's1', releaseAt: DateTime(2026, 10, 15, 19)),
      _item('quiz', 'q1', releaseAt: DateTime(2026, 10, 27, 9)),
    ]);

    test('starts on the week that holds today', () {
      final provider = make();

      expect(provider.weekDays.first, DateTime(2026, 10, 12));
      expect(provider.weekDays.last, DateTime(2026, 10, 18));
      expect(provider.weekDays, hasLength(7));
      expect(provider.weekLabel, 'October 2026');
      expect(provider.isToday(DateTime(2026, 10, 14)), isTrue);
      expect(provider.isToday(DateTime(2026, 10, 15)), isFalse);
    });

    test('names both months when a week crosses them', () {
      expect(make(now: DateTime(2026, 10, 28)).weekLabel, 'Oct – Nov 2026');
      expect(
        make(now: DateTime(2026, 12, 30)).weekLabel,
        'Dec 2026 – Jan 2027',
      );
    });

    test(
      'weeks can move forward only while something is dated later',
      () async {
        final provider = make(fetch: () async => later);
        await provider.load();

        expect(provider.canGoBack, isFalse);
        expect(provider.canGoForward, isTrue);

        provider.showNextWeek();
        expect(provider.weekDays.first, DateTime(2026, 10, 19));
        expect(provider.canGoBack, isTrue);
        expect(provider.canGoForward, isTrue);

        provider.showNextWeek();
        expect(provider.weekDays.first, DateTime(2026, 10, 26));
        // Nothing is dated after the week of the 27th.
        expect(provider.canGoForward, isFalse);
        provider.showNextWeek();
        expect(provider.weekDays.first, DateTime(2026, 10, 26));

        provider.showPreviousWeek();
        provider.showPreviousWeek();
        expect(provider.weekDays.first, DateTime(2026, 10, 12));
        provider.showPreviousWeek();
        expect(provider.weekDays.first, DateTime(2026, 10, 12));
      },
    );

    test('tapping a day chooses it, and again shows every day', () async {
      final provider = make(fetch: () async => later);
      await provider.load();
      expect(provider.sections, hasLength(3));

      provider.toggleDay(DateTime(2026, 10, 15, 13));
      expect(provider.isSelected(DateTime(2026, 10, 15)), isTrue);
      expect(provider.sections.single.events.single.id, 's1');

      provider.toggleDay(DateTime(2026, 10, 15));
      expect(provider.selectedDay, isNull);
      expect(provider.sections, hasLength(3));
    });

    test('changing week drops the chosen day', () async {
      final provider = make(fetch: () async => later);
      await provider.load();
      provider.toggleDay(DateTime(2026, 10, 15));

      provider.showNextWeek();

      expect(provider.selectedDay, isNull);
    });

    test('a filter narrows both the agenda and the dots', () async {
      final provider = make(fetch: () async => later);
      await provider.load();
      final day = DateTime(2026, 10, 15);
      expect(provider.kindsOn(day), [CalendarEventKind.liveClass]);

      provider.selectFilter(CalendarFilter.assignments);

      expect(provider.kindsOn(day), isEmpty);
      expect(provider.sections.single.events.single.id, 'a1');
    });

    test('shows a skeleton only on the first load', () async {
      final provider = make(fetch: () async => later);
      final seen = <bool>[];
      provider.addListener(() => seen.add(provider.showSkeleton));

      await provider.load();
      await provider.load();

      expect(seen.first, isTrue);
      expect(seen.skip(2).any((value) => value), isFalse);
    });

    test('nothing dated reads as empty, not as an error', () async {
      final provider = make();
      expect(provider.isEmpty, isFalse);

      await provider.load();

      expect(provider.isEmpty, isTrue);
      expect(provider.showError, isFalse);
    });

    test('a failed load shows an error until a retry works', () async {
      var attempts = 0;
      final provider = make(
        fetch: () async {
          attempts++;
          if (attempts == 1) throw Exception('offline');
          return later;
        },
      );

      await provider.load();
      expect(provider.showError, isTrue);

      await provider.load();
      expect(provider.showError, isFalse);
      expect(provider.agenda.events, hasLength(3));
    });

    test('a failed refresh keeps what was already loaded', () async {
      var fail = false;
      final provider = make(
        fetch: () async {
          if (fail) throw Exception('offline');
          return later;
        },
      );
      await provider.load();

      fail = true;
      await provider.load();

      expect(provider.showError, isFalse);
      expect(provider.agenda.events, hasLength(3));
    });
  });
}
