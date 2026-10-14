import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qspot/screens/quiz/provider/quiz_question_screen_provider.dart';

/// The countdowns run to fixed deadlines and read the clock on every tick, so
/// time that passes between ticks (app in the background, late timer) counts.
void main() {
  late DateTime now;
  final start = DateTime(2026, 10, 14, 10);

  setUp(() => now = start);

  void later(int seconds) => now = now.add(Duration(seconds: seconds));
  DateTime inSeconds(int seconds) => now.add(Duration(seconds: seconds));
  T onClock<T>(T Function() body) => withClock(Clock(() => now), body);

  test('both countdowns tick down together', () {
    onClock(() {
      final q = QuizQuestionScreenProvider()
        ..startTimers(
          overallDeadline: inSeconds(100),
          questionDeadline: inSeconds(20),
        );
      later(1);
      expect(q.tick(), QuizTimerExpiry.none);
      expect(q.overallRemaining, 99);
      expect(q.questionRemaining, 19);
    });
  });

  test('a new question only gets a new per-question deadline', () {
    onClock(() {
      final q = QuizQuestionScreenProvider()
        ..startTimers(
          overallDeadline: inSeconds(100),
          questionDeadline: inSeconds(20),
        );
      later(5);
      q.tick();

      q.setQuestionDeadline(inSeconds(20));

      expect(q.overallRemaining, 95);
      expect(q.questionRemaining, 20);
    });
  });

  test('reports a question running out once, then stays at zero', () {
    onClock(() {
      final q = QuizQuestionScreenProvider()
        ..startTimers(questionDeadline: inSeconds(2));

      later(1);
      expect(q.tick(), QuizTimerExpiry.none);
      later(1);
      expect(q.tick(), QuizTimerExpiry.question);
      later(1);
      expect(q.tick(), QuizTimerExpiry.none);
      expect(q.questionRemaining, 0);
      expect(q.overallRemaining, isNull);
    });
  });

  test('the whole-quiz time wins when both run out together', () {
    onClock(() {
      final q = QuizQuestionScreenProvider()
        ..startTimers(
          overallDeadline: inSeconds(1),
          questionDeadline: inSeconds(1),
        );
      later(1);
      expect(q.tick(), QuizTimerExpiry.overall);
      expect(q.tick(), QuizTimerExpiry.none);
    });
  });

  test('time that passed between ticks still counts', () {
    onClock(() {
      final q = QuizQuestionScreenProvider()
        ..startTimers(
          overallDeadline: inSeconds(100),
          questionDeadline: inSeconds(30),
        );
      // e.g. 40 s in the background, where timers do not fire.
      later(40);
      expect(q.tick(), QuizTimerExpiry.question);
      expect(q.overallRemaining, 60);
    });
  });

  test('a deadline already past when the screen opens fires at once', () {
    onClock(() {
      final q = QuizQuestionScreenProvider()
        ..startTimers(overallDeadline: inSeconds(-5));
      expect(q.overallRemaining, 0);
      expect(q.tick(), QuizTimerExpiry.overall);
    });
  });

  test('part of a second left still shows as a second', () {
    onClock(() {
      final q = QuizQuestionScreenProvider()
        ..startTimers(
          questionDeadline: now.add(const Duration(milliseconds: 1200)),
        );
      expect(q.questionRemaining, 2);
    });
  });

  test('labels count as minutes and seconds', () {
    expect(QuizQuestionScreenProvider.timerLabel(97), '1:37');
    expect(QuizQuestionScreenProvider.timerLabel(5), '0:05');
  });
}
