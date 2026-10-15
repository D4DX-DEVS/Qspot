import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:qspot/screens/bookmark/provider/bookmark_provider.dart';
import 'package:qspot/screens/lesson/screens/lesson_screen.dart';
import 'package:qspot/screens/subject/provider/subject_provider.dart';
import 'package:qspot/screens/video/provider/video_provider.dart';
import 'package:qspot/services/api_client.dart';
import 'package:qspot/services/common/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _video(
  String id,
  String title,
  int order, {
  String learnText = '',
  int questions = 0,
}) => {
  '_id': id,
  'title': title,
  'video': 'https://youtu.be/$id',
  'subject': {'_id': 's1', 'name': 'letters'},
  'order': order,
  'durationSeconds': 600,
  'learnText': learnText,
  'questionCount': questions,
};

/// Lessons one, two and three of "Letters". [done] are finished.
http.Response Function(http.Request) _api(List<String> done) => (request) {
  final Object body = switch (request.url.path) {
    '/api/subjects' => [
      {'_id': 's1', 'name': 'letters', 'order': 1, 'courseId': 'c1'},
    ],
    '/api/courses' => [
      {'_id': 'c1', 'title': 'Tajweed'},
    ],
    '/api/videos' => [
      _video('v1', 'Lesson one', 1, learnText: 'Notes for lesson one.'),
      _video('v2', 'Lesson two', 2, questions: 2),
      _video('v3', 'Lesson three', 3),
    ],
    '/api/video-progress' => [
      for (final id in done)
        {
          'videoId': id,
          'completed': true,
          'positionSeconds': 600,
          'durationSeconds': 600,
        },
    ],
    _ => [],
  };
  return http.Response(
    jsonEncode(body),
    200,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
};

Future<void> _openLesson(
  WidgetTester tester,
  String id, {
  List<String> done = const ['v1'],
}) async {
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
  final respond = _api(done);
  ApiClient.clientOverride = MockClient((request) async => respond(request));
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
        ChangeNotifierProvider(create: (_) => BookmarkProvider()),
      ],
      child: MaterialApp(
        home: LessonScreen(
          video: videos.allVideos.firstWhere((video) => video.id == id),
        ),
      ),
    ),
  );
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}

/// A widget that gives screen readers this label.
Finder _labelled(String label) => find.byWidgetPredicate(
  (widget) => widget is Semantics && widget.properties.label == label,
);

void main() {
  testWidgets('shows where the lesson sits and what to do with it', (
    tester,
  ) async {
    await _openLesson(tester, 'v2');

    expect(find.text('LESSON 2 OF 3'), findsOneWidget);
    expect(find.text('Lesson two'), findsOneWidget);
    expect(find.text('Tajweed · Chapter 1'), findsOneWidget);
    expect(find.text('Letters'), findsWidgets);
    // The picture says what tapping it does, for screen readers.
    expect(_labelled('Watch lesson'), findsOneWidget);
    // Along its bottom: time reached, a bar, and the length.
    expect(find.text('0:00'), findsOneWidget);
    expect(find.text('10:00'), findsOneWidget);
    expect(find.text('Learn'), findsOneWidget);
    expect(find.text('Downloads'), findsOneWidget);
    expect(find.text('Practice'), findsOneWidget);
  });

  testWidgets('the next lesson opens before this one is done', (tester) async {
    await _openLesson(tester, 'v2');

    final previous = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Previous'),
    );
    expect(previous.onPressed, isNotNull);

    await tester.tap(find.widgetWithText(FilledButton, 'Next'));
    await tester.pumpAndSettle();

    expect(find.text('LESSON 3 OF 3'), findsOneWidget);
  });

  testWidgets('a finished lesson opens the next one', (tester) async {
    await _openLesson(tester, 'v2', done: const ['v1', 'v2']);

    expect(_labelled('Watch again'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Next'));
    await tester.pumpAndSettle();

    expect(find.text('LESSON 3 OF 3'), findsOneWidget);
    expect(find.text('Lesson three'), findsOneWidget);
  });

  testWidgets('Previous goes back a lesson', (tester) async {
    await _openLesson(tester, 'v2');

    await tester.tap(find.widgetWithText(OutlinedButton, 'Previous'));
    await tester.pumpAndSettle();

    expect(find.text('LESSON 1 OF 3'), findsOneWidget);
  });

  testWidgets('a lesson ahead of unfinished ones can be played', (
    tester,
  ) async {
    // Lesson two is not finished, yet lesson three is open.
    await _openLesson(tester, 'v3');

    expect(_labelled('Watch lesson'), findsOneWidget);
    expect(find.byIcon(LucideIcons.lock), findsNothing);
  });

  testWidgets('the lesson list shows every lesson and opens any of them', (
    tester,
  ) async {
    await _openLesson(tester, 'v1');

    await tester.tap(find.widgetWithText(OutlinedButton, 'Lessons'));
    await tester.pumpAndSettle();

    expect(find.text('Chapter 1 · Letters'), findsOneWidget);
    expect(find.text('1. Lesson one'), findsOneWidget);
    expect(find.text('3. Lesson three'), findsOneWidget);

    await tester.tap(find.text('3. Lesson three'));
    await tester.pumpAndSettle();

    expect(find.text('LESSON 3 OF 3'), findsOneWidget);
  });

  testWidgets('the lesson list jumps to a lesson that is open', (tester) async {
    await _openLesson(tester, 'v2');

    await tester.tap(find.widgetWithText(OutlinedButton, 'Lessons'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1. Lesson one'));
    await tester.pumpAndSettle();

    expect(find.text('LESSON 1 OF 3'), findsOneWidget);
  });

  group('tabs', () {
    testWidgets('Learn shows the note, or says there is none', (tester) async {
      await _openLesson(tester, 'v1');
      expect(find.text('Notes for lesson one.'), findsOneWidget);
    });

    testWidgets('Learn says so when the lesson has no notes', (tester) async {
      await _openLesson(tester, 'v2');
      expect(find.text('No notes for this lesson yet.'), findsOneWidget);
    });

    testWidgets('Downloads says so when there are none', (tester) async {
      await _openLesson(tester, 'v2');

      await tester.tap(find.text('Downloads'));
      await tester.pump();

      expect(find.text('No downloads for this lesson yet.'), findsOneWidget);
    });

    testWidgets('Practice stays locked until the lesson is finished', (
      tester,
    ) async {
      await _openLesson(tester, 'v2');

      await tester.tap(find.text('Practice'));
      await tester.pump();

      expect(find.text('2 Questions on This Lesson'), findsOneWidget);
      expect(
        find.text('Finish watching to unlock the questions.'),
        findsOneWidget,
      );
      expect(find.text('Start Practice'), findsNothing);
    });

    testWidgets('Practice offers to start once the lesson is finished', (
      tester,
    ) async {
      await _openLesson(tester, 'v2', done: const ['v1', 'v2']);

      await tester.tap(find.text('Practice'));
      await tester.pump();

      expect(find.text('Start Practice'), findsOneWidget);
    });
  });
}
