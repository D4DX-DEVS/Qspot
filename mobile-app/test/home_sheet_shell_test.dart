import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qspot/widgets/common/home_sheet_shell.dart';

void main() {
  // A phone in landscape: the notch leaves 62px of side inset, and a modal
  // sheet is capped at 640px wide and centred, so it never reaches those edges.
  testWidgets('side safe-area insets do not push a centred sheet inward', (
    tester,
  ) async {
    const marker = Key('marker');
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(padding: const EdgeInsets.fromLTRB(62, 0, 62, 21)),
          child: child!,
        ),
        home: const Scaffold(
          body: Center(
            child: SizedBox(
              width: 640,
              child: HomeSheetShell(
                child: SafeArea(
                  top: false,
                  child: Align(
                    heightFactor: 1,
                    alignment: Alignment.centerLeft,
                    child: SizedBox.square(key: marker, dimension: 40),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final shell = find.byType(HomeSheetShell);
    final inset =
        tester.getTopLeft(find.byKey(marker)).dx - tester.getTopLeft(shell).dx;
    expect(inset, 0, reason: 'content should sit at the sheet edge');

    // The bottom inset (home indicator) must still be respected.
    expect(tester.getSize(shell).height, 40 + 21);
  });
}
