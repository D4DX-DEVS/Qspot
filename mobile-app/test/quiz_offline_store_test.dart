import 'package:flutter_test/flutter_test.dart';
import 'package:qspot/screens/quiz/model/quiz_progress_record.dart';
import 'package:qspot/services/quiz_offline_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

QuizProgressRecord _record(
  String quizId, {
  bool submitPending = false,
  int? rejectedStatus,
  DateTime? startedAt,
}) => QuizProgressRecord(
  quizId: quizId,
  title: 'Quiz $quizId',
  questionIds: const ['a', 'b', 'c'],
  answers: const {'a': 2, 'b': null, 'c': 0},
  language: 'ml',
  startedAt: startedAt ?? DateTime.utc(2026, 10, 14, 10),
  currentIndex: 1,
  submitPending: submitPending,
  totalDuration: submitPending ? 75 : null,
  rejectedStatus: rejectedStatus,
);

/// What is kept on the phone while a quiz is taken.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('the questions come back exactly as saved', () async {
    final session = {
      'title': 'Quiz',
      'questions': [
        {'_id': 'a', 'question_en': 'Q?'},
      ],
    };
    expect(await QuizOfflineStore.saveSession('u1', 'q1', session), isTrue);
    expect(await QuizOfflineStore.loadSession('u1', 'q1'), session);
  });

  test('answers, position and start time round-trip', () async {
    await QuizOfflineStore.saveProgress('u1', _record('q1'));
    final back = (await QuizOfflineStore.loadProgress('u1', 'q1'))!;
    expect(back.answers, {'a': 2, 'b': null, 'c': 0});
    expect(back.questionIds, ['a', 'b', 'c']);
    expect(back.currentIndex, 1);
    expect(back.language, 'ml');
    expect(back.startedAt, DateTime.utc(2026, 10, 14, 10));
    expect(back.submitPending, isFalse);
  });

  test('nothing saved reads as null, not an error', () async {
    expect(await QuizOfflineStore.loadSession('u1', 'nope'), isNull);
    expect(await QuizOfflineStore.loadProgress('u1', 'nope'), isNull);
    expect(await QuizOfflineStore.pending('u1'), isEmpty);
  });

  test('a damaged entry is ignored instead of breaking the quiz', () async {
    SharedPreferences.setMockInitialValues({
      'quiz_offline_progress_u1_q1': '{not json',
      'quiz_offline_session_u1_q1': '[1,2]',
    });
    expect(await QuizOfflineStore.loadProgress('u1', 'q1'), isNull);
    expect(await QuizOfflineStore.loadSession('u1', 'q1'), isNull);
    expect(await QuizOfflineStore.pending('u1'), isEmpty);
  });

  test('another student on this phone never sees these answers', () async {
    await QuizOfflineStore.saveProgress('u1', _record('q1'));
    await QuizOfflineStore.saveSession('u1', 'q1', {'title': 'x'});
    expect(await QuizOfflineStore.loadProgress('u2', 'q1'), isNull);
    expect(await QuizOfflineStore.loadSession('u2', 'q1'), isNull);
  });

  test(
    'pending lists only submitted, not refused, answers, oldest first',
    () async {
      await QuizOfflineStore.saveProgress('u1', _record('midway'));
      await QuizOfflineStore.saveProgress(
        'u1',
        _record(
          'late',
          submitPending: true,
          startedAt: DateTime.utc(2026, 10, 14, 12),
        ),
      );
      await QuizOfflineStore.saveProgress(
        'u1',
        _record(
          'early',
          submitPending: true,
          startedAt: DateTime.utc(2026, 10, 14, 9),
        ),
      );
      await QuizOfflineStore.saveProgress(
        'u1',
        _record('refused', submitPending: true, rejectedStatus: 403),
      );
      await QuizOfflineStore.saveProgress(
        'u2',
        _record('other', submitPending: true),
      );

      final pending = await QuizOfflineStore.pending('u1');
      expect(pending.map((r) => r.quizId), ['early', 'late']);
      // The refused one is not retried, but it is still on the phone.
      expect(await QuizOfflineStore.loadProgress('u1', 'refused'), isNotNull);
    },
  );

  test(
    'clear removes the questions and the answers of that quiz only',
    () async {
      for (final id in ['q1', 'q2']) {
        await QuizOfflineStore.saveSession('u1', id, {'title': id});
        await QuizOfflineStore.saveProgress('u1', _record(id));
      }
      await QuizOfflineStore.clear('u1', 'q1');
      expect(await QuizOfflineStore.loadSession('u1', 'q1'), isNull);
      expect(await QuizOfflineStore.loadProgress('u1', 'q1'), isNull);
      expect(await QuizOfflineStore.loadSession('u1', 'q2'), isNotNull);
      expect(await QuizOfflineStore.loadProgress('u1', 'q2'), isNotNull);
    },
  );

  test('a write started before clear can never bring the quiz back', () async {
    // Not awaited on purpose: like a tap just before the result arrives.
    final late = QuizOfflineStore.saveProgress('u1', _record('q1'));
    final cleared = QuizOfflineStore.clear('u1', 'q1');
    await Future.wait([late, cleared]);
    expect(await QuizOfflineStore.loadProgress('u1', 'q1'), isNull);
  });
}
