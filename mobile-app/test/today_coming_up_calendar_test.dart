import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:qspot/routes/app_routes.dart';
import 'package:qspot/screens/assignment/screens/assignments_screen.dart';
import 'package:qspot/screens/auth/provider/auth_provider.dart';
import 'package:qspot/screens/banner/provider/banner_provider.dart';
import 'package:qspot/screens/bookmark/provider/bookmark_provider.dart';
import 'package:qspot/screens/calendar/screens/calendar_screen.dart';
import 'package:qspot/screens/common/provider/main_navigation_provider.dart';
import 'package:qspot/screens/home/screens/redesigned_home_screen.dart';
import 'package:qspot/screens/notification/provider/notification_provider.dart';
import 'package:qspot/screens/schedule/provider/schedule_provider.dart';
import 'package:qspot/screens/speaker/provider/speaker_provider.dart';
import 'package:qspot/screens/subject/provider/subject_provider.dart';
import 'package:qspot/screens/video/provider/video_provider.dart';
import 'package:qspot/services/api_client.dart';
import 'package:qspot/services/common/storage_service.dart';
import 'package:qspot/themes/home_theme.dart';
import 'package:qspot/widgets/common/section_header.dart';
import 'package:shared_preferences/shared_preferences.dart';

http.Response _json(Object body) => http.Response(
  jsonEncode(body),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

/// A live class a few days out is "Coming Up"; an assignment is "To-Do".
http.Response _respond(http.Request request) {
  final soon = DateTime.now().add(const Duration(days: 3)).toIso8601String();
  return switch (request.url.path) {
    '/api/user/today' => _json({
      'continue': [],
      'upcoming': [
        {
          'kind': 'schedule',
          'id': 's1',
          'title': 'Q&A with the teacher',
          'status': 'upcoming',
          'releaseAt': soon,
        },
        {
          'kind': 'assignment',
          'id': 'a1',
          'title': 'Steps of wudu',
          'status': 'upcoming',
          'dueAt': soon,
        },
      ],
    }),
    _ => _json([]),
  };
}

Future<void> _openToday(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390 * 3, 1400 * 3);
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
        ChangeNotifierProvider(
          create: (_) =>
              MainNavigationProvider(tabCount: 1, tabKeys: const ['today']),
        ),
      ],
      child: MaterialApp(
        theme: HomeTheme.light,
        onGenerateRoute: AppRoutes.onGenerateRoute,
        home: const RedesignedHomeScreen(),
      ),
    ),
  );
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 500)),
  );
  // Today has animations that never stop, so wait a fixed time instead of
  // for it to settle.
  await tester.pump(const Duration(seconds: 2));
}

void main() {
  testWidgets('Coming Up "See All" opens the Calendar', (tester) async {
    await _openToday(tester);
    expect(find.text('Coming Up'), findsWidgets);

    // Coming Up is also the name of a stat tile; the link is on the heading.
    final seeAll = find.descendant(
      of: find.widgetWithText(SectionHeader, 'Coming Up'),
      matching: find.text('See All'),
    );
    await tester.ensureVisible(seeAll);
    await tester.pump();
    await tester.tap(seeAll);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    // One frame starts the page transition, the next finishes it.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(CalendarScreen), findsOneWidget);
    expect(find.text('Q&A with the teacher'), findsWidgets);
  });

  testWidgets('To-Do "See All" still opens Assignments, not the Calendar', (
    tester,
  ) async {
    await _openToday(tester);

    final seeAll = find.descendant(
      of: find.widgetWithText(SectionHeader, 'Your To-Do List'),
      matching: find.text('See All'),
    );
    await tester.ensureVisible(seeAll);
    await tester.pump();
    await tester.tap(seeAll);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(AssignmentsScreen), findsOneWidget);
    expect(find.byType(CalendarScreen), findsNothing);
  });
}
