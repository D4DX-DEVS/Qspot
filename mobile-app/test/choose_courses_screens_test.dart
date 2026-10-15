import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:qspot/screens/auth/model/user_model.dart';
import 'package:qspot/screens/auth/provider/auth_provider.dart';
import 'package:qspot/screens/banner/provider/banner_provider.dart';
import 'package:qspot/screens/bookmark/provider/bookmark_provider.dart';
import 'package:qspot/screens/common/screens/main_navigation_screen.dart';
import 'package:qspot/screens/notification/provider/notification_provider.dart';
import 'package:qspot/screens/quiz/provider/quiz_provider.dart';
import 'package:qspot/screens/schedule/provider/schedule_provider.dart';
import 'package:qspot/screens/speaker/provider/speaker_provider.dart';
import 'package:qspot/screens/subject/provider/subject_provider.dart';
import 'package:qspot/screens/subject/screens/subject_list_screen.dart';
import 'package:qspot/screens/video/provider/video_provider.dart';
import 'package:qspot/services/api_client.dart';
import 'package:qspot/services/common/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A learner with no course chosen gets an empty app from the server. These
/// tests check the app asks them to choose, and leaves everyone else alone.
Future<void> _pump(
  WidgetTester tester, {
  required Widget home,
  required List<String> courseIds,
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
  ApiClient.clientOverride = MockClient((_) async => http.Response('[]', 200));
  addTearDown(() => ApiClient.clientOverride = null);

  final auth = AuthProvider();
  if (courseIds.isNotEmpty) {
    await auth.updateUser(UserModel(phone: '1', courseIds: courseIds));
  }

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => VideoProvider()),
        ChangeNotifierProvider(create: (_) => SpeakerProvider()),
        ChangeNotifierProvider(create: (_) => SubjectProvider()),
        ChangeNotifierProvider(create: (_) => BookmarkProvider()),
        ChangeNotifierProvider(create: (_) => ScheduleProvider()),
        ChangeNotifierProvider(create: (_) => BannerProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => QuizProvider()),
      ],
      child: MaterialApp(home: home),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  group('Learn tab', () {
    testWidgets('asks a learner with no courses to choose', (tester) async {
      await _pump(tester, home: const SubjectListScreen(), courseIds: const []);

      expect(find.text('Choose Your Courses'), findsOneWidget);
      expect(find.text('No Subjects Available'), findsNothing);
    });

    testWidgets('keeps the usual empty message once courses are chosen', (
      tester,
    ) async {
      await _pump(
        tester,
        home: const SubjectListScreen(),
        courseIds: const ['c1'],
      );

      expect(find.text('Choose Your Courses'), findsNothing);
      expect(find.text('No Subjects Available'), findsOneWidget);
    });
  });

  group('Today tab', () {
    testWidgets('asks a learner with no courses to choose', (tester) async {
      await _pump(
        tester,
        home: const MainNavigationScreen(),
        courseIds: const [],
      );

      expect(find.text('Choose Your Courses'), findsOneWidget);
    });

    testWidgets('does not ask a learner who chose courses', (tester) async {
      await _pump(
        tester,
        home: const MainNavigationScreen(),
        courseIds: const ['c1'],
      );

      expect(find.text('Choose Your Courses'), findsNothing);
    });
  });
}
