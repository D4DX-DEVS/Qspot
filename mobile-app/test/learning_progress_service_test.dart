import 'package:flutter_test/flutter_test.dart';
import 'package:qspot/services/learning_progress_service.dart';

void main() {
  test('parses mastery and assessment activity from progress', () {
    final data = LearningProgressData.fromJson(
      {
        'videos': {'total': 4, 'completed': 3, 'inProgress': 1},
        'courses': [
          {'courseId': 'c1', 'title': 'Foundation', 'total': 4, 'completed': 3},
        ],
        'subjects': [
          {'subjectId': 's1', 'name': 'Tajweed', 'total': 2, 'completed': 2},
          {'subjectId': 's2', 'name': 'Seerah', 'total': 2, 'completed': 1},
        ],
        'quizAttempts': [
          {
            'title': 'Checkpoint',
            'score': 4,
            'totalQuestions': 5,
            'percentage': 80,
            'createdAt': '2026-09-23T10:00:00Z',
          },
        ],
        'videoQuizzes': [
          {
            'title': 'Lesson questions',
            'score': 2,
            'totalQuestions': 2,
            'percentage': 100,
            'createdAt': '2026-09-22T10:00:00Z',
          },
        ],
      },
      {
        'currentStreak': 5,
        'longestStreak': 9,
        'xp': 120,
        'level': 2,
        'lastActivityDate': '2026-09-23',
      },
    );

    expect(data.masteryPercent, 0.75);
    expect(data.courses.single.percent, 0.75);
    expect(data.subjects.first.title, 'Tajweed');
    expect(data.activities, hasLength(2));
    expect(data.activities.first.kind, 'quiz');
    expect(data.activities.last.isVideoQuiz, isTrue);
    expect(data.stats?.currentStreak, 5);
    expect(data.stats?.longestStreak, 9);
    expect(data.stats?.xp, 120);
  });

  test('malformed optional fields do not invent progress', () {
    final data = LearningProgressData.fromJson({
      'videos': 'unexpected',
      'courses': null,
      'subjects': [
        {'subjectId': '', 'name': 'Missing id', 'total': 2, 'completed': 5},
      ],
      'quizAttempts': 'unexpected',
      'videoQuizzes': [],
    }, null);

    expect(data.videosTotal, 0);
    expect(data.masteryPercent, 0);
    expect(data.courses, isEmpty);
    expect(data.subjects, isEmpty);
    expect(data.activities, isEmpty);
    expect(data.stats, isNull);
  });

  test(
    'marked assignments join the quizzes in recent activity, newest first',
    () {
      final data = LearningProgressData.fromJson(
        {
          'quizAttempts': [
            {
              'title': 'Checkpoint',
              'score': 4,
              'totalQuestions': 5,
              'percentage': 80,
              'createdAt': '2026-10-08T10:00:00Z',
            },
          ],
        },
        null,
        assignmentActivities: [
          ProgressActivity(
            kind: 'assignment',
            title: 'Steps of wudu',
            score: 82,
            totalQuestions: 100,
            percentage: 82,
            createdAt: DateTime.parse('2026-10-12T10:00:00Z'),
            detail: '82/100 points - 82%',
          ),
        ],
      );

      expect(data.activities.map((a) => a.title), [
        'Steps of wudu',
        'Checkpoint',
      ]);
      expect(data.activities.first.isAssignment, isTrue);
      expect(data.activities.first.detail, '82/100 points - 82%');
      expect(data.activities.last.isAssignment, isFalse);
      expect(data.activities.last.detail, isNull);
    },
  );
}
