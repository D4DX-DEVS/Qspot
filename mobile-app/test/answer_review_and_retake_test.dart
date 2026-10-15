import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qspot/screens/quiz/model/answers_availability.dart';
import 'package:qspot/screens/quiz/model/quiz_model.dart';
import 'package:qspot/screens/quiz/provider/quiz_review_filter_provider.dart';
import 'package:qspot/screens/quiz/screens/quiz_results_screen.dart';
import 'package:qspot/screens/video/model/practice_result_summary.dart';
import 'package:qspot/screens/video/screens/video_questions_screen.dart';
import 'package:qspot/services/video_progress_service.dart';

QuestionResult _result(String id, {required bool correct}) => QuestionResult(
  questionId: id,
  type: 'Multiple Choice',
  questionEn: 'Question $id',
  questionMl: '',
  optionsEn: const ['A', 'B'],
  optionsMl: const [],
  attemptedAnswer: correct ? 0 : 1,
  correctAnswer: 0,
  isCorrect: correct,
);

void main() {
  group('when answers show', () {
    final now = DateTime(2026, 10, 15, 12);

    test('a time later today', () {
      final a = AnswersAvailability(
        revealed: false,
        availableAt: DateTime(2026, 10, 15, 19, 5),
      );
      expect(a.hiddenMessage(now: now), contains('after 7:05 pm today'));
    });

    test('another day', () {
      final a = AnswersAvailability(
        revealed: false,
        availableAt: DateTime(2026, 10, 21, 9),
      );
      expect(a.hiddenMessage(now: now), contains('after 9:00 am on 21 Oct'));
    });

    test('never, without an end date', () {
      const a = AnswersAvailability(revealed: false);
      expect(a.hiddenMessage(now: now), contains("aren't shown"));
    });
  });

  group('reading the server', () {
    test('an exam attempt with its answers held back', () {
      final attempt = QuizAttemptResult.fromJson({
        'attemptId': 'a1',
        'score': 3,
        'totalQuestions': 4,
        'percentage': 75,
        'answersRevealed': false,
        'answersAvailableAt': '2026-10-15T13:35:00.000Z',
        'results': <dynamic>[],
      });
      expect(attempt.answersRevealed, isFalse);
      expect(attempt.results, isEmpty);
      expect(attempt.answersAvailableAt, isNotNull);
    });

    test('an older server that sends answers and no flag', () {
      final attempt = QuizAttemptResult.fromJson({
        'attemptId': 'a1',
        'results': [
          {'questionId': 'q1', 'correctAnswer': 0, 'isCorrect': true},
        ],
      });
      expect(attempt.answersRevealed, isTrue);
    });

    test('the quiz list summary says whether answers are out', () {
      final summary = MyAttemptSummary.fromJson({
        'attemptId': 'a1',
        'answersRevealed': true,
        'answersAvailableAt': '2026-10-15T13:35:00.000Z',
      });
      expect(summary.answersRevealed, isTrue);
      expect(summary.answersAvailableAt, isNotNull);
    });

    test('a practice result with retakes', () {
      final r = VideoQuizResult.fromJson({
        'score': 4,
        'totalQuestions': 5,
        'percentage': 80,
        'attemptCount': 3,
        'latest': {'score': 2, 'percentage': 40},
        'canRetake': true,
        'answersRevealed': false,
        'answersAvailableAt': null,
        'results': <dynamic>[],
      });
      expect(r.attemptCount, 3);
      expect(r.latestScore, 2);
      expect(r.canRetake, isTrue);
      expect(r.answersRevealed, isFalse);
      expect(r.answersAvailableAt, isNull);
    });
  });

  group('practice result wording', () {
    const result = VideoQuizResult(
      score: 4,
      totalQuestions: 5,
      percentage: 80,
      attemptCount: 3,
      latestScore: 2,
      latestPercentage: 40,
      results: [
        VideoQuestionResult(
          questionId: 'q1',
          optionsEn: ['A', 'B'],
          attemptedAnswer: '1',
          correctAnswer: '0',
        ),
      ],
      answersRevealed: true,
    );

    test('a try just submitted shows its own score and the best', () {
      const s = PracticeResultSummary(result, justSubmitted: true);
      expect(s.scoreLine, 'You answered 2 of 5 correctly.');
      expect(s.shownPercentage, 40);
      expect(s.triesLine, 'Best so far: 4 of 5 · 3 tries');
    });

    test('a saved result shows the best', () {
      const s = PracticeResultSummary(result, justSubmitted: false);
      expect(s.scoreLine, 'Your best: 4 of 5 correct.');
      expect(s.triesLine, '3 tries');
    });

    test('a first try has no tries line', () {
      const s = PracticeResultSummary(
        VideoQuizResult(score: 1, totalQuestions: 2, percentage: 50),
        justSubmitted: true,
      );
      expect(s.triesLine, isNull);
      expect(s.canReview, isFalse);
    });

    test('revealed answers map onto the review screen', () {
      const s = PracticeResultSummary(result, justSubmitted: false);
      expect(s.canReview, isTrue);
      expect(s.reviewResults.single.attemptedAnswer, 1);
      expect(s.reviewResults.single.correctAnswer, 0);
    });
  });

  group('wrong-only filter', () {
    final results = [
      _result('1', correct: true),
      _result('2', correct: false),
      _result('3', correct: true),
      _result('4', correct: false),
    ];

    test('keeps question numbers from the full attempt', () {
      final f = QuizReviewFilterProvider(results);
      expect(f.showsFilter, isTrue);
      expect(f.labelFor(ReviewFilter.wrong), 'Wrong 2');
      f.select(ReviewFilter.wrong);
      expect(f.visible.map((e) => e.$1), [2, 4]);
    });

    test('is hidden when everything was right, or everything wrong', () {
      expect(
        QuizReviewFilterProvider([_result('1', correct: true)]).showsFilter,
        isFalse,
      );
      expect(
        QuizReviewFilterProvider([_result('1', correct: false)]).showsFilter,
        isFalse,
      );
    });
  });

  group('screens', () {
    Future<void> pump(WidgetTester tester, Widget child) async {
      await tester.pumpWidget(MaterialApp(home: child));
      await tester.pump(const Duration(seconds: 2));
    }

    testWidgets('an exam result before close says when answers show', (
      tester,
    ) async {
      await pump(
        tester,
        QuizResultsScreen(
          title: 'Unit Test 2',
          score: 2,
          totalQuestions: 4,
          percentage: 50,
          completedAt: null,
          results: const [],
          answersRevealed: false,
          answersAvailableAt: DateTime.now().add(const Duration(hours: 2)),
          attemptId: 'a1',
        ),
      );
      expect(find.textContaining('Correct answers show after'), findsOneWidget);
      expect(find.text('Review Answers'), findsNothing);
    });

    testWidgets('a closed exam opened from the list offers the review', (
      tester,
    ) async {
      await pump(
        tester,
        const QuizResultsScreen(
          title: 'Unit Test 2',
          score: 2,
          totalQuestions: 4,
          percentage: 50,
          completedAt: null,
          results: [],
          answersRevealed: true,
          attemptId: 'a1',
        ),
      );
      expect(find.text('Review Answers'), findsOneWidget);
      expect(find.textContaining('Correct answers show'), findsNothing);
    });

    const questions = [
      VideoQuestionItem(
        id: 'q1',
        questionEn: 'What are the three madd letters?',
        questionMl: '',
        optionsEn: ['Alif, waw and yaa', 'Noon, meem and laam'],
        optionsMl: [],
      ),
    ];

    testWidgets('a saved practice result offers Try Again while open', (
      tester,
    ) async {
      await pump(
        tester,
        const VideoQuestionsScreen(
          videoId: 'v1',
          videoTitle: 'Rules of Madd',
          questions: questions,
          priorResult: VideoQuizResult(
            score: 4,
            totalQuestions: 5,
            percentage: 80,
            attemptCount: 2,
            canRetake: true,
          ),
        ),
      );
      expect(find.text('Your best: 4 of 5 correct.'), findsOneWidget);
      expect(find.text('2 tries'), findsOneWidget);
      expect(find.textContaining("Correct answers aren't shown"), findsOneWidget);

      await tester.ensureVisible(find.text('Try Again'));
      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();
      expect(find.text('Question 1 of 1'), findsOneWidget);
    });

    testWidgets('a closed practice shows its answers and no Try Again', (
      tester,
    ) async {
      await pump(
        tester,
        const VideoQuestionsScreen(
          videoId: 'v1',
          videoTitle: 'Rules of Madd',
          questions: <VideoQuestionItem>[],
          priorResult: VideoQuizResult(
            score: 1,
            totalQuestions: 1,
            percentage: 100,
            answersRevealed: true,
            results: [
              VideoQuestionResult(
                questionId: 'q1',
                optionsEn: ['A', 'B'],
                attemptedAnswer: '0',
                correctAnswer: '0',
                isCorrect: true,
              ),
            ],
          ),
        ),
      );
      expect(find.text('See Answers'), findsOneWidget);
      expect(find.text('Try Again'), findsNothing);
    });
  });
}
