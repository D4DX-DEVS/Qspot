import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:qspot/screens/quiz/model/question_timing.dart';
import 'package:qspot/screens/quiz/model/quiz_progress_record.dart';
import 'package:qspot/screens/quiz/provider/quiz_provider.dart';
import 'package:qspot/services/api_client.dart';
import 'package:qspot/services/common/storage_service.dart';
import 'package:qspot/services/quiz_offline_store.dart';
import 'package:qspot/services/quiz_reminder_service.dart';
import 'package:qspot/services/quiz_submission_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _json = {'content-type': 'application/json'};
final _t0 = DateTime(2026, 10, 14, 10);
DateTime _at(int minutes) => _t0.add(Duration(minutes: minutes));

QuizProgressRecord _record({
  String quizId = 'q1',
  Map<String, int?> answers = const {'a': 1, 'b': null},
  bool submitPending = false,
  int? rejectedStatus,
  DateTime? endsAt,
  bool noEndTime = false,
  DateTime? startedAt,
}) => QuizProgressRecord(
  quizId: quizId,
  title: 'Weekly Quiz',
  questionIds: const ['a', 'b'],
  answers: answers,
  language: 'en',
  startedAt: startedAt ?? _at(0),
  submitPending: submitPending,
  rejectedStatus: rejectedStatus,
  endsAt: noEndTime ? null : (endsAt ?? _at(30)),
  savedAt: _at(12),
  timings: {
    'a': const QuestionTiming().shown(_at(0)).hidden(_at(4)),
    // On screen when the app was killed.
    'b': const QuestionTiming().shown(_at(10)),
  },
);

/// A quiz left open but unsubmitted when it closed is sent the next time the
/// app opens; a reminder fires shortly before a started quiz closes.
void main() {
  group('a quiz that closed while the app was shut', () {
    test('is spotted only once its end time has passed', () {
      final r = _record();
      expect(r.closedUnsubmitted(_at(29)), isFalse);
      expect(r.closedUnsubmitted(_at(31)), isTrue);
      expect(_record(submitPending: true).closedUnsubmitted(_at(31)), isFalse);
      expect(_record(rejectedStatus: 403).closedUnsubmitted(_at(31)), isFalse);
    });

    test('becomes final as the answers stood when the app last ran', () {
      final sealed = _record().sealedAfterClose();
      expect(sealed.submitPending, isTrue);
      expect(sealed.isRetryable, isTrue);
      expect(sealed.answers, {'a': 1, 'b': null});
      expect(sealed.totalDuration, 12 * 60, reason: 'start to last save');
      expect(sealed.timings['b']!.visibleSince, isNull);
      expect(sealed.timings['b']!.spentMs, 2 * 60 * 1000);
    });

    group('when the app opens', () {
      late List<Map<String, dynamic>> posts;
      late http.Response Function() reply;

      setUp(() async {
        SharedPreferences.setMockInitialValues({});
        await StorageService.setString('userId', 'u1');
        posts = [];
        reply = () => http.Response(
          jsonEncode({
            'attempt': {
              'attemptId': 'x',
              'quizId': 'q1',
              'score': 1,
              'totalQuestions': 2,
              'percentage': 50,
              'results': <Object>[],
            },
          }),
          201,
          headers: _json,
        );
        QuizSubmissionService.retryDelays = const [];
        ApiClient.clientOverride = MockClient((request) async {
          if (request.method == 'GET') return http.Response('[]', 200);
          posts.add(jsonDecode(request.body) as Map<String, dynamic>);
          return reply();
        });
      });
      tearDown(() => ApiClient.clientOverride = null);

      Future<bool> openApp(DateTime now) =>
          withClock(Clock.fixed(now), QuizProvider().flushPendingSubmissions);

      test('its answers are sent and the copy is removed', () async {
        await QuizOfflineStore.saveProgress('u1', _record());
        expect(await openApp(_at(32)), isTrue);
        expect(posts.single['answers'], [
          {'questionId': 'a', 'attemptedAnswer': 1, 'duration': 240.0},
          {'questionId': 'b', 'attemptedAnswer': null, 'duration': 120.0},
        ]);
        expect(await QuizOfflineStore.loadProgress('u1', 'q1'), isNull);
      });

      test('too late is reported, not lost in silence', () async {
        reply = () => http.Response(
          jsonEncode({'message': 'closed', 'code': 'QUIZ_CLOSED'}),
          403,
          headers: _json,
        );
        await QuizOfflineStore.saveProgress('u1', _record());
        final p = QuizProvider();
        await withClock(Clock.fixed(_at(60)), p.flushPendingSubmissions);
        expect(p.refusedSubmissions.single.quizId, 'q1');
      });

      test('a quiz still open is left for the student to finish', () async {
        await QuizOfflineStore.saveProgress('u1', _record());
        await openApp(_at(20));
        expect(posts, isEmpty);
        expect(
          (await QuizOfflineStore.loadProgress('u1', 'q1'))!.submitPending,
          isFalse,
        );
      });

      test(
        'a quiz opened but never answered is not sent as an empty attempt',
        () async {
          await QuizOfflineStore.saveProgress(
            'u1',
            _record(answers: const {'a': null, 'b': null}),
          );
          await openApp(_at(32));
          expect(posts, isEmpty);
          // Nothing to send once the quiz is over, so the copy is deleted.
          expect(await QuizOfflineStore.loadProgress('u1', 'q1'), isNull);
        },
      );

      test('an unanswered copy of a quiz still open is kept', () async {
        await QuizOfflineStore.saveProgress(
          'u1',
          _record(answers: const {'a': null, 'b': null}),
        );
        await openApp(_at(20));
        expect(await QuizOfflineStore.loadProgress('u1', 'q1'), isNotNull);
      });

      test(
        'an unanswered copy with no end time saved goes after 30 days',
        () async {
          await QuizOfflineStore.saveProgress(
            'u1',
            _record(quizId: 'old', answers: const {'a': null}, noEndTime: true),
          );
          await QuizOfflineStore.saveProgress(
            'u1',
            _record(
              quizId: 'recent',
              answers: const {'a': null},
              noEndTime: true,
              startedAt: _at(0).add(const Duration(days: 2)),
            ),
          );
          await openApp(_at(0).add(const Duration(days: 31)));
          expect(await QuizOfflineStore.loadProgress('u1', 'old'), isNull);
          expect(
            await QuizOfflineStore.loadProgress('u1', 'recent'),
            isNotNull,
          );
        },
      );
    });
  });

  group('reminder', () {
    test('fires five minutes before the quiz closes', () {
      expect(QuizReminderService.remindAt(_at(30), _at(0)), _at(25));
    });

    test('is skipped when less than five minutes are left', () {
      expect(QuizReminderService.remindAt(_at(30), _at(26)), isNull);
    });

    test('keeps one id per quiz, apart from other reminders', () {
      final id = QuizReminderService.idFor('66f1a2b3c4d5e6f7a8b9c0d1');
      expect(QuizReminderService.idFor('66f1a2b3c4d5e6f7a8b9c0d1'), id);
      expect(QuizReminderService.idFor('66f1a2b3c4d5e6f7a8b9c0d2'), isNot(id));
      expect(id, greaterThan(1 << 30));
      expect(id, lessThan(1 << 31));
    });
  });
}
