import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qspot/screens/assignment/model/assignment_model.dart';
import 'package:qspot/screens/assignment/screens/assignment_detail_screen.dart';
import 'package:qspot/services/api_client.dart';
import 'package:qspot/services/common/storage_service.dart';
import 'package:qspot/widgets/common/surface_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _openDetail(
  WidgetTester tester,
  Map<String, dynamic> submission, {
  String? dueAt,
  http.Response? submitResponse,
}) async {
  SharedPreferences.setMockInitialValues({});
  await StorageService.init();
  ApiClient.clientOverride = MockClient((request) async {
    if (request.url.path.endsWith('/api/user/assignments/a1')) {
      return http.Response(
        jsonEncode({
          '_id': 'a1',
          'title': 'Summary of the lesson',
          'instructions': 'Keep it short.',
          'status': submission['status'],
          'dueAt': dueAt,
          'submission': submission,
        }),
        200,
      );
    }
    if (request.url.path.endsWith('/submissions') && submitResponse != null) {
      return submitResponse;
    }
    return http.Response('{}', 200);
  });
  addTearDown(() => ApiClient.clientOverride = null);

  await tester.pumpWidget(
    const MaterialApp(
      home: AssignmentDetailScreen(
        assignment: AssignmentModel(id: 'a1', title: 'Summary of the lesson'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('marked work says it was reviewed and shows the score', (
    tester,
  ) async {
    await _openDetail(tester, {
      'status': 'graded',
      'text': 'My summary',
      'submittedAt': '2026-10-15T06:00:00Z',
      'grade': 55,
      'feedback': 'try to explain more',
    });

    expect(find.text('Reviewed'), findsOneWidget);
    expect(find.text('Submitted'), findsNothing);
    expect(find.text('Your teacher has reviewed your work.'), findsOneWidget);
    expect(find.text('Your work has been sent to your teacher.'), findsNothing);
    expect(find.text('try to explain more'), findsOneWidget);
    expect(find.text('Score: 55'), findsOneWidget);
    // The heading sits above the feedback card, like "What to Do".
    expect(
      find.ancestor(
        of: find.text('Teacher Feedback'),
        matching: find.byType(SurfaceCard),
      ),
      findsNothing,
    );
    expect(
      find.ancestor(
        of: find.text('try to explain more'),
        matching: find.byType(SurfaceCard),
      ),
      findsOneWidget,
    );
  });

  testWidgets('work returned for changes asks for it again', (tester) async {
    await _openDetail(tester, {
      'status': 'returned',
      'text': 'My summary',
      'submittedAt': '2026-10-15T06:00:00Z',
      'feedback': 'Add an example',
    });

    expect(find.text('Changes Asked'), findsOneWidget);
    expect(find.textContaining('asked for changes'), findsOneWidget);
    expect(find.text('Add an example'), findsOneWidget);
    expect(find.text('Your Answer'), findsOneWidget);
    expect(find.text('Your work has been sent to your teacher.'), findsNothing);
  });

  testWidgets('work marked by parts shows each part under the feedback', (
    tester,
  ) async {
    await _openDetail(tester, {
      'status': 'graded',
      'text': 'My recitation',
      'submittedAt': '2026-10-15T06:00:00Z',
      'grade': 7,
      'feedback': 'Hold the madd longer',
      'rubricScores': [
        {'label': 'Makharij', 'points': 3, 'maxPoints': 4},
        {'label': 'Madd length', 'points': 2, 'maxPoints': 4},
        {'label': 'Fluency', 'points': 2, 'maxPoints': 2},
      ],
    });

    expect(find.text('Score: 7'), findsOneWidget);
    expect(find.text('Makharij'), findsOneWidget);
    expect(find.text('3 / 4'), findsOneWidget);
    expect(find.text('2 / 2'), findsOneWidget);
  });

  testWidgets('a score with no written feedback is still shown', (
    tester,
  ) async {
    await _openDetail(tester, {
      'status': 'graded',
      'text': 'My summary',
      'submittedAt': '2026-10-15T06:00:00Z',
      'grade': 40,
    });

    expect(find.text('Teacher Feedback'), findsOneWidget);
    expect(find.text('Score: 40'), findsOneWidget);
  });

  testWidgets('the sent response stays hidden until its arrow is tapped', (
    tester,
  ) async {
    await _openDetail(tester, {
      'status': 'graded',
      'text': 'My summary',
      'submittedAt': '2026-10-15T06:00:00Z',
      'grade': 55,
      'files': [
        {'name': 'reading.m4a', 'url': 'x', 'mimeType': 'audio/mp4'},
      ],
    });

    expect(find.text('Your Response'), findsOneWidget);
    expect(find.text('My summary'), findsNothing);
    expect(find.text('reading.m4a'), findsNothing);

    await tester.tap(find.byIcon(LucideIcons.chevronDown));
    await tester.pumpAndSettle();

    expect(find.text('My summary'), findsOneWidget);
    expect(find.text('reading.m4a'), findsOneWidget);

    await tester.tap(find.byIcon(LucideIcons.chevronDown));
    await tester.pumpAndSettle();

    expect(find.text('My summary'), findsNothing);
  });

  testWidgets('work waiting for the teacher says it was sent', (tester) async {
    await _openDetail(tester, {
      'status': 'submitted',
      'text': 'My summary',
      'submittedAt': '2026-10-15T06:00:00Z',
    });

    expect(find.text('Submitted'), findsOneWidget);
    expect(
      find.text('Your work has been sent to your teacher.'),
      findsOneWidget,
    );
    expect(find.text('Teacher Feedback'), findsNothing);
  });

  testWidgets('a missed deadline says time is over and hides the answer box', (
    tester,
  ) async {
    await _openDetail(tester, {}, dueAt: '2026-01-01T00:00:00Z');

    expect(find.text('Time Is Over'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('Time Is Over'), findsNothing);
    expect(find.text('Past Due'), findsOneWidget);
    expect(find.textContaining('time for this assignment is over'), findsOne);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Submit Assignment'), findsNothing);
  });

  testWidgets('work sent back after the deadline can still be sent again', (
    tester,
  ) async {
    await _openDetail(tester, {
      'status': 'returned',
      'text': 'My summary',
      'submittedAt': '2025-12-30T06:00:00Z',
      'feedback': 'Add an example',
    }, dueAt: '2026-01-01T00:00:00Z');

    expect(find.text('Time Is Over'), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Submit Assignment'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Submit Assignment'), findsOneWidget);
  });

  testWidgets('a send turned away for the deadline locks the answer box', (
    tester,
  ) async {
    await _openDetail(
      tester,
      {},
      dueAt: '2099-01-01T00:00:00Z',
      submitResponse: http.Response(
        jsonEncode({
          'message': 'The time for this assignment is over',
          'code': 'assignment_closed',
        }),
        403,
      ),
    );
    expect(find.text('Time Is Over'), findsNothing);

    await tester.enterText(find.byType(TextField), 'My summary');
    await tester.ensureVisible(find.text('Submit Assignment'));
    await tester.tap(find.text('Submit Assignment'));
    await tester.pumpAndSettle();

    expect(find.text('Time Is Over'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
  });
}
