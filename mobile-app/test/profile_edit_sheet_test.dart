import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:qspot/screens/auth/provider/auth_provider.dart';
import 'package:qspot/screens/profile/screens/profile_screen.dart';
import 'package:qspot/services/api_client.dart';
import 'package:qspot/widgets/common/home_sheet_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'profile form stays usable above the keyboard and validates input',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final auth = AuthProvider();
      addTearDown(auth.dispose);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: auth,
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Edit Profile'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeSheetShell), findsOneWidget);
      expect(find.text('Choose photo'), findsOneWidget);

      // Simulate a phone keyboard while the name field is focused.
      await tester.tap(find.byType(TextFormField).first);
      tester.view.viewInsets = const FakeViewPadding(bottom: 350);
      await tester.pumpAndSettle();
      final save = find.widgetWithText(FilledButton, 'Save profile');
      expect(tester.getBottomRight(save).dy, lessThanOrEqualTo(844 - 350));
      expect(tester.takeException(), isNull);

      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(find.text('Name is required'), findsOneWidget);
      expect(find.text('Class is required'), findsOneWidget);
      expect(find.byType(HomeSheetShell), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeSheetShell), findsNothing);
      expect(auth.user, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  // The class signs the student in, so it must match the sign-in list ("8").
  testWidgets('a class typed as 08 is saved as 8', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final sent = <Map<String, dynamic>>[];
    ApiClient.clientOverride = MockClient((request) async {
      if (request.method == 'PUT' && request.url.path == '/api/user/me') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        sent.add(body);
        return http.Response(
          jsonEncode({
            'user': {'id': 'u1', 'name': body['name'], 'class': body['class']},
          }),
          200,
        );
      }
      return http.Response('{}', 404);
    });
    addTearDown(() => ApiClient.clientOverride = null);
    final auth = AuthProvider();
    addTearDown(auth.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit Profile'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Ayesha Khan');
    await tester.enterText(find.byType(TextFormField).at(1), ' 08 ');
    await tester.tap(find.widgetWithText(FilledButton, 'Save profile'));
    await tester.pumpAndSettle();

    expect(sent.single['class'], '8');
    expect(auth.user?.classNumber, '8');
  });
}
