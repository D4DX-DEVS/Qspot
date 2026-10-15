import 'dart:convert';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:qspot/screens/quiz/provider/quiz_provider.dart';
import 'package:qspot/services/api_client.dart';
import 'package:qspot/services/common/storage_service.dart';
import 'package:qspot/services/quiz_submission_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _json = {'content-type': 'application/json'};

Map<String, dynamic> _question(int i) => {
  '_id': 'id-$i',
  'type': 'Multiple Choice',
  'question_en': 'Question $i',
  'options_en': ['A', 'B', 'C', 'D'],
  'difficulty': 'easy',
};

/// What the quiz records about time, and how it holds the time limits.
void main() {
  final t0 = DateTime(2026, 10, 14, 10);
  late DateTime now;
  late bool online;
  late List<Map<String, dynamic>> posts;
  late Map<String, dynamic> payload;

  void later(int seconds) => now = now.add(Duration(seconds: seconds));
  Future<T> onClock<T>(Future<T> Function() body) =>
      withClock(Clock(() => now), body);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.setString('userId', 'u1');
    now = t0;
    online = true;
    posts = [];
    QuizSubmissionService.retryDelays = const [];
    payload = {
      'title': 'Timed Quiz',
      'timerMode': 'per-question',
      'perQuestionTimeLimit': 30,
      'questions': [for (var i = 0; i < 3; i++) _question(i)],
    };
    ApiClient.clientOverride = MockClient((request) async {
      if (!online) throw const SocketException('no network');
      if (request.method == 'GET') {
        return http.Response(
          jsonEncode({
            ...payload,
            'startedAt': t0.toIso8601String(),
            'serverNow': now.toIso8601String(),
          }),
          200,
          headers: _json,
        );
      }
      posts.add(jsonDecode(request.body) as Map<String, dynamic>);
      return http.Response(
        jsonEncode({
          'attempt': {
            'attemptId': 'a1',
            'quizId': 'q1',
            'score': 1,
            'totalQuestions': 3,
            'percentage': 33,
            'results': <Object>[],
          },
        }),
        201,
        headers: _json,
      );
    });
  });
  tearDown(() {
    ApiClient.clientOverride = null;
    QuizSubmissionService.retryDelays = const [
      Duration(milliseconds: 800),
      Duration(milliseconds: 2400),
    ];
  });

  Future<QuizProvider> open() async {
    final provider = QuizProvider();
    await provider.startQuiz('q1');
    return provider;
  }

  test('time taken to answer is recorded per question', () async {
    await onClock(() async {
      payload['timerMode'] = 'none';
      final p = await open();
      later(4);
      p.selectAnswer(1);
      later(2);
      p.selectAnswer(2); // final answer at 6 s
      later(1);
      p.nextQuestion();
      later(5);
      p.previousQuestion(); // back to the first question, no change
      later(3);
      p.nextQuestion();

      expect(p.timingOf('id-0').timeTakenMs, 6000);
      expect(p.timingOf('id-0').spentMs, 10000);
      expect(p.timingOf('id-1').timeTakenMs, 5000, reason: 'unanswered');
      expect(p.timingOf('id-2').timeTakenMs, 0, reason: 'not reached');
    });
  });

  test("no answer is taken after a question's time is up", () async {
    await onClock(() async {
      final p = await open();
      later(29);
      p.selectAnswer(1);
      later(2);
      p.selectAnswer(3);
      expect(p.getSelectedAnswer('id-0'), 1);
    });
  });

  test('no answer is taken after the whole quiz time is up', () async {
    await onClock(() async {
      payload
        ..['timerMode'] = 'overall'
        ..['overallTimeLimit'] = 60;
      final p = await open();
      later(61);
      p.selectAnswer(2);
      expect(p.getSelectedAnswer('id-0'), isNull);
    });
  });

  test(
    'a question that runs out is skipped; the next one starts then',
    () async {
      await onClock(() async {
        final p = await open();
        later(10);
        p.selectAnswer(2);
        later(20);
        expect(p.timeOutCurrentQuestion(), isTrue);

        expect(p.currentQuestionIndex, 1);
        expect(p.timingOf('id-0').timedOut, isTrue);
        expect(p.getSelectedAnswer('id-0'), 2, reason: 'picked in time, kept');
        expect(p.questionDeadline, now.add(const Duration(seconds: 30)));
      });
    },
  );

  test('the last question running out asks for the submit', () async {
    await onClock(() async {
      final p = await open();
      p.goToQuestion(2);
      later(30);
      expect(p.timeOutCurrentQuestion(), isFalse);
      expect(p.timingOf('id-2').timedOut, isTrue);
    });
  });

  test(
    'background time does not count as on screen, but the countdown runs',
    () async {
      await onClock(() async {
        final p = await open();
        later(5);
        p.pauseVisit();
        later(40);
        p.resumeVisit();
        expect(p.timingOf('id-0').spentMs, 5000);
        expect(p.questionDeadline, t0.add(const Duration(seconds: 30)));
        p.selectAnswer(1);
        expect(p.getSelectedAnswer('id-0'), isNull, reason: 'time ran out');
      });
    },
  );

  test('the submission carries only the time taken per question', () async {
    await onClock(() async {
      final p = await open();
      later(7);
      p.selectAnswer(0);
      later(4);
      p.nextQuestion();
      later(30);
      p.timeOutCurrentQuestion();
      later(3);
      await p.submitQuiz();

      final body = posts.single;
      expect(
        body.keys,
        unorderedEquals(['quizId', 'language', 'answers', 'totalDuration']),
      );
      expect(body['totalDuration'], 44);
      expect(body['answers'], [
        {'questionId': 'id-0', 'attemptedAnswer': 0, 'duration': 7.0},
        {'questionId': 'id-1', 'attemptedAnswer': null, 'duration': 30.0},
        {'questionId': 'id-2', 'attemptedAnswer': null, 'duration': 3.0},
      ]);
    });
  });

  test(
    'reopening after the app was killed keeps every clock running',
    () async {
      await onClock(() async {
        final first = await open();
        later(6);
        first.selectAnswer(1); // last save: 6 s in
        later(60); // killed, reopened a minute later

        final again = await open();
        final timing = again.timingOf('id-0');
        expect(timing.spentMs, 6000, reason: 'closed at the last save');
        expect(timing.timeTakenMs, 6000, reason: 'answered at 6 s');
        expect(again.questionDeadline, t0.add(const Duration(seconds: 30)));
        again.selectAnswer(3);
        expect(again.getSelectedAnswer('id-0'), 1, reason: 'its time is up');
      });
    },
  );
}
