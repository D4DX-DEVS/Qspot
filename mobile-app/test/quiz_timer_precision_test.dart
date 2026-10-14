import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:qspot/screens/quiz/provider/quiz_provider.dart';
import 'package:qspot/screens/quiz/screens/quiz_question_screen.dart';
import 'package:qspot/services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The per-question countdown is exact: time keeps running while the app is
/// away, an expired question is skipped as soon as the quiz is back on
/// screen, and the next question's clock starts only when it is shown.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiClient.clientOverride = MockClient(
      (_) async => http.Response('{}', 500),
    );
  });
  tearDown(() => ApiClient.clientOverride = null);

  QuizProvider seeded() => QuizProvider()
    ..seedSessionForTest(
      [
        for (var i = 0; i < 3; i++)
          {
            '_id': 'id-$i',
            'type': 'multiple_choice',
            'question_en': 'Question body $i',
            'options_en': ['A', 'B', 'C', 'D'],
            'difficulty': 'easy',
          },
      ],
      timerMode: 'per-question',
      perQuestionTimeLimit: 30,
    );

  Future<void> showScreen(WidgetTester tester, QuizProvider provider) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(
          navigatorKey: navigator,
          home: const Scaffold(body: Text('List')),
        ),
      ),
    );
    navigator.currentState!.push(
      MaterialPageRoute(builder: (_) => const QuizQuestionScreen()),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets(
    'a question whose time ran out before the screen opened is skipped at once',
    (tester) async {
      final provider = seeded();
      // 40 s pass before the quiz is on screen again (app was closed).
      await tester.pump(const Duration(seconds: 40));

      await showScreen(tester, provider);

      expect(provider.currentQuestionIndex, 1);
      expect(provider.timingOf('id-0').timedOut, isTrue);
      expect(find.text('This question 0:30'), findsOneWidget);
      expect(find.text('Question body 1'), findsOneWidget);
    },
  );

  testWidgets(
    'time in the background counts, and the next question waits to be seen',
    (tester) async {
      final provider = seeded();
      await showScreen(tester, provider);
      await tester.pump(const Duration(seconds: 5));

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 50));
      // Question 1 ran out while away; question 2 has not been seen yet.
      expect(provider.timingOf('id-0').timedOut, isTrue);
      expect(provider.timingOf('id-1').firstShownAt, isNull);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(provider.currentQuestionIndex, 1);
      expect(find.text('This question 0:30'), findsOneWidget);
      // Ran out while away: it took its full 30 s.
      expect(provider.timingOf('id-0').timeTakenMs, 30000);

      await tester.pump(const Duration(seconds: 10));
      expect(find.text('This question 0:20'), findsOneWidget);
    },
  );
}
