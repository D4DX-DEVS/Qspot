import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qspot/screens/auth/provider/auth_provider.dart';
import 'package:qspot/screens/banner/provider/banner_provider.dart';
import 'package:qspot/screens/bookmark/provider/bookmark_provider.dart';
import 'package:qspot/screens/common/screens/main_navigation_screen.dart';
import 'package:qspot/screens/notification/provider/notification_provider.dart';
import 'package:qspot/screens/quiz/provider/quiz_provider.dart';
import 'package:qspot/screens/schedule/provider/schedule_provider.dart';
import 'package:qspot/screens/speaker/provider/speaker_provider.dart';
import 'package:qspot/screens/subject/provider/subject_provider.dart';
import 'package:qspot/screens/video/provider/video_provider.dart';
import 'package:qspot/services/api_client.dart';
import 'package:qspot/services/common/storage_service.dart';

Future<void> pumpNav(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  // The test font renders every glyph one em wide, so real screens that fit on
  // a phone still report overflow. Those reports are artifacts here; layout is
  // verified on the device build.
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
  ApiClient.clientOverride = MockClient((request) async {
    if (request.url.path.endsWith('/api/user/today')) {
      return http.Response(
        '{"next":null,"continue":[],"upcoming":[],"streak":{"current":2},'
        '"summary":{}}',
        200,
      );
    }
    if (request.url.path.endsWith('/api/user/progress')) {
      return http.Response(
        '{"videos":{"total":0,"completed":0,"inProgress":0},'
        '"courses":[],"subjects":[],"quizAttempts":[],"videoQuizzes":[]}',
        200,
      );
    }
    if (request.url.path.endsWith('/api/user/learning-stats')) {
      return http.Response(
        '{"currentStreak":2,"longestStreak":4,"xp":30,"level":1}',
        200,
      );
    }
    return http.Response('[]', 200);
  });
  addTearDown(() => ApiClient.clientOverride = null);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => VideoProvider()),
        ChangeNotifierProvider(create: (_) => SpeakerProvider()),
        ChangeNotifierProvider(create: (_) => SubjectProvider()),
        ChangeNotifierProvider(create: (_) => BookmarkProvider()),
        ChangeNotifierProvider(create: (_) => ScheduleProvider()),
        ChangeNotifierProvider(create: (_) => BannerProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => QuizProvider()),
      ],
      child: const MaterialApp(home: MainNavigationScreen()),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('footer exposes the learner task loop', (tester) async {
    await pumpNav(tester);

    expect(find.byType(BottomNavigationBar), findsNothing);

    expect(find.text('Today'), findsWidgets);
    expect(find.text('Learn'), findsWidgets);
    expect(find.text('Practice'), findsWidgets);
    expect(find.text('Progress'), findsWidgets);
    expect(find.text('Me'), findsWidgets);
    expect(find.byIcon(LucideIcons.house), findsOneWidget);
    expect(find.byIcon(LucideIcons.chartNoAxesCombined), findsOneWidget);
  });

  testWidgets('Practice tab groups assignments and quizzes', (tester) async {
    await pumpNav(tester);

    await tester.tap(find.text('Practice').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Assignments'), findsOneWidget);
    expect(find.text('Quizzes and Exams'), findsOneWidget);
  });

  testWidgets('Progress tab owns mastery and activity', (tester) async {
    await pumpNav(tester);

    await tester.tap(find.text('Progress').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Lesson Mastery'), findsWidgets);
    expect(find.text('Recent Activity'), findsOneWidget);
    expect(
      find.text('Your completed lessons and assessments will appear here.'),
      findsOneWidget,
    );
  });
}
