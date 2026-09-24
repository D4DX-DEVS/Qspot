import 'package:flutter_test/flutter_test.dart';
import 'package:qspot/screens/quiz/model/quiz_model.dart';

void main() {
  group('QuizListItem', () {
    test('parses a live quiz with no prior attempt', () {
      final item = QuizListItem.fromJson({
        '_id': 'q1',
        'title': 'General Knowledge',
        'startDate': '2026-09-19T00:00:00.000Z',
        'endDate': '2026-09-20T00:00:00.000Z',
        'numberOfQuestions': 10,
        'questionsRandomization': true,
        'overallTimeLimit': 600,
        'perQuestionTimeLimit': 30,
        'optionsCount': 4,
        'status': 'live',
        'questionCount': 10,
        'myAttempt': null,
      });

      expect(item.id, 'q1');
      expect(item.status, 'live');
      expect(item.isLive, isTrue);
      expect(item.hasAttempted, isFalse);
      expect(item.myAttempt, isNull);
    });

    test('parses an ended quiz with an attempt summary embedded', () {
      final item = QuizListItem.fromJson({
        '_id': 'q2',
        'title': 'History Quiz',
        'startDate': '2026-09-01T00:00:00.000Z',
        'endDate': '2026-09-02T00:00:00.000Z',
        'numberOfQuestions': 5,
        'questionsRandomization': false,
        'status': 'ended',
        'questionCount': 5,
        'myAttempt': {
          'attemptId': 'a1',
          'score': 4,
          'totalQuestions': 5,
          'percentage': 80,
          'createdAt': '2026-09-01T12:00:00.000Z',
        },
      });

      expect(item.isEnded, isTrue);
      expect(item.hasAttempted, isTrue);
      expect(item.myAttempt!.score, 4);
      expect(item.myAttempt!.percentage, 80);
    });

    test(
      'an empty list response parses to an empty list (normal, not an error)',
      () {
        final list = <dynamic>[];
        final items = list
            .map((e) => QuizListItem.fromJson(e as Map<String, dynamic>))
            .toList();
        expect(items, isEmpty);
      },
    );
  });

  group('QuizQuestion', () {
    test('uses the Mongo _id string as the question id, not a parsed int', () {
      final question = QuizQuestion.fromJson({
        '_id': '66f1a2b3c4d5e6f7a8b9c0d1',
        'type': 'multiple_choice',
        'question_en': 'What is the capital of Kerala?',
        'question_ml': 'കേരളത്തിന്റെ തലസ്ഥാനം ഏത്?',
        'options_en': ['Kochi', 'Thiruvananthapuram', 'Kozhikode', 'Thrissur'],
        'options_ml': ['കൊച്ചി', 'തിരുവനന്തപുരം', 'കോഴിക്കോട്', 'തൃശ്ശൂർ'],
        'difficulty': 'easy',
      });

      expect(question.id, '66f1a2b3c4d5e6f7a8b9c0d1');
      expect(question.getQuestion('en'), 'What is the capital of Kerala?');
      expect(question.getOptions('ml').length, 4);
    });

    test(
      'falls back to English options when Malayalam options are missing',
      () {
        final question = QuizQuestion.fromJson({
          '_id': 'q1',
          'question_en': 'Q',
          'options_en': ['A', 'B', 'C'],
          'options_ml': [], // guards against a RangeError on a shorter ML list
        });

        expect(question.getOptions('ml'), ['A', 'B', 'C']);
      },
    );
  });

  group('QuestionResult', () {
    test('parses a server-graded result including a null attemptedAnswer', () {
      final result = QuestionResult.fromJson({
        'questionId': '66f1a2b3c4d5e6f7a8b9c0d1',
        'type': 'multiple_choice',
        'question_en': 'Q',
        'question_ml': 'ചോ',
        'options_en': ['A', 'B'],
        'options_ml': ['എ', 'ബി'],
        'attemptedAnswer': null,
        'correctAnswer': 1,
        'isCorrect': false,
      });

      expect(result.questionId, '66f1a2b3c4d5e6f7a8b9c0d1');
      expect(result.attemptedAnswer, isNull);
      expect(result.correctAnswer, 1);
      expect(result.isCorrect, isFalse);
    });

    test('parses an answered, correct result', () {
      final result = QuestionResult.fromJson({
        'questionId': 'q2',
        'options_en': ['A', 'B'],
        'attemptedAnswer': 1,
        'correctAnswer': 1,
        'isCorrect': true,
      });

      expect(result.attemptedAnswer, 1);
      expect(result.isCorrect, isTrue);
    });
  });

  group('QuizAttemptResult', () {
    test(
      'parses the attempt object returned by a submission, with results',
      () {
        final attempt = QuizAttemptResult.fromJson({
          'attemptId': 'a1',
          'quizId': 'q1',
          'title': 'General Knowledge',
          'language': 'en',
          'score': 8,
          'totalQuestions': 10,
          'percentage': 80,
          'totalDuration': 300,
          'createdAt': '2026-09-19T10:00:00.000Z',
          'results': [
            {
              'questionId': 'q1',
              'options_en': ['A', 'B'],
              'attemptedAnswer': 0,
              'correctAnswer': 0,
              'isCorrect': true,
            },
          ],
        });

        expect(attempt.score, 8);
        expect(attempt.results, hasLength(1));
        expect(attempt.results.first.isCorrect, isTrue);
      },
    );

    test('parses a 409 already-attempted body the same way as a fresh 201', () {
      // Contract: on 409 the response body is {message, attempt}. The
      // `attempt` payload itself has the same shape as a successful submit.
      final body = {
        'message': 'Already attempted',
        'attempt': {
          'attemptId': 'a1',
          'quizId': 'q1',
          'title': 'General Knowledge',
          'language': 'en',
          'score': 5,
          'totalQuestions': 10,
          'percentage': 50,
          'totalDuration': 120,
          'createdAt': '2026-09-19T10:00:00.000Z',
          'results': <dynamic>[],
        },
      };

      final attempt = QuizAttemptResult.fromJson(
        body['attempt'] as Map<String, dynamic>,
      );
      expect(attempt.attemptId, 'a1');
      expect(attempt.score, 5);
    });
  });

  group('QuizHistoryItem', () {
    test('parses a quiz-history row', () {
      final item = QuizHistoryItem.fromJson({
        'attemptId': 'a1',
        'quizId': 'q1',
        'title': 'General Knowledge',
        'language': 'en',
        'score': 8,
        'totalQuestions': 10,
        'percentage': 80,
        'totalDuration': 300,
        'createdAt': '2026-09-19T10:00:00.000Z',
      });

      expect(item.attemptId, 'a1');
      expect(item.score, 8);
      expect(item.percentage, 80);
    });
  });
}
