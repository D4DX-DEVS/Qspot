import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:qspot/screens/assignment/model/assignment_model.dart';
import 'package:qspot/screens/assignment/screens/assignment_detail_screen.dart';
import 'package:qspot/services/api_client.dart';
import 'package:qspot/services/common/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _openDetail(
  WidgetTester tester,
  Map<String, dynamic> submission,
) async {
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
          'submission': submission,
        }),
        200,
      );
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
}
