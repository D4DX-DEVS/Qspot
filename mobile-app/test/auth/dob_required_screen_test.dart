import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:qspot/screens/auth/provider/auth_provider.dart';
import 'package:qspot/screens/auth/screens/dob_required_screen.dart';
import 'package:qspot/screens/auth/widgets/date_picker_field.dart';
import 'package:qspot/screens/auth/widgets/gradient_pill_button.dart';
import 'package:qspot/screens/banner/provider/banner_provider.dart';
import 'package:qspot/screens/bookmark/provider/bookmark_provider.dart';
import 'package:qspot/screens/common/provider/main_navigation_provider.dart';
import 'package:qspot/screens/common/screens/main_navigation_screen.dart';
import 'package:qspot/screens/notification/provider/notification_provider.dart';
import 'package:qspot/screens/quiz/provider/quiz_provider.dart';
import 'package:qspot/screens/schedule/provider/schedule_provider.dart';
import 'package:qspot/screens/speaker/provider/speaker_provider.dart';
import 'package:qspot/screens/subject/provider/subject_provider.dart';
import 'package:qspot/screens/video/provider/video_provider.dart';
import 'package:qspot/services/api_client.dart';
import 'package:qspot/services/common/storage_service.dart';
import 'package:qspot/utils/dob_format.dart';

String get _defaultPickedDob {
  final now = DateTime.now();
  return formatDobForApi(DateTime(now.year - 12, now.month, now.day));
}

bool _buttonEnabled(WidgetTester tester) =>
    tester
        .widget<GradientPillButton>(find.byType(GradientPillButton))
        .onPressed !=
    null;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<http.Request> requests;

  Future<void> pumpScreen(
    WidgetTester tester, {
    required http.Response Function(http.Request) onPut,
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
    requests = [];
    ApiClient.clientOverride = MockClient((request) async {
      requests.add(request);
      if (request.method == 'PUT' && request.url.path == '/api/user/me') {
        return onPut(request);
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
          ChangeNotifierProvider(
            create: (_) =>
                MainNavigationProvider(tabCount: 1, tabKeys: const ['today']),
          ),
        ],
        child: const MaterialApp(home: DobRequiredScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pickDob(WidgetTester tester) async {
    await tester.tap(find.byType(DatePickerField));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  testWidgets('explains why and keeps Save off until a date is picked', (
    tester,
  ) async {
    await pumpScreen(tester, onPut: (_) => http.Response('{}', 500));

    expect(find.text('Save and Continue'), findsOneWidget);
    expect(
      find.textContaining('phone number and date of birth'),
      findsOneWidget,
    );
    expect(_buttonEnabled(tester), isFalse);

    await pickDob(tester);

    expect(find.text(_defaultPickedDob), findsOneWidget);
    expect(_buttonEnabled(tester), isTrue);
  });

  testWidgets('saving sends the date, updates the account and opens the app', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      onPut: (request) {
        final dob = (jsonDecode(request.body) as Map)['dob'];
        return http.Response(
          jsonEncode({
            'message': 'Profile updated',
            'user': {
              'id': 'u1',
              'name': 'Ayesha',
              'phone': '9876543210',
              'role': 'student',
              'dob': '${dob}T00:00:00.000Z',
            },
          }),
          200,
        );
      },
    );
    final auth = tester
        .element(find.byType(DobRequiredScreen))
        .read<AuthProvider>();

    await pickDob(tester);
    await tester.tap(find.byType(GradientPillButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final put = requests.singleWhere((r) => r.method == 'PUT');
    expect(put.url.path, '/api/user/me');
    expect(jsonDecode(put.body), {'dob': _defaultPickedDob});
    expect(auth.user?.hasDob, isTrue);
    expect(find.byType(MainNavigationScreen), findsOneWidget);
    expect(find.byType(DobRequiredScreen), findsNothing);
  });

  testWidgets('a refused save shows the message and stays on the screen', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      onPut: (_) => http.Response(
        jsonEncode({'message': 'Please check your connection and try again.'}),
        409,
      ),
    );

    await pickDob(tester);
    await tester.tap(find.byType(GradientPillButton));
    await tester.pumpAndSettle();

    expect(
      find.text('Please check your connection and try again.'),
      findsOneWidget,
    );
    expect(find.byType(DobRequiredScreen), findsOneWidget);
    expect(find.byType(MainNavigationScreen), findsNothing);
    expect(_buttonEnabled(tester), isTrue, reason: 'can try again');
  });
}
