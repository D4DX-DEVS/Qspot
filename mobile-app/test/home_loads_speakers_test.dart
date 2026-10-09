import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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

void main() {
  testWidgets('opening the app shell loads the faculties', (tester) async {
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
    ApiClient.clientOverride = MockClient(
      (_) async => http.Response('[]', 200),
    );
    addTearDown(() => ApiClient.clientOverride = null);

    final speakers = SpeakerProvider();
    expect(speakers.loadingState, SpeakerLoadingState.idle);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => VideoProvider()),
          ChangeNotifierProvider.value(value: speakers),
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

    // Whatever the request returns, faculties must have been asked for.
    expect(speakers.loadingState, isNot(SpeakerLoadingState.idle));
  });
}
