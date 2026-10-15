import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qspot/screens/assignment/screens/assignments_screen.dart';
import 'package:qspot/screens/calendar/screens/calendar_screen.dart';
import 'package:qspot/services/api_client.dart';
import 'package:qspot/services/common/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Wednesday 14 October 2026, 10:00 on the phone.
final _now = DateTime(2026, 10, 14, 10);

String _at(int day, int hour) =>
    DateTime(2026, 10, day, hour).toUtc().toIso8601String();

Map<String, dynamic> _today(List<Map<String, dynamic>> upcoming) => {
  'continue': <Map<String, dynamic>>[],
  'upcoming': upcoming,
};

final _agenda = _today([
  {
    'kind': 'assignment',
    'id': 'a0',
    'title': 'Late reflection',
    'status': 'overdue',
    'dueAt': _at(9, 17),
  },
  {
    'kind': 'assignment',
    'id': 'a1',
    'title': 'Steps of wudu',
    'status': 'upcoming',
    'dueAt': _at(14, 18),
  },
  {
    'kind': 'schedule',
    'id': 's1',
    'title': 'Q&A with the teacher',
    'status': 'upcoming',
    'releaseAt': _at(15, 19),
  },
  {
    'kind': 'quiz',
    'id': 'q1',
    'title': 'Chapter 2 quiz',
    'status': 'upcoming',
    'releaseAt': _at(16, 9),
    'dueAt': _at(20, 9),
  },
  {
    'kind': 'video',
    'id': 'v1',
    'title': 'Madd Asli',
    'status': 'upcoming',
    'subject': {'name': 'Tajweed'},
    'releaseAt': _at(16, 6),
  },
  {
    'kind': 'assignment',
    'id': 'a2',
    'title': 'Final recitation',
    'status': 'upcoming',
    'dueAt': _at(20, 9),
  },
]);

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Future<void> _open(
  WidgetTester tester, {
  required http.Response Function(http.Request) respond,
  double width = 390,
}) async {
  tester.view.physicalSize = Size(width * 3, 844 * 3);
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
  ApiClient.clientOverride = MockClient((request) async => respond(request));
  addTearDown(() => ApiClient.clientOverride = null);

  await tester.pumpWidget(MaterialApp(home: CalendarScreen(clock: () => _now)));
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 300)),
  );
  await tester.pumpAndSettle();
}

http.Response _serveAgenda(http.Request request) =>
    request.url.path == '/api/user/today' ? _json(_agenda) : _json([]);

void main() {
  testWidgets('shows the week, the filters and the agenda by day', (
    tester,
  ) async {
    await _open(tester, respond: _serveAgenda);

    expect(find.text('Calendar'), findsOneWidget);
    expect(find.text('October 2026'), findsOneWidget);
    for (final weekday in ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']) {
      expect(find.text(weekday), findsOneWidget);
    }
    for (final chip in [
      'All',
      'Assignments',
      'Live classes',
      'Quizzes',
      'Lessons',
    ]) {
      expect(find.text(chip), findsOneWidget);
    }
    expect(find.text('OVERDUE'), findsOneWidget);
    expect(find.text('TODAY · WED 14 OCT'), findsOneWidget);
    expect(find.text('TOMORROW · THU 15 OCT'), findsOneWidget);
    expect(find.text('FRI 16 OCT'), findsOneWidget);
  });

  testWidgets('each entry shows its time, title, kind and what happens', (
    tester,
  ) async {
    await _open(tester, respond: _serveAgenda);

    expect(find.text('Steps of wudu'), findsOneWidget);
    expect(find.text('6:00 PM'), findsOneWidget);
    // Two assignments have a deadline: Steps of wudu and Final recitation.
    expect(find.text('Due'), findsNWidgets(2));
    expect(find.text('Q&A with the teacher'), findsOneWidget);
    expect(find.text('Live'), findsOneWidget);
    expect(find.text('Lesson · Tajweed'), findsOneWidget);
    expect(find.text('Late reflection'), findsOneWidget);
    expect(find.text('Overdue'), findsOneWidget);
  });

  testWidgets('a filter chip keeps only that kind', (tester) async {
    await _open(tester, respond: _serveAgenda);

    await tester.tap(find.text('Live classes'));
    await tester.pump();

    expect(find.text('Q&A with the teacher'), findsOneWidget);
    expect(find.text('Steps of wudu'), findsNothing);
    expect(find.text('Chapter 2 quiz'), findsNothing);
  });

  testWidgets(
    'tapping a day shows only that day, and Show all brings back the rest',
    (tester) async {
      await _open(tester, respond: _serveAgenda);

      await tester.tap(find.text('16'));
      await tester.pump();

      expect(find.text('Chapter 2 quiz'), findsOneWidget);
      expect(find.text('Madd Asli'), findsOneWidget);
      expect(find.text('Steps of wudu'), findsNothing);
      expect(find.text('Show all days'), findsOneWidget);

      await tester.tap(find.text('Show all days'));
      await tester.pump();

      expect(find.text('Steps of wudu'), findsOneWidget);
      expect(find.text('Show all days'), findsNothing);
    },
  );

  testWidgets('a day with nothing on it says so', (tester) async {
    await _open(tester, respond: _serveAgenda);

    await tester.tap(find.text('17'));
    await tester.pump();

    expect(find.text('Nothing on This Day'), findsOneWidget);
    expect(find.text('Steps of wudu'), findsNothing);
  });

  testWidgets('a kind with nothing says so', (tester) async {
    await _open(
      tester,
      respond: (request) => request.url.path == '/api/user/today'
          ? _json(
              _today([
                {
                  'kind': 'schedule',
                  'id': 's1',
                  'title': 'Q&A',
                  'status': 'upcoming',
                  'releaseAt': _at(15, 19),
                },
              ]),
            )
          : _json([]),
    );

    // The chips scroll sideways; bring the last ones into view first.
    await tester.ensureVisible(find.text('Quizzes'));
    await tester.pump();
    await tester.tap(find.text('Quizzes'));
    await tester.pump();

    expect(find.text('Nothing Here'), findsOneWidget);
    expect(find.text('Q&A'), findsNothing);
  });

  testWidgets('the arrows change week, and stop where the dates stop', (
    tester,
  ) async {
    await _open(tester, respond: _serveAgenda);

    // Nothing is dated after the week of the 20th.
    final next = find.widgetWithIcon(IconButton, LucideIcons.chevronRight);
    final previous = find.widgetWithIcon(IconButton, LucideIcons.chevronLeft);
    expect(tester.widget<IconButton>(previous).onPressed, isNull);
    expect(tester.widget<IconButton>(next).onPressed, isNotNull);

    await tester.tap(next);
    await tester.pump();

    expect(find.text('19'), findsOneWidget);
    expect(find.text('12'), findsNothing);
    expect(tester.widget<IconButton>(next).onPressed, isNull);
    expect(tester.widget<IconButton>(previous).onPressed, isNotNull);
  });

  testWidgets('a lesson that is not open yet says when it opens', (
    tester,
  ) async {
    await _open(tester, respond: _serveAgenda);

    await tester.ensureVisible(find.text('Madd Asli'));
    await tester.pump();
    await tester.tap(find.text('Madd Asli'));
    await tester.pump();

    expect(
      find.text('This lesson opens on Fri 16 Oct at 6:00 AM.'),
      findsOneWidget,
    );
  });

  testWidgets('an assignment opens the Assignments screen', (tester) async {
    await _open(tester, respond: _serveAgenda);

    await tester.tap(find.text('Steps of wudu'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AssignmentsScreen), findsOneWidget);
  });

  testWidgets('a learner with nothing dated sees a friendly empty state', (
    tester,
  ) async {
    await _open(tester, respond: (_) => _json(_today([])));

    expect(find.text('Nothing Coming Up'), findsOneWidget);
    expect(find.text('October 2026'), findsNothing);
  });

  testWidgets('a failed load says so and offers a retry', (tester) async {
    var fail = true;
    await _open(
      tester,
      respond: (request) =>
          fail ? _json({'message': 'boom'}, 500) : _serveAgenda(request),
    );

    expect(find.text('Could Not Load Calendar'), findsOneWidget);

    fail = false;
    await tester.tap(find.text('Retry'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Steps of wudu'), findsOneWidget);
  });

  testWidgets('asks the server for the long list', (tester) async {
    Uri? seen;
    await _open(
      tester,
      respond: (request) {
        if (request.url.path == '/api/user/today') seen = request.url;
        return _json(_agenda);
      },
    );

    expect(seen?.queryParameters['upcomingLimit'], '200');
  });
}
