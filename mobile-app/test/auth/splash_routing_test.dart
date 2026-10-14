import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:qspot/screens/auth/provider/auth_provider.dart';
import 'package:qspot/screens/auth/screens/dob_required_screen.dart';
import 'package:qspot/screens/auth/screens/login_screen.dart';
import 'package:qspot/screens/banner/provider/banner_provider.dart';
import 'package:qspot/screens/bookmark/provider/bookmark_provider.dart';
import 'package:qspot/screens/common/provider/main_navigation_provider.dart';
import 'package:qspot/screens/common/screens/main_navigation_screen.dart';
import 'package:qspot/screens/common/screens/splash_screen.dart';
import 'package:qspot/screens/notification/provider/notification_provider.dart';
import 'package:qspot/screens/quiz/provider/quiz_provider.dart';
import 'package:qspot/screens/schedule/provider/schedule_provider.dart';
import 'package:qspot/screens/speaker/provider/speaker_provider.dart';
import 'package:qspot/screens/subject/provider/subject_provider.dart';
import 'package:qspot/screens/video/provider/video_provider.dart';
import 'package:qspot/services/api_client.dart';
import 'package:qspot/services/common/storage_service.dart';

/// Where the splash sends someone: sign-in when there is no session, the
/// add-your-date-of-birth screen for a student whose account has none, the
/// main app otherwise.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> openSplash(
    WidgetTester tester, {
    required Map<String, Object> storage,
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

    SharedPreferences.setMockInitialValues(storage);
    // StorageService keeps its SharedPreferences instance between tests.
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    await StorageService.init();
    for (final key in ['auth_token', 'user_data', 'userId']) {
      await StorageService.remove(key);
    }
    for (final entry in storage.entries) {
      await StorageService.setString(entry.key, entry.value as String);
    }
    ApiClient.clientOverride = MockClient(
      (_) async => http.Response('[]', 200),
    );
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
          ChangeNotifierProvider(
            create: (_) =>
                MainNavigationProvider(tabCount: 1, tabKeys: const ['today']),
          ),
        ],
        child: const MaterialApp(home: SplashScreen()),
      ),
    );
    // Splash animation, the 3 second hold and the fade into the next page.
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(seconds: 1));
  }

  Map<String, Object> signedIn({String? dob, String role = 'student'}) => {
    'auth_token': 'tok-1',
    'user_data': jsonEncode({
      'id': 'u1',
      'phone': '9876543210',
      'name': 'Ayesha',
      'role': role,
      if (dob != null) 'dob': dob,
    }),
  };

  testWidgets('no session goes to sign-in', (tester) async {
    await openSplash(tester, storage: {});

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('a student with no date of birth is asked for one', (
    tester,
  ) async {
    await openSplash(tester, storage: signedIn());

    expect(find.byType(DobRequiredScreen), findsOneWidget);
    expect(find.byType(MainNavigationScreen), findsNothing);
  });

  testWidgets('a student with a date of birth goes to the app', (tester) async {
    await openSplash(
      tester,
      storage: signedIn(dob: '2010-05-03T00:00:00.000Z'),
    );

    expect(find.byType(MainNavigationScreen), findsOneWidget);
    expect(find.byType(DobRequiredScreen), findsNothing);
  });
}
