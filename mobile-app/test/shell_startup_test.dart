import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:qspot/screens/auth/provider/auth_provider.dart';
import 'package:qspot/screens/banner/provider/banner_provider.dart';
import 'package:qspot/screens/bookmark/provider/bookmark_provider.dart';
import 'package:qspot/screens/common/provider/main_navigation_provider.dart';
import 'package:qspot/screens/common/screens/main_navigation_screen.dart';
import 'package:qspot/screens/home/screens/redesigned_home_screen.dart';
import 'package:qspot/screens/notification/provider/notification_provider.dart';
import 'package:qspot/screens/quiz/model/quiz_progress_record.dart';
import 'package:qspot/screens/quiz/provider/quiz_provider.dart';
import 'package:qspot/screens/schedule/provider/schedule_provider.dart';
import 'package:qspot/screens/speaker/provider/speaker_provider.dart';
import 'package:qspot/screens/subject/provider/subject_provider.dart';
import 'package:qspot/screens/video/provider/video_provider.dart';
import 'package:qspot/services/api_client.dart';
import 'package:qspot/services/common/storage_service.dart';
import 'package:qspot/services/quiz_offline_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Lists {
  final videos = VideoProvider();
  final subjects = SubjectProvider();
  final speakers = SpeakerProvider();
  final banners = BannerProvider();
}

Future<_Lists> _pump(WidgetTester tester, Widget home) async {
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
  ApiClient.clientOverride = MockClient((_) async => http.Response('[]', 200));
  addTearDown(() => ApiClient.clientOverride = null);

  final lists = _Lists();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider.value(value: lists.videos),
        ChangeNotifierProvider.value(value: lists.speakers),
        ChangeNotifierProvider.value(value: lists.subjects),
        ChangeNotifierProvider(create: (_) => BookmarkProvider()),
        ChangeNotifierProvider(create: (_) => ScheduleProvider()),
        ChangeNotifierProvider.value(value: lists.banners),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => QuizProvider()),
        ChangeNotifierProvider(
          create: (_) =>
              MainNavigationProvider(tabCount: 1, tabKeys: const ['today']),
        ),
      ],
      child: MaterialApp(home: home),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  return lists;
}

void main() {
  testWidgets('opening the shell starts the shared lists', (tester) async {
    final lists = await _pump(tester, const MainNavigationScreen());

    expect(lists.videos.loadingState, isNot(VideoLoadingState.idle));
    expect(lists.subjects.loadingState, isNot(SubjectLoadingState.idle));
    expect(lists.speakers.loadingState, isNot(SpeakerLoadingState.idle));
    expect(lists.banners.loadingState, isNot(BannerLoadingState.idle));
  });

  testWidgets('coming back to the app sends quiz answers waiting on the phone', (
    tester,
  ) async {
    await _pump(tester, const MainNavigationScreen());
    final posts = <String>[];
    ApiClient.clientOverride = MockClient((request) async {
      if (request.method == 'POST') posts.add(request.url.path);
      return http.Response('[]', 200);
    });
    // Answers from a quiz submitted while offline, saved after the app opened.
    await QuizOfflineStore.saveProgress(
      'anon',
      QuizProgressRecord(
        quizId: 'q1',
        title: 'Weekly Quiz',
        questionIds: const ['a'],
        answers: const {'a': 1},
        language: 'en',
        startedAt: DateTime(2026, 10, 14, 10),
        submitPending: true,
      ),
    );

    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(posts, contains('/api/quizzes/attempt'));
  });

  testWidgets('Today alone no longer starts them; the shell does', (
    tester,
  ) async {
    final lists = await _pump(tester, const RedesignedHomeScreen());

    expect(lists.videos.loadingState, VideoLoadingState.idle);
    expect(lists.subjects.loadingState, SubjectLoadingState.idle);
    expect(lists.speakers.loadingState, SpeakerLoadingState.idle);
    expect(lists.banners.loadingState, BannerLoadingState.idle);
  });
}
