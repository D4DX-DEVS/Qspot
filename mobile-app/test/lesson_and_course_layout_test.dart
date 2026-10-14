import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:qspot/screens/bookmark/provider/bookmark_provider.dart';
import 'package:qspot/screens/calendar/screens/calendar_screen.dart';
import 'package:qspot/screens/certificate/screens/certificates_screen.dart';
import 'package:qspot/screens/course/screens/course_screen.dart';
import 'package:qspot/screens/grades/screens/grades_screen.dart';
import 'package:qspot/screens/lesson/screens/lesson_screen.dart';
import 'package:qspot/screens/subject/model/subject_model.dart';
import 'package:qspot/screens/subject/provider/subject_provider.dart';
import 'package:qspot/screens/subject/screens/subject_videos_screen.dart';
import 'package:qspot/screens/video/provider/video_provider.dart';
import 'package:qspot/services/api_client.dart';
import 'package:qspot/services/common/storage_service.dart';
import 'package:qspot/services/course_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The other tests draw text in a placeholder font where every letter is one
/// em wide, so they cannot tell whether a row really fits. These load the
/// app's own Manrope font and fail on any overflow, at the narrowest phone
/// width and with the largest text size the app allows.
const _course = CourseModel(
  id: 'c1',
  title: 'Tajweed and Recitation for Every Learner',
  description: 'Learn to recite with care.',
  learnPoints: ['Know the rules of madd and how long each one is held'],
);

const _longTitle = 'Understanding the rules of madd and how long to hold them';

Map<String, dynamic> _video(String id, int order) => {
  '_id': id,
  'title': '$_longTitle $order',
  'video': 'https://youtu.be/$id',
  'subject': {'_id': 's1', 'name': 'letters and sounds of the alphabet'},
  'order': order,
  'durationSeconds': 780,
  'learnText': 'A short note about the lesson. ' * 6,
  'learnPoints': ['First key point of the lesson', 'Second key point'],
  'questionCount': 4,
};

http.Response _respond(http.Request request) {
  final Object body = switch (request.url.path) {
    '/api/subjects' => [
      {
        '_id': 's1',
        'name': 'letters and sounds of the alphabet',
        'order': 1,
        'courseId': 'c1',
      },
    ],
    '/api/courses' => [
      {'_id': 'c1', 'title': 'Tajweed and Recitation for Every Learner'},
    ],
    '/api/videos' => [_video('v1', 1), _video('v2', 2), _video('v3', 3)],
    '/api/video-progress' => [
      {
        'videoId': 'v1',
        'completed': true,
        'positionSeconds': 780,
        'durationSeconds': 780,
      },
      {'videoId': 'v2', 'positionSeconds': 300, 'durationSeconds': 780},
    ],
    '/api/user/assignments' => [
      {
        '_id': 'a1',
        'title': 'Record yourself reciting the first page aloud',
        'courseId': 'c1',
        'maxPoints': 100,
        'submission': {
          'status': 'graded',
          'grade': 82,
          'feedback':
              'A very careful recitation. Watch the length of the long '
              'vowels in the second line and try again next week.',
          'gradedAt': '2026-10-12T09:00:00Z',
        },
      },
    ],
    '/api/user/progress' => {
      'quizAttempts': [
        {
          'title': 'Review quiz for the first chapter of the whole course',
          'score': 8,
          'totalQuestions': 10,
          'createdAt': '2026-10-08T09:00:00Z',
        },
      ],
      'videoQuizzes': [
        {
          'videoId': 'v1',
          'title': _longTitle,
          'score': 4,
          'totalQuestions': 5,
          'createdAt': '2026-10-11T09:00:00Z',
        },
      ],
    },
    '/api/certificates/mine' => {
      'items': [
        {
          'id': 'c1',
          'certificateNumber': 'QS-0001',
          'snapshot': {
            'examTitle': 'Final examination for the whole tajweed course',
          },
          'percentage': 87.5,
          'score': 7,
          'totalQuestions': 8,
          'issuedAt': '2026-10-07T12:00:00Z',
          'student': {'name': 'Aisha'},
        },
      ],
    },
    '/api/user/today' => {
      'continue': [],
      'upcoming': [
        {
          'kind': 'assignment',
          'id': 'a0',
          'title': 'Record yourself reciting the first page aloud, slowly',
          'status': 'overdue',
          'dueAt': _at(9, 23),
        },
        {
          'kind': 'assignment',
          'id': 'a1',
          'title': 'Write the steps of wudu in your own words',
          'status': 'upcoming',
          'dueAt': _at(14, 23),
        },
        {
          'kind': 'quiz',
          'id': 'q1',
          'title': 'Final practical examination for the whole course',
          'status': 'upcoming',
          'assessmentType': 'practical',
          'releaseAt': _at(14, 12),
        },
        {
          'kind': 'schedule',
          'id': 's1',
          'title': 'Live question and answer session with the teacher',
          'status': 'upcoming',
          'releaseAt': _at(14, 19),
        },
        {
          'kind': 'video',
          'id': 'v9',
          'title': _longTitle,
          'status': 'upcoming',
          'subject': {'name': 'letters and sounds of the alphabet'},
          'releaseAt': _at(15, 6),
        },
        {
          'kind': 'assignment',
          'id': 'a3',
          'title': 'An assignment nobody has set a date for',
          'status': 'upcoming',
        },
      ],
    },
    '/api/user/prefs' => {
      'seenGuides': ['s1'],
    },
    _ => [],
  };
  return http.Response(
    jsonEncode(body),
    200,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

/// A time on the Calendar's fixed day, Wednesday 14 October 2026.
String _at(int day, int hour) =>
    DateTime(2026, 10, day, hour).toUtc().toIso8601String();

Future<void> _loadManrope() async {
  final loader = FontLoader('Manrope');
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
    loader.addFont(rootBundle.load('assets/fonts/Manrope-$weight.ttf'));
  }
  await loader.load();
}

Future<void> _pump(
  WidgetTester tester, {
  required double width,
  required double textScale,
  required Widget Function(VideoProvider videos) home,
}) async {
  tester.view.physicalSize = Size(width * 3, 700 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({});
  await StorageService.init();
  ApiClient.clientOverride = MockClient((request) async => _respond(request));
  addTearDown(() => ApiClient.clientOverride = null);

  final videos = VideoProvider();
  final subjects = SubjectProvider();
  await tester.runAsync(() async {
    await _loadManrope();
    await videos.initialize();
    await subjects.initialize();
  });

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: videos),
        ChangeNotifierProvider.value(value: subjects),
        ChangeNotifierProvider(create: (_) => BookmarkProvider()),
      ],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: home(videos),
      ),
    ),
  );
  await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 1)));
  await tester.pumpAndSettle();
}

void main() {
  for (final (width, scale) in [(320.0, 1.0), (320.0, 1.3), (390.0, 1.0)]) {
    final setting = '${width.toInt()} wide, text ${scale}x';

    testWidgets('Course page fits at $setting', (tester) async {
      await _pump(
        tester,
        width: width,
        textScale: scale,
        home: (_) => const CourseScreen(course: _course),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Start · Chapter 1, Lesson 2'), findsNothing);
      expect(find.textContaining('Continue · Chapter 1'), findsOneWidget);
    });

    testWidgets('Lesson page fits at $setting', (tester) async {
      await _pump(
        tester,
        width: width,
        textScale: scale,
        home: (videos) => LessonScreen(
          video: videos.allVideos.firstWhere((video) => video.id == 'v2'),
        ),
      );

      expect(tester.takeException(), isNull);

      for (final tab in ['Downloads', 'Practice', 'Learn']) {
        await tester.tap(find.text(tab));
        await tester.pump();
        expect(tester.takeException(), isNull, reason: '$tab tab');
      }
    });

    testWidgets('Lesson list sheet fits at $setting', (tester) async {
      await _pump(
        tester,
        width: width,
        textScale: scale,
        home: (videos) => LessonScreen(
          video: videos.allVideos.firstWhere((video) => video.id == 'v2'),
        ),
      );

      await tester.tap(find.widgetWithText(OutlinedButton, 'Lessons'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Course Grades tab fits at $setting', (tester) async {
      await _pump(
        tester,
        width: width,
        textScale: scale,
        home: (_) => const CourseScreen(course: _course),
      );

      await tester.tap(find.text('Grades'));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('4/5'), findsOneWidget);
    });

    testWidgets('My Grades fits at $setting', (tester) async {
      await _pump(
        tester,
        width: width,
        textScale: scale,
        home: (_) => const GradesScreen(),
      );

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Teacher:'), findsOneWidget);
    });

    testWidgets('My Certificates fits at $setting', (tester) async {
      await _pump(
        tester,
        width: width,
        textScale: scale,
        home: (_) => const CertificatesScreen(),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('87.5%'), findsOneWidget);
    });

    testWidgets('Calendar fits at $setting', (tester) async {
      await _pump(
        tester,
        width: width,
        textScale: scale,
        home: (_) => CalendarScreen(clock: () => DateTime(2026, 10, 14, 10)),
      );

      expect(tester.takeException(), isNull);
      // The list builds as it scrolls, so the last block checks the bottom.
      await tester.scrollUntilVisible(
        find.text('NO DATE'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull, reason: 'bottom of the list');
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
      await tester.pumpAndSettle();

      // A chosen day and a filter lay out too.
      await tester.tap(find.text('15'));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'chosen day');
      await tester.tap(find.text('Show all days'));
      await tester.pump();
      await tester.ensureVisible(find.text('Live classes'));
      await tester.pump();
      await tester.tap(find.text('Live classes'));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'filter');
    });

    testWidgets('Chapter lessons fit at $setting', (tester) async {
      await _pump(
        tester,
        width: width,
        textScale: scale,
        home: (_) => SubjectVideosScreen(
          subject: SubjectModel(
            id: 's1',
            subject: 'letters and sounds of the alphabet',
            order: 1,
            courseId: 'c1',
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  }
}
