import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:qspot/screens/quiz/provider/quiz_provider.dart';
import 'package:qspot/screens/quiz/screens/quiz_list_screen.dart';
import 'package:qspot/screens/quiz/widgets/quiz_reminder_permission_dialog.dart';
import 'package:qspot/services/api_client.dart';
import 'package:qspot/services/common/storage_service.dart';
import 'package:qspot/services/quiz_reminder_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Notification permission for the "quiz closes soon" reminder is asked for
/// once, with an explanation, and only when not already allowed.
void main() {
  late bool allowed;
  late int prompts;
  late int explained;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.setBool('quiz_reminder_permission_asked', false);
    allowed = false;
    prompts = 0;
    explained = 0;
    QuizReminderService.notificationsAllowed = () async => allowed;
    QuizReminderService.requestNotifications = () async => prompts++;
  });

  Future<void> ask({required bool answer}) =>
      QuizReminderService.askPermissionOnce(() async {
        explained++;
        return answer;
      });

  test('Allow shows the phone prompt, once', () async {
    await ask(answer: true);
    await ask(answer: true);
    expect(explained, 1);
    expect(prompts, 1);
  });

  test('Not Now skips the phone prompt and is not asked again', () async {
    await ask(answer: false);
    await ask(answer: true);
    expect(explained, 1);
    expect(prompts, 0);
  });

  test('already allowed: nothing is asked', () async {
    allowed = true;
    await ask(answer: true);
    expect(explained, 0);
    expect(prompts, 0);
  });

  testWidgets('the first quiz started offers it', (tester) async {
    const json = {'content-type': 'application/json'};
    ApiClient.clientOverride = MockClient((request) async {
      if (request.url.path.endsWith('/questions')) {
        return http.Response(
          jsonEncode({
            'title': 'Weekly Quiz',
            'questions': [
              {
                '_id': 'a',
                'type': 'mcq',
                'question_en': 'Question body',
                'options_en': ['A', 'B'],
                'difficulty': 'easy',
              },
            ],
          }),
          200,
          headers: json,
        );
      }
      return http.Response(
        jsonEncode([
          {
            '_id': 'q1',
            'title': 'Weekly Quiz',
            'assessmentType': 'quiz',
            'status': 'live',
            'numberOfQuestions': 1,
            'questionCount': 1,
            'myAttempt': null,
          },
        ]),
        200,
        headers: json,
      );
    });
    addTearDown(() => ApiClient.clientOverride = null);

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

    // No language dialog: the quiz goes straight to the reminder prompt.
    await tester.tap(find.text('Weekly Quiz').last);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(QuizReminderPermissionDialog), findsOneWidget);
    await tester.tap(find.text('Allow'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();

    expect(prompts, 1);
    expect(find.text('Question body'), findsOneWidget, reason: 'quiz opens');
  });
}
