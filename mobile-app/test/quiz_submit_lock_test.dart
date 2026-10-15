import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:qspot/screens/quiz/model/quiz_progress_record.dart';
import 'package:qspot/screens/quiz/provider/quiz_provider.dart';
import 'package:qspot/screens/quiz/screens/quiz_list_screen.dart';
import 'package:qspot/screens/quiz/widgets/quiz_pending_banner.dart';
import 'package:qspot/services/api_client.dart';
import 'package:qspot/services/common/storage_service.dart';
import 'package:qspot/services/quiz_offline_store.dart';
import 'package:qspot/services/quiz_submission_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _json = {'content-type': 'application/json'};

/// Once Submit is pressed the answers are final: a quiz waiting to be sent is
/// not reopened for changes.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.setString('userId', 'u1');
    QuizSubmissionService.retryDelays = const [];
  });
  tearDown(() => ApiClient.clientOverride = null);

  test('a submitted quiz waiting to be sent does not reopen', () async {
    var online = true;
    ApiClient.clientOverride = MockClient((request) async {
      if (!online) throw const SocketException('no network');
      return http.Response(
        jsonEncode({
          'title': 'Weekly Quiz',
          'questions': [
            {
              '_id': 'a',
              'type': 'mcq',
              'question_en': 'Q',
              'options_en': ['A', 'B'],
              'difficulty': 'easy',
            },
          ],
        }),
        200,
        headers: _json,
      );
    });
    final provider = QuizProvider();
    await provider.startQuiz('q1');
    provider.selectAnswer(1);
    online = false;
    await expectLater(provider.submitQuiz(), throwsA(anything));
    provider.resetSession();
    online = true;

    await expectLater(
      provider.startQuiz('q1'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          QuizProvider.submittedWaitingMessage,
        ),
      ),
    );
    expect(provider.isQuizActive, isFalse);
  });

  testWidgets('tapping it says it is waiting to send and tries again', (
    tester,
  ) async {
    final posts = <String>[];
    ApiClient.clientOverride = MockClient((request) async {
      if (request.method == 'POST') {
        posts.add(request.url.path);
        // The server is still struggling.
        return http.Response(jsonEncode({'message': 'busy'}), 500);
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
        headers: _json,
      );
    });
    await tester.runAsync(
      () => QuizOfflineStore.saveProgress(
        'u1',
        QuizProgressRecord(
          quizId: 'q1',
          title: 'Weekly Quiz',
          questionIds: const ['a'],
          answers: const {'a': 1},
          language: 'en',
          startedAt: DateTime.now(),
          submitPending: true,
        ),
      ),
    );
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => QuizProvider(),
        child: const MaterialApp(home: QuizListScreen()),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
    final sendsBefore = posts.length;
    // The list shows that answers are waiting on the phone.
    expect(find.byType(QuizPendingBanner), findsOneWidget);
    expect(find.textContaining('saved on this phone'), findsOneWidget);

    await tester.tap(find.text('Weekly Quiz').last);
    await tester.pump();

    expect(find.text(QuizProvider.submittedWaitingMessage), findsOneWidget);
    expect(find.text('Select Quiz Language'), findsNothing);

    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
    expect(posts.length, greaterThan(sendsBefore), reason: 'sent again');
  });
}
