import 'package:flutter_test/flutter_test.dart';
import 'package:qspot/services/video_progress_service.dart';

void main() {
  group('VideoProgressStatus.fromJson', () {
    test('parses every field from the contract shape', () {
      final status = VideoProgressStatus.fromJson({
        'videoId': 'v1',
        'positionSeconds': 42,
        'maxPositionSeconds': 50,
        'watchedSeconds': 40,
        'durationSeconds': 100,
        'completed': false,
        'completedAt': null,
        'lastViewedAt': '2026-01-01T10:00:00.000Z',
        'status': 'in-progress',
        'questionCount': 3,
        'quizAttempted': false,
      });

      expect(status.videoId, 'v1');
      expect(status.positionSeconds, 42);
      expect(status.maxPositionSeconds, 50);
      expect(status.watchedSeconds, 40);
      expect(status.durationSeconds, 100);
      expect(status.completed, isFalse);
      expect(status.status, 'in-progress');
      expect(status.questionCount, 3);
      expect(status.hasQuestions, isTrue);
      expect(status.quizAttempted, isFalse);
      expect(status.lastViewedAt, isNotNull);
    });

    test('defaults missing fields to zero/false/not-started', () {
      final status = VideoProgressStatus.fromJson({'videoId': 'v2'});

      expect(status.positionSeconds, 0);
      expect(status.durationSeconds, 0);
      expect(status.completed, isFalse);
      expect(status.status, 'not-started');
      expect(status.hasQuestions, isFalse);
    });

    test('resume percent is driven by positionSeconds, not watchedSeconds', () {
      final status = VideoProgressStatus.fromJson({
        'videoId': 'v3',
        'positionSeconds': 25,
        'watchedSeconds': 90,
        'durationSeconds': 100,
        'completed': false,
      });

      // The resume bar should reflect where playback left off (25%), not how
      // much was watched in total (90%).
      expect(status.percent, closeTo(0.25, 0.0001));
    });

    test('a completed video always reports 100% regardless of position', () {
      final status = VideoProgressStatus.fromJson({
        'videoId': 'v4',
        'positionSeconds': 10,
        'durationSeconds': 100,
        'completed': true,
      });

      expect(status.percent, 1.0);
    });
  });

  group('VideoProgressService.heartbeatBody', () {
    test(
      'never includes an "ended" key (no ended shortcut in the contract)',
      () {
        final body = VideoProgressService.heartbeatBody(
          videoId: 'v1',
          position: 30,
          watchedDelta: 5,
          duration: 120,
        );

        expect(body.containsKey('ended'), isFalse);
        expect(body, {
          'videoId': 'v1',
          'position': 30,
          'watchedDelta': 5,
          'duration': 120,
        });
      },
    );

    test('omits duration entirely when not known yet', () {
      final body = VideoProgressService.heartbeatBody(
        videoId: 'v1',
        position: 10,
        watchedDelta: 2,
      );

      expect(body.containsKey('duration'), isFalse);
      expect(body.containsKey('ended'), isFalse);
    });
  });

  group('VideoQuestionItem', () {
    test('never carries a correct answer field', () {
      final question = VideoQuestionItem.fromJson({
        '_id': 'q1',
        'question_en': 'What is this about?',
        'question_ml': '',
        'options_en': ['A', 'B'],
        'options_ml': [],
      });

      expect(question.id, 'q1');
      expect(question.optionsFor('en'), ['A', 'B']);
      // There is intentionally no `correctAnswer` getter/field to assert on —
      // the server never sends one, so the model has nothing to expose.
    });
  });
}
