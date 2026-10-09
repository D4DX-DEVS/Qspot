import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qspot/widgets/common/common_app_bar.dart';

void main() {
  testWidgets('root drawer pages show menu and pushed pages show back', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: const CommonAppBar(title: 'Home', isDrawerNeeded: true),
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.push<void>(
                tester.element(find.byType(ElevatedButton)),
                MaterialPageRoute<void>(
                  builder: (_) => const Scaffold(
                    appBar: CommonAppBar(title: 'Nested', isDrawerNeeded: true),
                  ),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Menu'), findsOneWidget);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Back'), findsOneWidget);
    expect(find.byTooltip('Menu'), findsNothing);
  });
}
