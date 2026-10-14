import 'dart:convert';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:qspot/screens/quiz/model/quiz_progress_record.dart';
import 'package:qspot/screens/quiz/provider/quiz_provider.dart';
import 'package:qspot/screens/quiz/provider/quiz_question_screen_provider.dart';
import 'package:qspot/services/api_client.dart';
import 'package:qspot/services/common/storage_service.dart';
import 'package:qspot/services/quiz_offline_store.dart';
import 'package:qspot/services/quiz_submission_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _quizId = 'quiz-1';
const _user = 'student-1';
const _json = {'content-type': 'application/json'};

Map<String, dynamic> _questions({int? overall}) => {
  'quizId': _quizId,
  'title': 'Weekly Quiz',
  'timerMode': overall == null ? 'none' : 'overall',
  'overallTimeLimit': overall,
  'questions': [
    for (var i = 0; i < 3; i++)
      {
        '_id': 'id-$i',
        'type': 'Multiple Choice',
        'question_en': 'Question $i',
        'options_en': ['A', 'B', 'C', 'D'],
        'difficulty': 'easy',
      },
  ],
};

Map<String, dynamic> _attempt() => {
  'attemptId': 'att-1',
  'quizId': _quizId,
  'title': 'Weekly Quiz',
  'language': 'English',
  'score': 2,
  'totalQuestions': 3,
  'percentage': 67,
  'totalDuration': 40,
  'createdAt': '2026-10-14T10:00:00.000Z',
  'results': <Object>[],
};

/// The quiz on the phone: downloaded once, answers kept on every tap, sent only
/// when the server can be reached, and removed only once the server confirms.
void main() {
  late bool online;
  late http.Response Function(http.Request) onSubmit;
  late List<Map<String, dynamic>> posts;
  late Map<String, dynamic> questionsPayload;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.setString('userId', _user);
    online = true;
    posts = [];
    questionsPayload = _questions();
    QuizSubmissionService.retryDelays = const [];
    onSubmit = (_) =>
        http.Response(jsonEncode({'attempt': _attempt()}), 201, headers: _json);
    ApiClient.clientOverride = MockClient((request) async {
      if (!online) throw const SocketException('no network');
      if (request.method == 'GET') {
        return http.Response(jsonEncode(questionsPayload), 200, headers: _json);
      }
      posts.add(jsonDecode(request.body) as Map<String, dynamic>);
      return onSubmit(request);
    });
  });

  tearDown(() {
    ApiClient.clientOverride = null;
    QuizSubmissionService.retryDelays = const [
      Duration(milliseconds: 800),
      Duration(milliseconds: 2400),
    ];
  });

  Future<QuizProvider> openQuiz({String language = 'en'}) async {
    final provider = QuizProvider();
    await provider.startQuiz(_quizId, language: language);
    return provider;
  }

  Future<QuizProgressRecord?> onPhone() async {
    await QuizOfflineStore.idle();
    return QuizOfflineStore.loadProgress(_user, _quizId);
  }

  group('saving the quiz on the phone', () {
    test('the questions are kept as soon as they are downloaded', () async {
      await openQuiz();
      expect(
        await QuizOfflineStore.loadSession(_user, _quizId),
        questionsPayload,
      );
      final record = (await onPhone())!;
      expect(record.questionIds, ['id-0', 'id-1', 'id-2']);
      expect(record.answers.values, everyElement(isNull));
      expect(record.submitPending, isFalse);
    });

    test('every answer and move is written down as it happens', () async {
      final provider = await openQuiz();
      provider.selectAnswer(2);
      provider.nextQuestion();
      provider.selectAnswer(1);
      final record = (await onPhone())!;
      expect(record.answers, {'id-0': 2, 'id-1': 1, 'id-2': null});
      expect(record.currentIndex, 1);
    });

    test('reopening continues with the earlier answers and position', () async {
      final first = await openQuiz();
      first.selectAnswer(3);
      first.goToQuestion(2);
      first.selectAnswer(0);
      await onPhone();

      final again = await openQuiz();
      expect(again.getSelectedAnswer('id-0'), 3);
      expect(again.getSelectedAnswer('id-2'), 0);
      expect(again.currentQuestionIndex, 2);
      expect(again.openedFromDevice, isFalse);
    });

    test(
      'answers to a question the server dropped are not carried over',
      () async {
        final first = await openQuiz();
        first.selectAnswer(3);
        await onPhone();
        questionsPayload = {
          ..._questions(),
          'questions': (_questions()['questions'] as List).sublist(1),
        };
        final again = await openQuiz();
        expect(again.totalQuestions, 2);
        expect(again.getSelectedAnswer('id-0'), isNull);
      },
    );

    test('another student gets none of it', () async {
      final first = await openQuiz();
      first.selectAnswer(3);
      await onPhone();
      await StorageService.setString('userId', 'student-2');
      final other = await openQuiz();
      expect(other.getSelectedAnswer('id-0'), isNull);
    });
  });

  group('losing the connection', () {
    test('the quiz opens from the phone with the earlier answers', () async {
      final first = await openQuiz();
      first.selectAnswer(1);
      await onPhone();

      online = false;
      final offline = await openQuiz();
      expect(offline.openedFromDevice, isTrue);
      expect(offline.isQuizActive, isTrue);
      expect(offline.totalQuestions, 3);
      expect(offline.getSelectedAnswer('id-0'), 1);
    });

    test(
      'with no saved copy it says so instead of showing an empty quiz',
      () async {
        online = false;
        final provider = QuizProvider();
        await expectLater(
          provider.startQuiz(_quizId),
          throwsA(
            isA<ApiException>().having(
              (e) => e.message,
              'message',
              contains('offline'),
            ),
          ),
        );
        expect(provider.hasSessionError, isTrue);
      },
    );

    test('a definite refusal is not hidden behind the saved copy', () async {
      await openQuiz();
      await onPhone();
      ApiClient.clientOverride = MockClient(
        (_) async => http.Response(
          jsonEncode({'message': 'Quiz is not live right now'}),
          403,
          headers: _json,
        ),
      );
      await expectLater(
        QuizProvider().startQuiz(_quizId),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 403)),
      );
    });

    test('"already attempted" drops the half-finished copy', () async {
      final first = await openQuiz();
      first.selectAnswer(2);
      await onPhone();
      ApiClient.clientOverride = MockClient(
        (_) async => http.Response(
          jsonEncode({'message': 'Already attempted'}),
          409,
          headers: _json,
        ),
      );
      await expectLater(
        QuizProvider().startQuiz(_quizId),
        throwsA(isA<ApiException>()),
      );
      expect(await onPhone(), isNull);
    });

    test(
      'the quiz clock runs from the server start, even with nothing saved',
      () async {
        // Opened 100 s ago (e.g. before the app data was cleared).
        final now = DateTime.now();
        questionsPayload = {
          ..._questions(overall: 300),
          'startedAt': now
              .subtract(const Duration(seconds: 100))
              .toIso8601String(),
          'serverNow': now.toIso8601String(),
        };
        final provider = await openQuiz();
        expect(
          QuizQuestionScreenProvider.secondsUntil(provider.overallDeadline!),
          inInclusiveRange(199, 201),
        );
      },
    );

    test("changing the phone's time does not change the time left", () async {
      final now = DateTime.now();
      questionsPayload = {
        ..._questions(overall: 300),
        'startedAt': now
            .subtract(const Duration(seconds: 100))
            .toIso8601String(),
        'serverNow': now.toIso8601String(),
      };
      // The phone's clock is an hour fast.
      final fast = Clock(() => DateTime.now().add(const Duration(hours: 1)));
      await withClock(fast, () async {
        final provider = await openQuiz();
        expect(
          QuizQuestionScreenProvider.secondsUntil(provider.overallDeadline!),
          inInclusiveRange(199, 201),
        );
      });
    });

    test('a saved copy keeps the clock when offline', () async {
      final now = DateTime.now();
      questionsPayload = {
        ..._questions(overall: 300),
        'startedAt': now
            .subtract(const Duration(seconds: 250))
            .toIso8601String(),
        'serverNow': now.toIso8601String(),
      };
      await openQuiz();
      await onPhone();
      online = false;
      final offline = await openQuiz();
      expect(offline.openedFromDevice, isTrue);
      expect(
        QuizQuestionScreenProvider.secondsUntil(offline.overallDeadline!),
        inInclusiveRange(49, 51),
      );
    });
  });

  group('submitting', () {
    test('success removes the copy from the phone', () async {
      final provider = await openQuiz();
      provider.selectAnswer(2);
      final attempt = await provider.submitQuiz();
      expect(attempt.attemptId, 'att-1');
      expect(
        [
          for (final a in posts.single['answers'] as List)
            [a['questionId'], a['attemptedAnswer']],
        ],
        [
          ['id-0', 2],
          ['id-1', null],
          ['id-2', null],
        ],
      );
      await QuizOfflineStore.idle();
      expect(await QuizOfflineStore.loadProgress(_user, _quizId), isNull);
      expect(await QuizOfflineStore.loadSession(_user, _quizId), isNull);
    });

    test(
      'no connection keeps every answer and marks it ready to send',
      () async {
        final provider = await openQuiz(language: 'ml');
        provider.selectAnswer(1);
        provider.nextQuestion();
        provider.selectAnswer(3);
        online = false;

        await expectLater(
          provider.submitQuiz(),
          throwsA(isA<SocketException>()),
        );

        final record = (await onPhone())!;
        expect(record.submitPending, isTrue);
        expect(record.answers, {'id-0': 1, 'id-1': 3, 'id-2': null});
        expect(record.totalDuration, isNotNull);
        expect(await QuizOfflineStore.loadSession(_user, _quizId), isNotNull);
        expect((await QuizOfflineStore.pending(_user)).single.quizId, _quizId);
      },
    );

    test('a server error keeps the answers too', () async {
      final provider = await openQuiz();
      provider.selectAnswer(0);
      onSubmit = (_) => http.Response(
        jsonEncode({'message': 'Internal server error'}),
        500,
        headers: _json,
      );
      await expectLater(provider.submitQuiz(), throwsA(isA<ApiException>()));
      expect((await onPhone())!.answers['id-0'], 0);
      expect((await QuizOfflineStore.pending(_user)), hasLength(1));
    });

    test(
      'a retry after the first reply was lost shows the saved result',
      () async {
        final provider = await openQuiz();
        provider.selectAnswer(2);
        onSubmit = (_) => http.Response(
          jsonEncode({'message': 'Already attempted', 'attempt': _attempt()}),
          409,
          headers: _json,
        );
        final attempt = await provider.submitQuiz();
        expect(attempt.score, 2);
        expect(await onPhone(), isNull);
      },
    );

    test('a final refusal keeps the answers but stops retrying', () async {
      final provider = await openQuiz();
      provider.selectAnswer(2);
      onSubmit = (_) => http.Response(
        jsonEncode({'message': 'Quiz is not live right now'}),
        403,
        headers: _json,
      );
      await expectLater(provider.submitQuiz(), throwsA(isA<ApiException>()));
      final record = (await onPhone())!;
      expect(record.rejectedStatus, 403);
      expect(record.answers['id-0'], 2);
      expect(await QuizOfflineStore.pending(_user), isEmpty);
    });

    test('a busy server is retried on its own before giving up', () async {
      QuizSubmissionService.retryDelays = const [Duration.zero, Duration.zero];
      final provider = await openQuiz();
      provider.selectAnswer(2);
      var calls = 0;
      onSubmit = (_) {
        calls++;
        return calls < 3
            ? http.Response(
                jsonEncode({'message': 'Service unavailable'}),
                503,
                headers: _json,
              )
            : http.Response(
                jsonEncode({'attempt': _attempt()}),
                201,
                headers: _json,
              );
      };
      final attempt = await provider.submitQuiz();
      expect(attempt.attemptId, 'att-1');
      expect(posts, hasLength(3));
      expect(await onPhone(), isNull);
    });

    test('pressing Submit twice never changes the time taken', () async {
      final provider = await openQuiz();
      online = false;
      await expectLater(provider.submitQuiz(), throwsA(anything));
      final first = (await onPhone())!.totalDuration;
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      await expectLater(provider.submitQuiz(), throwsA(anything));
      expect((await onPhone())!.totalDuration, first);
    });
  });

  group('sending answers that were waiting', () {
    Future<QuizProvider> failedSubmit() async {
      final provider = await openQuiz();
      provider.selectAnswer(2);
      online = false;
      await expectLater(provider.submitQuiz(), throwsA(anything));
      // The student leaves the quiz screen ("Later"), which ends the session.
      provider.resetSession();
      await QuizOfflineStore.idle();
      return provider;
    }

    test('the quiz still open on screen is left to its own submit', () async {
      final provider = await openQuiz();
      provider.selectAnswer(2);
      online = false;
      await expectLater(provider.submitQuiz(), throwsA(anything));
      online = true;

      expect(await provider.flushPendingSubmissions(), isFalse);
      expect(posts, isEmpty);

      provider.resetSession(); // the quiz screen closes
      expect(await provider.flushPendingSubmissions(), isTrue);
      expect(posts, hasLength(1));
    });

    test(
      'they go out once the connection is back, and the copy is removed',
      () async {
        final provider = await failedSubmit();
        online = true;

        expect(await provider.flushPendingSubmissions(), isTrue);

        expect(posts.single['quizId'], _quizId);
        expect(
          posts.single['answers'].first,
          allOf(
            containsPair('questionId', 'id-0'),
            containsPair('attemptedAnswer', 2),
          ),
        );
        expect(provider.pendingSubmissions, isEmpty);
        expect(await onPhone(), isNull);
      },
    );

    test(
      'while offline they stay, and the list shows them as waiting',
      () async {
        final provider = await failedSubmit();
        expect(await provider.flushPendingSubmissions(), isFalse);
        expect(provider.pendingSubmissions.single.title, 'Weekly Quiz');
        expect(await onPhone(), isNotNull);
      },
    );

    test('opening the quiz list sends them without any extra step', () async {
      final provider = await failedSubmit();
      ApiClient.clientOverride = MockClient((request) async {
        if (request.method == 'POST') {
          posts.add(jsonDecode(request.body) as Map<String, dynamic>);
          return http.Response(
            jsonEncode({'attempt': _attempt()}),
            201,
            headers: _json,
          );
        }
        return http.Response('[]', 200, headers: _json);
      });
      await provider.fetchQuizList();
      expect(posts, hasLength(1));
      expect(provider.pendingSubmissions, isEmpty);
      expect(provider.listState, QuizLoadingState.loaded);
    });

    test(
      'signing out hides them from the screen but not from the phone',
      () async {
        final provider = await failedSubmit();
        await provider.flushPendingSubmissions();
        provider.clear();
        expect(provider.pendingSubmissions, isEmpty);
        expect(await QuizOfflineStore.pending(_user), hasLength(1));
      },
    );
  });
}
