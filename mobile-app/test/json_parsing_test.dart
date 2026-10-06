import 'package:flutter_test/flutter_test.dart';
import 'package:qspot/screens/quiz/model/quiz_model.dart';
import 'package:qspot/screens/subject/model/subject_model.dart';
import 'package:qspot/screens/video/model/video_model.dart';
import 'package:qspot/services/learning_progress_service.dart';
import 'package:qspot/services/navigation_config_service.dart';
import 'package:qspot/services/today_service.dart';
import 'package:qspot/services/video_progress_service.dart';
import 'package:qspot/utils/json_parsing.dart';

void main() {
  test('subject and video models tolerate numeric strings from the API', () {
    final subject = SubjectModel.fromJson({
      '_id': 'subject-1',
      'name': 'Quran Recitation',
      'order': '3',
    });
    expect(subject.order, 3);

    final video = VideoModel.fromJson({
      '_id': 'video-1',
      'description': 'Lesson',
      'video': 'https://example.invalid/video.mp4',
      'order': '2',
      'durationSeconds': '90',
      'questionCount': '4',
      'progress': '12',
    });
    expect(video.order, 2);
    expect(video.durationSeconds, 90);
    expect(video.questionCount, 4);
    expect(video.progress, 12);
  });

  test('video progress falls back safely for malformed numeric values', () {
    final progress = VideoProgressStatus.fromJson({
      'videoId': 'video-1',
      'positionSeconds': 'not-a-number',
      'durationSeconds': null,
      'questionCount': 'invalid',
    });
    expect(progress.positionSeconds, 0);
    expect(progress.durationSeconds, 0);
    expect(progress.questionCount, 0);
  });

  test(
    'numeric readers reject non-finite values and accept whole decimals',
    () {
      expect(jsonInt('12.0'), 12);
      expect(jsonInt(double.nan), isNull);
      expect(jsonInt(double.infinity), isNull);
      expect(jsonDouble('0.75'), closeTo(0.75, 0.0001));
      expect(jsonDouble('NaN'), isNull);
      expect(jsonDouble(double.negativeInfinity), isNull);
    },
  );

  test('progress and quiz models tolerate numeric strings', () {
    final progress = LearningProgressData.fromJson(
      {
        'videos': {'total': '8', 'completed': '3', 'inProgress': '2'},
        'quizAttempts': [
          {
            'title': 'Weekly Quiz',
            'score': '3',
            'totalQuestions': '4',
            'percentage': '75',
          },
        ],
      },
      {'currentStreak': '2', 'level': '4'},
    );
    expect(progress.videosTotal, 8);
    expect(progress.videosCompleted, 3);
    expect(progress.activities.single.percentage, 75);
    expect(progress.stats?.level, 4);

    final quiz = QuizListItem.fromJson({
      '_id': 'quiz-1',
      'title': 'Weekly Quiz',
      'numberOfQuestions': '10',
      'questionCount': '10',
      'overallTimeLimit': '20',
      'perQuestionTimeLimit': '2',
      'optionsCount': '4',
    });
    expect(quiz.numberOfQuestions, 10);
    expect(quiz.overallTimeLimit, 20);
    expect(quiz.optionsCount, 4);
  });

  test('Today and navigation config fall back for malformed numbers', () {
    final today = TodayOverview.fromJson({
      'streak': {'current': '4.0'},
      'next': {'id': 'lesson-1', 'percent': 'NaN', 'estimatedMinutes': '12.0'},
    });
    expect(today.currentStreak, 4);
    expect(today.next?.percent, isNull);
    expect(today.next?.estimatedMinutes, 12);

    final nav = NavigationItemConfig.fromJson({
      'key': 'learn',
      'order': 'Infinity',
    });
    expect(nav.order, 0);
  });
}
