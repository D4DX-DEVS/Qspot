import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:qspot/screens/assignment/screens/assignments_screen.dart';
import 'package:qspot/services/api_client.dart';
import 'package:qspot/services/common/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('assignment history is discoverable and filters submitted work', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
    ApiClient.clientOverride = MockClient((request) async {
      if (request.url.path.endsWith('/api/user/assignments')) {
        return http.Response(
          '[{"id":"a1","title":"Quran reflection","subject":"Quran",'
          '"status":"submitted","submittedAt":"2026-01-01T00:00:00Z"}]',
          200,
        );
      }
      return http.Response('[]', 200);
    });
    addTearDown(() => ApiClient.clientOverride = null);

    await tester.pumpWidget(const MaterialApp(home: AssignmentsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('No Assignments To Do'), findsOneWidget);
    expect(find.text('History (1)'), findsOneWidget);

    await tester.tap(find.text('History (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Quran reflection'), findsOneWidget);
    expect(find.text('Submitted'), findsOneWidget);
  });
}
