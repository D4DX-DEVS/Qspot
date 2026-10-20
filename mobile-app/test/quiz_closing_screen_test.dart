import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:qspot/screens/quiz/provider/quiz_provider.dart';
import 'package:qspot/screens/quiz/screens/quiz_question_screen.dart';
import 'package:qspot/screens/quiz/widgets/quiz_refused_banner.dart';
import 'package:qspot/services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _json = {'content-type': 'application/json'};
const _listStandIn = 'Quiz list stand-in';

http.Response _tooLate() => http.Response(
  jsonEncode({
    'message':
        "This quiz has closed. Answers that arrive after it closes can't be marked.",
    'code': 'QUIZ_CLOSED',
  }),
  403,
  headers: _json,
);

http.Response _accepted() => http.Response(
  jsonEncode({
    'attempt': {
      'attemptId': 'a1',
      'quizId': 'q1',
      'title': 'Test Quiz',
      'score': 1,
      'totalQuestions': 2,
      'percentage': 50,
      'createdAt': '2026-10-14T10:00:00.000Z',
      'results': <Object>[],
    },
  }),
  201,
  headers: _json,
);

List<Map<String, dynamic>> _questions(int n) => [
  for (var i = 0; i < n; i++)
    {
      '_id': 'id-$i',
      'type': 'multiple_choice',
      'question_en': 'Question body $i',
      'options_en': ['A', 'B', 'C', 'D'],
      'difficulty': 'easy',
    },
];

/// On the quiz screen: a warning before the quiz closes, a submit at the end
/// time, and a clear message when answers arrive too late to be marked.
void main() {
  group('quiz screen', () {
    late List<String> posted;
    late http.Response Function() onSubmit;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      posted = [];
      onSubmit = _accepted;
      ApiClient.clientOverride = MockClient((request) async {
        if (request.method != 'POST') return http.Response('[]', 200);
        posted.add(request.body);
        return onSubmit();
      });
    });
    tearDown(() => ApiClient.clientOverride = null);

    Future<QuizProvider> openQuiz(
      WidgetTester tester,
      Duration closesIn,
    ) async {
      final provider = QuizProvider()
        ..seedSessionForTest(_questions(2), endsAt: clock.now().add(closesIn));
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
      return provider;
    }

    testWidgets('warns before closing and submits by itself at the end time', (
      tester,
    ) async {
      await openQuiz(tester, const Duration(seconds: 10));
      await tester.tap(find.text('B'));
      await tester.pump();
      expect(find.text('Closes in 0:10'), findsOneWidget);

      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      await tester.pumpAndSettle();

      expect(posted, hasLength(1));
      expect(find.text('Answers Submitted'), findsOneWidget);
    });

    testWidgets('answers arriving too late get a clear message', (
      tester,
    ) async {
      onSubmit = _tooLate;
      await openQuiz(tester, const Duration(hours: 1));
      await tester.tap(find.byIcon(LucideIcons.arrowRight));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(LucideIcons.check));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Submit'));
      await tester.pumpAndSettle();

      expect(find.text('Submitted Too Late'), findsOneWidget);
      expect(find.textContaining('could not be marked'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'OK'));
      await tester.pumpAndSettle();
      expect(find.text(_listStandIn), findsOneWidget);
    });

    testWidgets('the list notice explains and can be dismissed', (
      tester,
    ) async {
      var dismissed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuizRefusedBanner(
              message: 'Your answers reached us after the quiz closed.',
              onDismiss: () => dismissed++,
            ),
          ),
        ),
      );
      expect(
        find.text('Your answers reached us after the quiz closed.'),
        findsOneWidget,
      );
      await tester.tap(find.text('OK'));
      expect(dismissed, 1);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: QuizRefusedBanner(message: 'x', onDismiss: () {}),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
