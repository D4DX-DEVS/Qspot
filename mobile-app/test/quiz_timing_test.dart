import 'package:flutter_test/flutter_test.dart';
import 'package:qspot/screens/quiz/model/question_timing.dart';
import 'package:qspot/screens/quiz/provider/quiz_timing_tracker.dart';

final _t0 = DateTime(2026, 10, 14, 10);
DateTime _at(int seconds) => _t0.add(Duration(seconds: seconds));

/// Per-question timing and the deadlines worked out from it.
void main() {
  group('QuestionTiming', () {
    test('time on screen adds up over visits', () {
      final t = const QuestionTiming()
          .shown(_at(0))
          .hidden(_at(10))
          .shown(_at(30))
          .hidden(_at(35));
      expect(t.spentMs, 15000);
      expect(t.firstShownAt, _at(0));
      expect(t.visibleSince, isNull);
    });

    test('background time is not time on screen', () {
      final t = const QuestionTiming()
          .shown(_at(0))
          .hidden(_at(5)) // app to background
          .resumed(_at(65)) // back a minute later
          .hidden(_at(70));
      expect(t.spentMs, 10000);
    });

    test(
      'time taken is the time on screen when the final answer was picked',
      () {
        final t = const QuestionTiming()
            .shown(_at(0))
            .answered(_at(3), previous: null, choice: 1)
            .answered(_at(4), previous: 1, choice: 1) // same option: no change
            .answered(_at(6), previous: 1, choice: 2)
            .hidden(_at(20));
        expect(t.timeTakenMs, 6000);
        expect(t.spentMs, 20000);
      },
    );

    test('an unanswered question took its time on screen', () {
      final t = const QuestionTiming().shown(_at(0)).hidden(_at(12));
      expect(t.timeTakenMs, 12000);
    });

    test('a question whose time ran out took its full limit', () {
      // On screen only 5 s before the app went to the background.
      final t = const QuestionTiming()
          .shown(_at(0))
          .hidden(_at(5))
          .expiredAt(_at(30), limitMs: 30000);
      expect(t.timedOut, isTrue);
      expect(t.timeTakenMs, 30000);
    });

    test('an answer picked in time keeps its time when the clock runs out', () {
      final t = const QuestionTiming()
          .shown(_at(0))
          .answered(_at(8), previous: null, choice: 0)
          .expiredAt(_at(30), limitMs: 30000);
      expect(t.timeTakenMs, 8000);
    });

    test('the server receives only the seconds taken', () {
      final t = const QuestionTiming()
          .shown(_at(0))
          .answered(
            _at(12).add(const Duration(milliseconds: 340)),
            previous: null,
            choice: 0,
          );
      expect(t.toSubmission(), {'duration': 12.3});
    });

    test('survives being saved and read back, and bad data reads as empty', () {
      final t = const QuestionTiming()
          .shown(_at(0))
          .answered(_at(2), previous: null, choice: 3);
      final back = QuestionTiming.fromJson(t.toJson());
      expect(back.toJson(), t.toJson());
      expect(QuestionTiming.fromJson('junk').spentMs, 0);
      expect(QuestionTiming.fromJson({'spentMs': -5}).spentMs, 0);
    });
  });

  group('QuizTimingTracker', () {
    QuizTimingTracker tracker({
      Map<String, QuestionTiming> saved = const {},
      DateTime? savedAt,
      DateTime? serverStartedAt,
      int offsetMs = 0,
      int? overall,
      int? perQuestion,
    }) => QuizTimingTracker()
      ..load(
        questionIds: const ['a', 'b'],
        localStart: _at(0),
        saved: saved,
        savedAt: savedAt,
        serverStartedAt: serverStartedAt,
        offsetMs: offsetMs,
        overallLimit: overall,
        perQuestionLimit: perQuestion,
      );

    test('the quiz clock follows the server start, on the phone clock', () {
      // The phone is 60 s behind the server.
      final t = tracker(
        serverStartedAt: _at(1000),
        offsetMs: 60000,
        overall: 300,
      );
      expect(t.quizStart, _at(940));
      expect(t.overallDeadline, _at(1240));
    });

    test('without a server start the first local open counts', () {
      expect(tracker(overall: 60).overallDeadline, _at(60));
    });

    test("a question's clock starts when it is first shown", () {
      final t = tracker(perQuestion: 30)..show('a', _at(10));
      expect(t.questionDeadline('a'), _at(40));
      expect(t.questionDeadline('b'), isNull);
      expect(t.isOpen('a', _at(39)), isTrue);
      expect(t.isOpen('a', _at(40)), isFalse);
    });

    test('nothing can be answered after the whole quiz ends', () {
      final t = tracker(overall: 60)..show('a', _at(0));
      expect(t.isOpen('a', _at(59)), isTrue);
      expect(t.isOpen('a', _at(61)), isFalse);
    });

    test('a timed out question stays closed and took its full time', () {
      final t = tracker(perQuestion: 30)
        ..show('a', _at(0))
        ..expire('a', _at(31));
      expect(t.timingOf('a').timedOut, isTrue);
      expect(t.timingOf('a').timeTakenMs, 30000);
      expect(t.isOpen('a', _at(5)), isFalse);
    });

    test(
      'a question on screen when the app was killed stops at the last save',
      () {
        final open = const QuestionTiming().shown(_at(0));
        final t = tracker(saved: {'a': open}, savedAt: _at(8), perQuestion: 30);
        expect(t.timingOf('a').spentMs, 8000);
        expect(t.timingOf('a').visibleSince, isNull);
        // ...but its countdown kept running while the app was closed.
        expect(t.questionDeadline('a'), _at(30));
      },
    );

    test('saved timings for questions no longer in the quiz are dropped', () {
      final t = tracker(saved: {'gone': const QuestionTiming().shown(_at(0))});
      expect(t.timings, isEmpty);
    });
  });
}
