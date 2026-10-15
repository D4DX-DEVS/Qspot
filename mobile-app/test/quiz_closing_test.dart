import 'dart:convert';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:qspot/screens/quiz/model/quiz_progress_record.dart';
import 'package:qspot/screens/quiz/provider/quiz_provider.dart';
import 'package:qspot/screens/quiz/provider/quiz_question_screen_provider.dart';
import 'package:qspot/screens/quiz/provider/quiz_timing_tracker.dart';
import 'package:qspot/services/api_client.dart';
import 'package:qspot/services/common/storage_service.dart';
import 'package:qspot/services/quiz_offline_store.dart';
import 'package:qspot/services/quiz_submission_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _json = {'content-type': 'application/json'};

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

/// The quiz stops at its end time, warns before it, and tells the student
/// plainly when answers reached the server too late to be marked.
void main() {
  final t0 = DateTime(2026, 10, 14, 10);

  group('closing time', () {
    test('the end time is lined up with the phone clock and stops answers', () {
      final t = QuizTimingTracker()
        ..load(
          questionIds: const ['a'],
          localStart: t0,
          endsAt: t0.add(const Duration(minutes: 10)),
          offsetMs: 60000, // phone is a minute behind the server
        )
        ..show('a', t0);
      expect(t.closingDeadline, t0.add(const Duration(minutes: 9)));
      expect(t.isOpen('a', t0.add(const Duration(minutes: 8))), isTrue);
      expect(t.isOpen('a', t0.add(const Duration(minutes: 9))), isFalse);
    });

    test('the warning shows only in the last five minutes', () {
      var now = t0;
      withClock(Clock(() => now), () {
        final q = QuizQuestionScreenProvider()
          ..startTimers(closingDeadline: t0.add(const Duration(minutes: 6)));
        expect(q.closingWarning, isNull);
        now = t0.add(const Duration(minutes: 1, seconds: 1));
        q.tick();
        expect(q.closingWarning, 299);
      });
    });

    test('the warning stays hidden when the quiz time runs out first', () {
      withClock(Clock.fixed(t0), () {
        final q = QuizQuestionScreenProvider()
          ..startTimers(
            overallDeadline: t0.add(const Duration(minutes: 2)),
            closingDeadline: t0.add(const Duration(minutes: 4)),
          );
        expect(q.closingWarning, isNull);
      });
    });

    test('closing is reported once, like the quiz time running out', () {
      var now = t0;
      withClock(Clock(() => now), () {
        final q = QuizQuestionScreenProvider()
          ..startTimers(closingDeadline: t0.add(const Duration(seconds: 2)));
        now = t0.add(const Duration(seconds: 2));
        expect(q.tick(), QuizTimerExpiry.closing);
        expect(q.tick(), QuizTimerExpiry.none);
      });
    });

    test('no answer is taken after the quiz has closed', () {
      var now = t0;
      withClock(Clock(() => now), () {
        final p = QuizProvider()
          ..seedSessionForTest(
            _questions(1),
            endsAt: t0.add(const Duration(seconds: 30)),
          );
        now = t0.add(const Duration(seconds: 31));
        p.selectAnswer(2);
        expect(p.getSelectedAnswer('id-0'), isNull);
      });
    });
  });

  group('too late', () {
    late bool online;
    late http.Response Function() onSubmit;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await StorageService.setString('userId', 'u1');
      online = true;
      onSubmit = _accepted;
      QuizSubmissionService.retryDelays = const [];
      ApiClient.clientOverride = MockClient((request) async {
        if (!online) throw const SocketException('no network');
        if (request.method == 'GET') {
          return http.Response(
            jsonEncode({'title': 'Weekly Quiz', 'questions': _questions(2)}),
            200,
            headers: _json,
          );
        }
        return onSubmit();
      });
    });
    tearDown(() {
      ApiClient.clientOverride = null;
      QuizSubmissionService.retryDelays = const [
        Duration(milliseconds: 800),
        Duration(milliseconds: 2400),
      ];
    });

    test(
      'answers sent after the quiz closed are reported, then dismissed',
      () async {
        final p = QuizProvider();
        await p.startQuiz('q1');
        p.selectAnswer(1);
        online = false;
        await expectLater(p.submitQuiz(), throwsA(anything));
        p.resetSession(); // the student leaves the quiz screen

        // Back online, but past the grace period.
        online = true;
        onSubmit = _tooLate;
        await p.flushPendingSubmissions();

        expect(p.pendingSubmissions, isEmpty, reason: 'no point retrying');
        expect(p.refusedSubmissions.single.title, 'Weekly Quiz');
        expect(p.refusedSubmissions.single.arrivedTooLate, isTrue);

        await p.dismissRefused('q1');
        expect(p.refusedSubmissions, isEmpty);
        expect(await QuizOfflineStore.loadProgress('u1', 'q1'), isNull);
      },
    );

    test('other refusals are reported too, with their own reason', () async {
      final p = QuizProvider();
      await p.startQuiz('q1');
      onSubmit = () => http.Response(
        jsonEncode({
          'message': 'Quiz is not live right now',
          'code': 'QUIZ_DISABLED',
        }),
        403,
        headers: _json,
      );
      await expectLater(p.submitQuiz(), throwsA(isA<ApiException>()));
      p.resetSession();
      await p.flushPendingSubmissions();

      final record = p.refusedSubmissions.single;
      expect(record.arrivedTooLate, isFalse);
      expect(record.rejectedCode, QuizProgressRecord.switchedOffCode);
      expect(record.canRetake, isFalse);
    });
  });
}
