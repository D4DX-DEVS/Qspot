import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:qspot/screens/quiz/model/answers_availability.dart';
import 'package:qspot/screens/quiz/provider/quiz_provider.dart';
import 'package:qspot/screens/quiz/screens/quiz_list_screen.dart';
import 'package:qspot/screens/quiz/screens/quiz_question_screen.dart';
import 'package:qspot/services/api_client.dart';
import 'package:qspot/services/common/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _listStandIn = 'Quiz list stand-in';

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

Map<String, dynamic> _takenQuiz({required bool revealed}) => {
  '_id': 'q1',
  'title': 'Weekly Quiz',
  'assessmentType': 'quiz',
  'status': 'live',
  'numberOfQuestions': 10,
  'questionCount': 10,
  'myAttempt': {
    'attemptId': 'a1',
    'score': 8,
    'totalQuestions': 10,
    'percentage': 80,
    'createdAt': '2026-10-20T10:00:00.000Z',
    'answersRevealed': revealed,
    'answersAvailableAt': '2026-10-20T11:35:00.000Z',
  },
};

/// A quiz score stays hidden until the quiz has closed for everyone:
/// submitting only confirms that the answers are in.
void main() {
  test('the message says when the score will show', () {
    final now = DateTime(2026, 10, 20, 15);
    expect(
      AnswersAvailability(
        revealed: false,
        availableAt: DateTime(2026, 10, 20, 17, 5),
      ).submittedMessage(now: now),
      'Your answers have been submitted. Your score will show after 5:05 pm '
      'today, once everyone has finished.',
    );
    expect(
      AnswersAvailability(
        revealed: false,
        availableAt: DateTime(2026, 10, 21, 9, 30),
      ).submittedMessage(now: now),
      contains('after 9:30 am on 21 Oct'),
    );
    expect(
      const AnswersAvailability(revealed: false).submittedMessage(now: now),
      'Your answers have been submitted. Your score will show once the quiz '
      'has closed.',
    );
  });

  testWidgets('submitting shows "Answers Submitted", not the results', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    ApiClient.clientOverride = MockClient(
      (request) async => _json({
        'attempt': {
          'attemptId': 'a1',
          'quizId': 'test-quiz',
          'title': 'Test Quiz',
          'language': 'Malayalam',
          'score': 1,
          'totalQuestions': 2,
          'percentage': 50,
          'createdAt': '2026-10-20T10:00:00.000Z',
          'answersRevealed': false,
          'answersAvailableAt': '2026-10-20T11:35:00.000Z',
          'results': <Object>[],
        },
      }, 201),
    );
    addTearDown(() => ApiClient.clientOverride = null);

    final provider = QuizProvider()
      ..seedSessionForTest([
        for (var i = 0; i < 2; i++)
          {
            '_id': 'id-$i',
            'type': 'multiple_choice',
            'question_en': 'Question body $i',
            'options_en': ['A', 'B', 'C', 'D'],
            'difficulty': 'easy',
          },
      ]);
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(
          navigatorKey: navigator,
          home: const Scaffold(body: Text(_listStandIn)),
        ),
      ),
    );
    navigator.currentState!.push(
      MaterialPageRoute(builder: (_) => const QuizQuestionScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('B'));
    await tester.tap(find.byIcon(LucideIcons.arrowRight));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(LucideIcons.check));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Submit'));
    await tester.pumpAndSettle();

    expect(find.text('Answers Submitted'), findsOneWidget);
    expect(find.textContaining('Your score will show after'), findsOneWidget);
    expect(find.text('Quiz Results'), findsNothing);

    await tester.tap(find.text('Got It'));
    await tester.pumpAndSettle();
    expect(find.text(_listStandIn), findsOneWidget);
    expect(find.byType(QuizQuestionScreen), findsNothing);
  });

  group('on the Quiz page', () {
    late Map<String, dynamic> quiz;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await StorageService.setString('userId', 'u1');
      ApiClient.clientOverride = MockClient(
        (request) async => request.url.path == '/api/user-quizzes'
            ? _json([quiz])
            : _json({'message': 'Not found'}, 404),
      );
    });
    tearDown(() => ApiClient.clientOverride = null);

    Future<void> openList(WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: QuizProvider(),
          child: const MaterialApp(home: QuizListScreen()),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('before the quiz closes: no score, and a tap explains why', (
      tester,
    ) async {
      quiz = _takenQuiz(revealed: false);
      await openList(tester);

      expect(find.text('Answers submitted'), findsOneWidget);
      expect(find.textContaining('Your Score'), findsNothing);

      await tester.tap(find.text('Weekly Quiz'));
      await tester.pumpAndSettle();
      expect(find.text('Answers Submitted'), findsOneWidget);
      expect(find.text('Quiz Results'), findsNothing);
    });

    testWidgets('after the quiz closes: the score and results show', (
      tester,
    ) async {
      quiz = _takenQuiz(revealed: true);
      await openList(tester);

      expect(find.textContaining('Your Score: 8/10'), findsOneWidget);
      expect(find.text('Answers submitted'), findsNothing);

      await tester.tap(find.text('Weekly Quiz'));
      await tester.pumpAndSettle();
      expect(find.text('Quiz Results'), findsOneWidget);
    });
  });
}
