import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qspot/screens/video/widgets/player_dispose_notifier.dart';

void main() {
  testWidgets('shows its child and calls back only once it leaves the tree', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: PlayerDisposeNotifier(
          onDispose: () => calls++,
          child: const Text('player'),
        ),
      ),
    );
    expect(find.text('player'), findsOneWidget);
    expect(calls, 0);

    await tester.pumpWidget(const SizedBox());
    expect(find.text('player'), findsNothing);
    expect(calls, 1);
  });

  testWidgets('keeps one callback across rebuilds in place', (tester) async {
    var calls = 0;
    Widget build(String label) => Directionality(
      textDirection: TextDirection.ltr,
      child: PlayerDisposeNotifier(
        onDispose: () => calls++,
        child: Text(label),
      ),
    );

    await tester.pumpWidget(build('one'));
    await tester.pumpWidget(build('two'));

    expect(find.text('two'), findsOneWidget);
    expect(calls, 0);
  });
}
