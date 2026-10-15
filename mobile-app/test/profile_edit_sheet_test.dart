import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:qspot/screens/auth/provider/auth_provider.dart';
import 'package:qspot/screens/profile/screens/profile_screen.dart';
import 'package:qspot/widgets/common/home_sheet_shell.dart';

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
}
