import 'package:flutter_test/flutter_test.dart';
import 'package:qspot/screens/quiz/provider/quiz_question_screen_provider.dart';

/// The whole-quiz and per-question countdowns must run independently.
void main() {
  test('both countdowns tick down together', () {
    final q = QuizQuestionScreenProvider()
      ..startTimers(overall: 100, perQuestion: 20);

    expect(q.tick(), QuizTimerExpiry.none);
    expect(q.overallRemaining, 99);
    expect(q.questionRemaining, 19);
  });

  test('moving to the next question only refills the per-question time', () {
    final q = QuizQuestionScreenProvider()
      ..startTimers(overall: 100, perQuestion: 20);
    for (var i = 0; i < 5; i++) {
      q.tick();
    }

    q.resetQuestionTimer();

    expect(q.overallRemaining, 95);
    expect(q.questionRemaining, 20);
  });

  test('reports a question running out once, then stays at zero', () {
    final q = QuizQuestionScreenProvider()..startTimers(perQuestion: 2);

    expect(q.tick(), QuizTimerExpiry.none);
    expect(q.tick(), QuizTimerExpiry.question);
    expect(q.tick(), QuizTimerExpiry.none);
    expect(q.questionRemaining, 0);
    expect(q.overallRemaining, isNull);
  });

  test('the whole-quiz time wins when both run out together', () {
    final q = QuizQuestionScreenProvider()
      ..startTimers(overall: 1, perQuestion: 1);

    expect(q.tick(), QuizTimerExpiry.overall);
  });

  test('labels count as minutes and seconds', () {
    expect(QuizQuestionScreenProvider.timerLabel(97), '1:37');
    expect(QuizQuestionScreenProvider.timerLabel(5), '0:05');
  });
}
