import 'package:flutter_test/flutter_test.dart';
import 'package:qspot/screens/home/model/today_item_text.dart';
import 'package:qspot/screens/home/model/today_plan.dart';
import 'package:qspot/screens/home/model/today_section.dart';
import 'package:qspot/services/today_service.dart';

TodayLearningItem _item(
  String kind,
  String status, {
  String id = 'x',
  String title = 'Item',
  DateTime? releaseAt,
  DateTime? dueAt,
}) => TodayLearningItem(
  kind: kind,
  id: id,
  title: title,
  status: status,
  releaseAt: releaseAt,
  dueAt: dueAt,
);

final _now = DateTime(2026, 10, 2, 17, 30);
final _soon = _now.add(const Duration(minutes: 30));
final _later = _now.add(const Duration(hours: 2));

TodayPlan _plan({
  TodayLearningItem? next,
  List<TodayLearningItem> keepGoing = const [],
  List<TodayLearningItem> upcoming = const [],
}) => TodayPlan.fromOverview(
  TodayOverview(next: next, continueItems: keepGoing, upcoming: upcoming),
  now: _now,
);

void main() {
  group('TodayPlan sections', () {
    test('not loaded gives the plain layout', () {
      final plan = TodayPlan.fromOverview(null);
      expect(plan.sections, [TodaySection.jumpBackIn, TodaySection.subjects]);
      expect(plan.heroItem, isNull);
      expect(plan.isCaughtUp, isFalse);
    });

    test('work ending within the hour comes first, then to do, lessons, '
        'coming up', () {
      final plan = _plan(
        next: _item('assignment', 'upcoming', title: 'Soon one'),
        keepGoing: [_item('video', 'in-progress')],
        upcoming: [
          _item('assignment', 'upcoming', id: 'soon', dueAt: _soon),
          _item('assignment', 'upcoming'),
          _item('schedule', 'upcoming'),
        ],
      );
      expect(plan.sections, [
        TodaySection.attention,
        TodaySection.todo,
        TodaySection.jumpBackIn,
        TodaySection.comingUp,
        TodaySection.subjects,
      ]);
      expect(plan.attention, hasLength(1));
      expect(plan.todo, hasLength(1));
      expect(plan.comingUp, hasLength(1));
    });

    test('a learner with nothing pending sees only lessons and subjects', () {
      final plan = _plan(
        next: _item('video', 'not-started', title: 'Next lesson'),
      );
      expect(plan.sections, [TodaySection.subjects, TodaySection.jumpBackIn]);
      expect(plan.heroItem?.title, 'Next lesson');
      expect(plan.isCaughtUp, isFalse);
    });

    test('lessons in progress rank above what is coming up', () {
      final plan = _plan(
        keepGoing: [_item('video', 'in-progress')],
        upcoming: [_item('schedule', 'upcoming')],
      );
      expect(plan.sections, [
        TodaySection.jumpBackIn,
        TodaySection.comingUp,
        TodaySection.subjects,
      ]);
    });

    test('a quiz already started goes to the top of the to-do list', () {
      final plan = _plan(
        keepGoing: [_item('quiz', 'live', id: 'started')],
        upcoming: [
          _item('assignment', 'upcoming', id: 'a'),
          _item('quiz', 'live', id: 'q'),
        ],
      );
      expect(plan.todo.map((item) => item.id), ['started', 'a', 'q']);
      expect(plan.sections.first, TodaySection.todo);
    });

    test('filters completed continuations and de-duplicates API lists', () {
      final plan = _plan(
        next: _item('assignment', 'upcoming', id: 'a'),
        keepGoing: [
          _item('quiz', 'graded', id: 'done'),
          _item('quiz', 'live', id: 'q'),
        ],
        upcoming: [
          _item('quiz', 'live', id: 'q'),
          _item('assignment', 'upcoming', id: 'a'),
        ],
      );
      expect(plan.attention, isEmpty);
      expect(plan.todo.map((item) => item.id), ['q', 'a']);
    });

    test(
      'quizzes that have not opened yet and lessons wait under coming up',
      () {
        final plan = _plan(
          upcoming: [
            _item('quiz', 'upcoming'),
            _item('video', 'upcoming'),
            _item('schedule', 'upcoming'),
          ],
        );
        expect(plan.todo, isEmpty);
        expect(plan.comingUp, hasLength(3));
      },
    );

    test('work already handed in is not listed', () {
      final plan = _plan(
        upcoming: [
          _item('assignment', 'submitted'),
          _item('assignment', 'late'),
          _item('assignment', 'graded'),
        ],
      );
      expect(plan.attention, isEmpty);
      expect(plan.todo, isEmpty);
      expect(plan.comingUp, isEmpty);
      expect(plan.sections, [TodaySection.subjects, TodaySection.jumpBackIn]);
    });

    test('work returned for changes is to do again', () {
      expect(TodayPlan.doneStatuses.contains('returned'), isFalse);
    });

    test('past-due work is not listed anywhere', () {
      final plan = _plan(
        upcoming: [
          _item('assignment', 'overdue', id: 'late'),
          _item('assignment', 'upcoming', id: 'a', dueAt: _later),
        ],
      );
      expect(plan.attention, isEmpty);
      expect(plan.todo.map((item) => item.id), ['a']);
    });

    test('only work ending within the hour needs attention', () {
      final plan = _plan(
        keepGoing: [_item('quiz', 'live', id: 'started', dueAt: _soon)],
        upcoming: [
          _item('assignment', 'upcoming', id: 'soon', dueAt: _soon),
          _item('assignment', 'upcoming', id: 'later', dueAt: _later),
          _item('quiz', 'live', id: 'q', dueAt: _soon),
          _item('quiz', 'upcoming', id: 'notOpen', dueAt: _soon),
        ],
      );
      expect(plan.attention.map((item) => item.id), ['started', 'soon', 'q']);
      expect(plan.todo.map((item) => item.id), ['later']);
      expect(plan.comingUp.map((item) => item.id), ['notOpen']);
    });

    test('work sent back for changes after its deadline stays to do', () {
      final plan = _plan(
        upcoming: [
          _item(
            'assignment',
            'returned',
            dueAt: _now.subtract(const Duration(days: 1)),
          ),
        ],
      );
      expect(plan.attention, isEmpty);
      expect(plan.todo, hasLength(1));
    });
  });

  group('TodayPlan hero', () {
    test('nothing left to do is caught up', () {
      final plan = _plan();
      expect(plan.heroItem, isNull);
      expect(plan.isCaughtUp, isTrue);
    });

    test('a handed-in assignment is never the next step', () {
      final plan = _plan(next: _item('assignment', 'graded'));
      expect(plan.heroItem, isNull);
      expect(plan.isCaughtUp, isTrue);
    });

    test('past-due work is never the next step', () {
      final plan = _plan(
        next: _item('assignment', 'overdue', id: 'late'),
        upcoming: [_item('assignment', 'overdue', id: 'late')],
      );
      expect(plan.heroItem, isNull);
      expect(plan.isCaughtUp, isTrue);
    });

    test('work ending within the hour beats the server pick', () {
      final plan = _plan(
        next: _item('quiz', 'live', id: 'q'),
        upcoming: [
          _item('quiz', 'live', id: 'q'),
          _item('assignment', 'upcoming', id: 'soon', dueAt: _soon),
        ],
      );
      expect(plan.heroItem?.id, 'soon');
    });

    test('missing next does not hide work ending soon', () {
      final plan = _plan(
        upcoming: [_item('assignment', 'upcoming', id: 'soon', dueAt: _soon)],
      );
      expect(plan.isCaughtUp, isFalse);
      expect(plan.attention, hasLength(1));
      expect(plan.heroItem?.id, 'soon');
    });

    test('does not promote an untitled fallback item into the hero', () {
      final plan = _plan(
        upcoming: [_item('assignment', 'upcoming', title: '  ', dueAt: _soon)],
      );
      expect(plan.heroItem, isNull);
      expect(plan.isCaughtUp, isFalse);
    });

    test('an untitled next step is ignored', () {
      final plan = _plan(next: _item('video', 'not-started', title: '  '));
      expect(plan.heroItem, isNull);
    });
  });

  group('TodayPlan focus', () {
    test('ending soon wins, then to do, then coming up', () {
      expect(
        _plan(
          upcoming: [
            _item('assignment', 'upcoming', id: 's1', dueAt: _soon),
            _item('assignment', 'upcoming', id: 's2', dueAt: _soon),
            _item('assignment', 'upcoming'),
          ],
        ).focus,
        TodaySection.attention,
      );
      final todo = _plan(
        upcoming: [
          _item('assignment', 'upcoming'),
          _item('schedule', 'upcoming'),
        ],
      );
      expect(todo.focus, TodaySection.todo);
      expect(todo.focusCount, 1);
      final coming = _plan(upcoming: [_item('schedule', 'upcoming')]);
      expect(coming.focus, TodaySection.comingUp);
      expect(coming.focusCount, 1);
      expect(_plan().focusCount, 0);
    });

    test('ending-soon count is the number of items ending soon', () {
      final plan = _plan(
        upcoming: [
          _item('assignment', 'upcoming', id: 's1', dueAt: _soon),
          _item('assignment', 'upcoming', id: 's2', dueAt: _soon),
        ],
      );
      expect(plan.focusCount, 2);
    });
  });

  group('TodayItemText.metaText', () {
    final now = DateTime(2026, 10, 2, 17, 30);

    test('overdue always says so', () {
      expect(
        _item(
          'assignment',
          'overdue',
          dueAt: DateTime(2026, 9, 1),
        ).metaText(now),
        'Past Due - Handle Now',
      );
    });

    test('less than an hour left says how many minutes', () {
      expect(
        _item(
          'assignment',
          'upcoming',
          dueAt: now.add(const Duration(minutes: 30)),
        ).metaText(now),
        'Ends in 30 Min',
      );
    });

    test('due today, tomorrow and later', () {
      expect(
        _item(
          'assignment',
          'upcoming',
          dueAt: DateTime(2026, 10, 2, 23),
        ).metaText(now),
        'Due Today',
      );
      expect(
        _item(
          'assignment',
          'upcoming',
          dueAt: DateTime(2026, 10, 3, 9),
        ).metaText(now),
        'Due Tomorrow',
      );
      expect(
        _item(
          'assignment',
          'upcoming',
          dueAt: DateTime(2026, 10, 9),
        ).metaText(now),
        'Due 9/10',
      );
    });

    test('a quiz not open yet says when it starts, not when it is due', () {
      final quiz = _item(
        'quiz',
        'upcoming',
        releaseAt: DateTime(2026, 10, 3),
        dueAt: DateTime(2026, 10, 10),
      );
      expect(quiz.metaText(now), 'Starts Tomorrow');
    });

    test('a live quiz shows its deadline', () {
      final quiz = _item(
        'quiz',
        'live',
        releaseAt: DateTime(2026, 9, 30),
        dueAt: DateTime(2026, 10, 10),
      );
      expect(quiz.metaText(now), 'Due 10/10');
    });

    test('sessions are live and lessons are available', () {
      expect(
        _item(
          'schedule',
          'upcoming',
          releaseAt: DateTime(2026, 10, 2, 19),
        ).metaText(now),
        'Live Today',
      );
      expect(
        _item(
          'video',
          'upcoming',
          releaseAt: DateTime(2026, 10, 3),
        ).metaText(now),
        'Available Tomorrow',
      );
    });

    test('items without dates fall back to a plain line', () {
      expect(_item('quiz', 'live').metaText(now), 'Ready to Practice');
      expect(_item('video', 'upcoming').metaText(now), 'Open When Ready');
    });
  });
}
