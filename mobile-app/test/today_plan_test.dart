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

TodayPlan _plan({
  TodayLearningItem? next,
  List<TodayLearningItem> keepGoing = const [],
  List<TodayLearningItem> upcoming = const [],
}) => TodayPlan.fromOverview(
  TodayOverview(next: next, continueItems: keepGoing, upcoming: upcoming),
);

void main() {
  group('TodayPlan sections', () {
    test('not loaded gives the plain layout', () {
      final plan = TodayPlan.fromOverview(null);
      expect(plan.sections, [TodaySection.jumpBackIn, TodaySection.subjects]);
      expect(plan.heroItem, isNull);
      expect(plan.isCaughtUp, isFalse);
    });

    test('overdue work comes first, then to do, lessons, coming up', () {
      final plan = _plan(
        next: _item('assignment', 'overdue', title: 'Late one'),
        keepGoing: [_item('video', 'in-progress')],
        upcoming: [
          _item('assignment', 'overdue'),
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
          _item('assignment', 'returned'),
        ],
      );
      expect(plan.attention, isEmpty);
      expect(plan.todo, isEmpty);
      expect(plan.comingUp, isEmpty);
      expect(plan.sections, [TodaySection.subjects, TodaySection.jumpBackIn]);
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

    test('an untitled next step is ignored', () {
      final plan = _plan(next: _item('video', 'not-started', title: '  '));
      expect(plan.heroItem, isNull);
    });
  });

  group('TodayPlan focus', () {
    test('overdue wins, then to do, then coming up', () {
      expect(
        _plan(
          upcoming: [
            _item('assignment', 'overdue'),
            _item('assignment', 'overdue'),
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

    test('overdue count is the number of overdue items', () {
      final plan = _plan(
        upcoming: [
          _item('assignment', 'overdue'),
          _item('assignment', 'overdue'),
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
