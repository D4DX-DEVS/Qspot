import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:qspot/screens/quiz/provider/quiz_provider.dart';
import 'package:qspot/screens/quiz/screens/quiz_question_screen.dart';
import 'package:qspot/screens/quiz/widgets/quiz_pending_banner.dart';
import 'package:qspot/services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _listStandIn = 'Quiz list stand-in';

/// What the student sees when Submit cannot reach the server.
void main() {
  late bool online;
  late List<Map<String, dynamic>> posts;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    online = false;
    posts = [];
    ApiClient.clientOverride = MockClient((request) async {
      if (!online) throw const SocketException('no network');
      posts.add(jsonDecode(request.body) as Map<String, dynamic>);
      return http.Response(
        jsonEncode({
          'attempt': {
            'attemptId': 'a1',
            'quizId': 'test-quiz',
            'title': 'Test Quiz',
            'language': 'English',
            'score': 1,
            'totalQuestions': 2,
            'percentage': 50,
            'createdAt': '2026-10-14T10:00:00.000Z',
            'results': <Object>[],
          },
        }),
        201,
        headers: {'content-type': 'application/json'},
      );
    });
  });
  tearDown(() => ApiClient.clientOverride = null);

  Future<QuizProvider> openQuiz(WidgetTester tester) async {
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
          home: const Scaffold(body: Text('Tabs')),
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
    await tester.pumpAndSettle();
    return provider;
  }

  Future<void> pressSubmit(WidgetTester tester) async {
    await tester.tap(find.byIcon(LucideIcons.arrowRight));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(LucideIcons.check));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Submit'));
    await tester.pumpAndSettle();
  }

  testWidgets('no connection: the answers are safe and Try Again sends them', (
    tester,
  ) async {
    await openQuiz(tester);
    await tester.tap(find.text('B'));
    await pressSubmit(tester);

    expect(find.text("Couldn't Submit Yet"), findsOneWidget);
    expect(find.textContaining('saved on this phone'), findsOneWidget);
    expect(find.text('Answers Submitted'), findsNothing);

    online = true;
    await tester.tap(find.widgetWithText(ElevatedButton, 'Try Again'));
    await tester.pumpAndSettle();

    expect(posts, hasLength(1));
    expect(posts.single['answers'].first, containsPair('questionId', 'id-0'));
    expect(posts.single['answers'].first, containsPair('attemptedAnswer', 1));
    expect(find.text('Answers Submitted'), findsOneWidget);
  });

  testWidgets('Try Again can fail again without losing the dialog or answers', (
    tester,
  ) async {
    final provider = await openQuiz(tester);
    await tester.tap(find.text('C'));
    await pressSubmit(tester);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Try Again'));
    await tester.pumpAndSettle();

    expect(find.text("Couldn't Submit Yet"), findsOneWidget);
    expect(provider.getSelectedAnswer('id-0'), 2);
  });

  testWidgets('Later leaves the quiz, to be sent automatically afterwards', (
    tester,
  ) async {
    await openQuiz(tester);
    await pressSubmit(tester);

    await tester.tap(find.widgetWithText(TextButton, 'Later'));
    await tester.pumpAndSettle();

    expect(find.text(_listStandIn), findsOneWidget);
    expect(find.byType(QuizQuestionScreen), findsNothing);
  });

  testWidgets('the waiting-answers banner explains and sends on tap', (
    tester,
  ) async {
    var sent = 0;
    Widget banner({bool sending = false, ThemeData? theme}) => MaterialApp(
      theme: theme,
      home: Scaffold(
        body: QuizPendingBanner(
          message: 'Your answers are saved on this phone.',
          sending: sending,
          onSend: () => sent++,
        ),
      ),
    );

    await tester.pumpWidget(banner());
    expect(find.text('Your answers are saved on this phone.'), findsOneWidget);
    await tester.tap(find.text('Send Now'));
    expect(sent, 1);

    await tester.pumpWidget(banner(sending: true));
    expect(find.text('Sending…'), findsOneWidget);
    await tester.tap(find.text('Sending…'));
    expect(sent, 1);

    // Reads colours from the palette, so dark mode renders too.
    await tester.pumpWidget(banner(theme: ThemeData.dark()));
    expect(find.text('Send Now'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
