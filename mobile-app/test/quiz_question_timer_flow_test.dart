import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:qspot/screens/quiz/provider/quiz_provider.dart';
import 'package:qspot/screens/quiz/screens/quiz_question_screen.dart';
import 'package:qspot/services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stand in for the main tabs and the quiz list opened from them.
const _tabsStandIn = 'Tabs stand-in';
const _listStandIn = 'Quiz list stand-in';

/// Timers, submitting and leaving the quiz question screen.
void main() {
  late List<Map<String, dynamic>> submitted;
  Completer<void>? holdSubmit;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    submitted = [];
    holdSubmit = null;
    ApiClient.clientOverride = MockClient((request) async {
      const headers = {'content-type': 'application/json'};
      if (request.method != 'POST') return http.Response('[]', 200);
      submitted.add(jsonDecode(request.body) as Map<String, dynamic>);
      await holdSubmit?.future;
      final attempt = {
        'attemptId': 'a1',
        'quizId': 'test-quiz',
        'title': 'Test Quiz',
        'language': 'English',
        'score': 1,
        'totalQuestions': 3,
        'percentage': 33,
        'createdAt': '2026-10-09T10:00:00.000Z',
        'results': <Object>[],
      };
      return http.Response(
        jsonEncode({'attempt': attempt}),
        201,
        headers: headers,
      );
    });
  });
  tearDown(() => ApiClient.clientOverride = null);

  /// Opens the quiz over the list stand-in and stops before the first tick.
  Future<QuizProvider> openQuiz(
    WidgetTester tester, {
    int questions = 3,
    String timerMode = 'none',
    int? overall,
    int? perQuestion,
  }) async {
    final provider = QuizProvider()
      ..seedSessionForTest(
        [
          for (var i = 0; i < questions; i++)
            {
              '_id': 'id-$i',
              'type': 'multiple_choice',
              'question_en': 'Question body $i',
              'options_en': ['A', 'B', 'C', 'D'],
              'difficulty': 'easy',
            },
        ],
        timerMode: timerMode,
        overallTimeLimit: overall,
        perQuestionTimeLimit: perQuestion,
      );
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(
          navigatorKey: navigator,
          home: const Scaffold(body: Text(_tabsStandIn)),
        ),
      ),
    );
    navigator.currentState!.push(
      MaterialPageRoute(
        builder: (_) => const Scaffold(body: Text(_listStandIn)),
      ),
    );
    navigator.currentState!.push(
      MaterialPageRoute(builder: (_) => const QuizQuestionScreen()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    return provider;
  }

  Future<void> seconds(WidgetTester tester, int count) async {
    for (var i = 0; i < count; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
  }

  testWidgets('a per-question timer allows no going back or jumping', (
    tester,
  ) async {
    final provider = await openQuiz(
      tester,
      timerMode: 'per-question',
      perQuestion: 30,
    );

    expect(find.byIcon(LucideIcons.arrowLeft), findsNothing);
    await tester.tap(find.text('3'));
    await tester.pump();
    expect(provider.currentQuestionIndex, 0);

    await tester.tap(find.byIcon(LucideIcons.arrowRight));
    await tester.pump();
    expect(provider.currentQuestionIndex, 1);
    expect(find.byIcon(LucideIcons.arrowLeft), findsNothing);
    await tester.tap(find.text('1'));
    await tester.pump();
    expect(provider.currentQuestionIndex, 1);
  });

  testWidgets('without a per-question timer Previous and numbers work', (
    tester,
  ) async {
    final provider = await openQuiz(tester, timerMode: 'overall', overall: 300);

    await tester.tap(find.text('3'));
    await tester.pump();
    expect(provider.currentQuestionIndex, 2);
    await tester.tap(find.byIcon(LucideIcons.arrowLeft));
    await tester.pump();
    expect(provider.currentQuestionIndex, 1);
  });

  testWidgets(
    'when a question runs out it moves on with the chosen answer, and the last one submits',
    (tester) async {
      final provider = await openQuiz(
        tester,
        timerMode: 'per-question',
        perQuestion: 5,
      );

      await tester.tap(find.text('B'));
      await seconds(tester, 5);
      expect(provider.currentQuestionIndex, 1);
      expect(provider.getSelectedAnswer('id-0'), 1);
      expect(find.text('This question 0:05'), findsOneWidget);

      await seconds(tester, 5);
      expect(provider.currentQuestionIndex, 2);
      expect(provider.getSelectedAnswer('id-1'), isNull);
      expect(submitted, isEmpty);

      await seconds(tester, 5);
      await tester.pumpAndSettle();
      expect(submitted, hasLength(1));
      expect(submitted.single['answers'], [
        {'questionId': 'id-0', 'attemptedAnswer': 1},
        {'questionId': 'id-1', 'attemptedAnswer': null},
        {'questionId': 'id-2', 'attemptedAnswer': null},
      ]);
      expect(find.text('Quiz Results'), findsOneWidget);
    },
  );

  testWidgets('Next keeps the whole-quiz time when both timers are on', (
    tester,
  ) async {
    await openQuiz(tester, timerMode: 'both', overall: 100, perQuestion: 20);
    await seconds(tester, 3);
    expect(find.text('Time 1:37'), findsOneWidget);
    expect(find.text('This question 0:17'), findsOneWidget);

    await tester.tap(find.byIcon(LucideIcons.arrowRight));
    await tester.pump();

    expect(find.text('Time 1:37'), findsOneWidget);
    expect(find.text('This question 0:20'), findsOneWidget);
  });

  testWidgets(
    'time running out with the Submit dialog open closes it, and X goes to the list',
    (tester) async {
      final provider = await openQuiz(
        tester,
        questions: 1,
        timerMode: 'overall',
        overall: 5,
      );
      await tester.tap(find.byIcon(LucideIcons.check));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      expect(find.text('Submit Quiz?'), findsOneWidget);

      await seconds(tester, 5);
      await tester.pumpAndSettle();

      expect(submitted, hasLength(1));
      expect(find.text('Submit Quiz?'), findsNothing);
      expect(find.text('Quiz Results'), findsOneWidget);
      expect(
        find.byType(QuizQuestionScreen, skipOffstage: false),
        findsNothing,
      );
      expect(provider.isQuizActive, isFalse);

      await tester.tap(find.byIcon(LucideIcons.x));
      await tester.pumpAndSettle();
      expect(find.text(_listStandIn), findsOneWidget);
    },
  );

  testWidgets(
    'a slow submit is sent once even if the timer runs out, and back goes to the list',
    (tester) async {
      await openQuiz(tester, questions: 1, timerMode: 'overall', overall: 3);
      holdSubmit = Completer<void>();

      await tester.tap(find.byIcon(LucideIcons.check));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Submit'));
      await seconds(tester, 5);
      expect(submitted, hasLength(1));

      holdSubmit!.complete();
      await tester.pumpAndSettle();
      expect(submitted, hasLength(1));
      expect(find.text('Quiz Results'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text(_listStandIn), findsOneWidget);
    },
  );
}
