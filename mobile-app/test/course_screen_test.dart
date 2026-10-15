import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:qspot/screens/course/screens/course_screen.dart';
import 'package:qspot/screens/subject/provider/subject_provider.dart';
import 'package:qspot/screens/video/provider/video_provider.dart';
import 'package:qspot/services/api_client.dart';
import 'package:qspot/services/common/storage_service.dart';
import 'package:qspot/services/course_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _course = CourseModel(
  id: 'c1',
  title: 'Tajweed',
  description: 'Learn to recite with care.',
  learnPoints: ['Know the rules of madd'],
);

Map<String, dynamic> _video(String id, String title, int order) => {
  '_id': id,
  'title': title,
  'video': 'https://youtu.be/$id',
  'subject': {'_id': 's1', 'name': 'letters'},
  'order': order,
  'durationSeconds': 600,
};

http.Response _respond(http.Request request) {
  final Object body = switch (request.url.path) {
    '/api/subjects' => [
      {'_id': 's1', 'name': 'letters', 'order': 1, 'courseId': 'c1'},
    ],
    '/api/courses' => [
      {'_id': 'c1', 'title': 'Tajweed'},
    ],
    '/api/videos' => [
      _video('v1', 'Lesson one', 1),
      _video('v2', 'Lesson two', 2),
      _video('v3', 'Lesson three', 3),
    ],
    '/api/video-progress' => [
      {
        'videoId': 'v1',
        'completed': true,
        'positionSeconds': 600,
        'durationSeconds': 600,
      },
    ],
    '/api/user/progress' => {
      'videoQuizzes': [
        {
          'videoId': 'v1',
          'title': 'Lesson one',
          'score': 4,
          'totalQuestions': 5,
          'createdAt': '2026-10-11T09:00:00Z',
        },
        {
          'videoId': 'elsewhere',
          'title': 'A lesson in another course',
          'score': 1,
          'totalQuestions': 5,
          'createdAt': '2026-10-12T09:00:00Z',
        },
      ],
    },
    '/api/user/assignments' => [
      {'_id': 'a1', 'title': 'Recite aloud', 'courseId': 'c1'},
    ],
    _ => [],
  };
  return http.Response(
    jsonEncode(body),
    200,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

Future<void> _openCourse(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  // The test font is one em wide per glyph, so rows that fit on a device
  // still report overflow here.
  final previousOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exception.toString().contains('A RenderFlex overflowed')) {
      return;
    }
    previousOnError?.call(details);
  };
  addTearDown(() => FlutterError.onError = previousOnError);

  SharedPreferences.setMockInitialValues({});
  await StorageService.init();
  ApiClient.clientOverride = MockClient((request) async => _respond(request));
  addTearDown(() => ApiClient.clientOverride = null);

  final videos = VideoProvider();
  final subjects = SubjectProvider();
  await tester.runAsync(() async {
    await videos.initialize();
    await subjects.initialize();
  });

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: videos),
        ChangeNotifierProvider.value(value: subjects),
      ],
      child: const MaterialApp(home: CourseScreen(course: _course)),
    ),
  );
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}

/// The tabs scroll sideways, so bring one into view before tapping it.
Future<void> _openTab(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label));
  await tester.pump();
  await tester.tap(find.text(label));
  await tester.pump();
}

void main() {
  testWidgets('shows progress, the syllabus and the next lesson to start', (
    tester,
  ) async {
    await _openCourse(tester);

    expect(find.text('Tajweed'), findsOneWidget);
    // Once in the summary card and once on the chapter's heading.
    expect(find.text('1 of 3 lessons'), findsNWidgets(2));
    expect(find.text('Assignments 0 of 1'), findsOneWidget);
    expect(find.text('Chapter 1 · Letters'), findsOneWidget);
    expect(find.text('1. Lesson one'), findsOneWidget);
    expect(find.text('2. Lesson two'), findsOneWidget);
    expect(find.text('3. Lesson three'), findsOneWidget);
    // Lessons two and three are both open, in any order.
    expect(find.text('Locked'), findsNothing);
    expect(find.text('Start'), findsNWidgets(2));
    expect(find.text('Start · Chapter 1, Lesson 2'), findsOneWidget);
  });

  testWidgets('the Assignments tab lists the course assignments', (
    tester,
  ) async {
    await _openCourse(tester);
    // Assignments are not under the lessons any more.
    expect(find.text('Recite aloud'), findsNothing);

    await _openTab(tester, 'Assignments');

    expect(find.text('Recite aloud'), findsOneWidget);
    expect(find.text('1. Lesson one'), findsNothing);
  });

  testWidgets('the About tab shows what the teacher wrote', (tester) async {
    await _openCourse(tester);

    await _openTab(tester, 'About');

    expect(find.text('Learn to recite with care.'), findsOneWidget);
    expect(find.text('Know the rules of madd'), findsOneWidget);
    expect(find.text('1. Lesson one'), findsNothing);
  });

  testWidgets('the Grades tab lists this course\'s marks only', (tester) async {
    await _openCourse(tester);

    await _openTab(tester, 'Grades');

    expect(find.text('4/5'), findsOneWidget);
    expect(find.text('Lesson one'), findsOneWidget);
    expect(find.text('A lesson in another course'), findsNothing);
    expect(find.text('1. Lesson one'), findsNothing);
  });

  testWidgets('the summary shows the course\'s grade average', (tester) async {
    await _openCourse(tester);

    expect(find.text('Grade average 80%'), findsOneWidget);
  });
}
