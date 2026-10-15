import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:qspot/screens/bookmark/provider/bookmark_provider.dart';
import 'package:qspot/screens/subject/model/subject_model.dart';
import 'package:qspot/screens/subject/provider/subject_provider.dart';
import 'package:qspot/screens/subject/screens/subject_videos_screen.dart';
import 'package:qspot/screens/video/provider/video_provider.dart';
import 'package:qspot/services/api_client.dart';
import 'package:qspot/services/common/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    // The first-open chapter guide has been seen already.
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

Future<void> _openChapter(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

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
        ChangeNotifierProvider(create: (_) => BookmarkProvider()),
      ],
      child: MaterialApp(
        home: SubjectVideosScreen(
          subject: SubjectModel(
            id: 's1',
            subject: 'letters',
            order: 1,
            courseId: 'c1',
          ),
        ),
      ),
    ),
  );
  await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 1)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('every lesson card carries its number', (tester) async {
    await _openChapter(tester);

    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('only the lesson after the finished ones is locked from view', (
    tester,
  ) async {
    await _openChapter(tester);

    // Lesson one is done and lesson two is next, so only lesson three is shut.
    expect(find.byIcon(LucideIcons.lock), findsOneWidget);
  });

  testWidgets('a locked lesson explains what to finish and does not open', (
    tester,
  ) async {
    await _openChapter(tester);

    await tester.tap(find.text('Lesson three'));
    await tester.pump();

    expect(find.text('Finish "Lesson two" first.'), findsOneWidget);
    expect(find.text('LESSON 3 OF 3'), findsNothing);
  });

  testWidgets('an open lesson opens its lesson page', (tester) async {
    await _openChapter(tester);

    await tester.tap(find.text('Lesson two'));
    await tester.pumpAndSettle();

    expect(find.text('LESSON 2 OF 3'), findsOneWidget);
  });

  testWidgets('a finished lesson can be opened again', (tester) async {
    await _openChapter(tester);

    await tester.tap(find.text('Lesson one'));
    await tester.pumpAndSettle();

    expect(find.text('LESSON 1 OF 3'), findsOneWidget);
    expect(find.text('Watch again'), findsOneWidget);
  });
}
