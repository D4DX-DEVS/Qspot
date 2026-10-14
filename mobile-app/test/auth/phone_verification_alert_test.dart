import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qspot/screens/auth/widgets/phone_verification_alert.dart';

/// Opens the alert from a button and records what it resolved to.
class _Host {
  bool? result;
  bool resolved = false;
}

Future<_Host> _open(WidgetTester tester, {double textScale = 1}) async {
  final host = _Host();
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                host.result = await PhoneVerificationAlert.show(
                  context,
                  phone: '9876543210',
                );
                host.resolved = true;
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return host;
}

void main() {
  tearDown(() {
    final binding = TestWidgetsFlutterBinding.instance;
    binding.platformDispatcher.clearAllTestValues();
  });

  testWidgets('shows the number and says it will be verified later', (
    tester,
  ) async {
    await _open(tester);

    expect(find.text('Check your phone number'), findsOneWidget);
    expect(find.text('+91 9876543210'), findsOneWidget);
    expect(find.textContaining('one-time code (OTP) later'), findsOneWidget);
    expect(
      find.textContaining('your data will become inaccessible'),
      findsOneWidget,
    );
  });

  testWidgets('"Number is correct" resolves to true', (tester) async {
    final host = await _open(tester);

    await tester.tap(find.text('Number is correct'));
    await tester.pumpAndSettle();

    expect(host.resolved, isTrue);
    expect(host.result, isTrue);
    expect(find.byType(PhoneVerificationAlert), findsNothing);
  });

  testWidgets('"Edit number" resolves to false', (tester) async {
    final host = await _open(tester);

    await tester.tap(find.text('Edit number'));
    await tester.pumpAndSettle();

    expect(host.resolved, isTrue);
    expect(host.result, isFalse);
  });

  testWidgets('tapping outside does not dismiss it', (tester) async {
    final host = await _open(tester);

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(find.byType(PhoneVerificationAlert), findsOneWidget);
    expect(host.resolved, isFalse);
  });

  testWidgets('follows the phone dark setting', (tester) async {
    Color? dialogColor() => tester
        .widget<Material>(
          find
              .descendant(
                of: find.byType(AlertDialog),
                matching: find.byType(Material),
              )
              .first,
        )
        .color;

    await _open(tester);
    final light = dialogColor();
    await tester.tap(find.text('Edit number'));
    await tester.pumpAndSettle();

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pump();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final dark = dialogColor();

    expect(light, isNot(dark));
    expect(tester.takeException(), isNull);
  });

  testWidgets('fits a small phone with large text, buttons reachable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final host = await _open(tester, textScale: 1.3);

    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Number is correct'));
    await tester.tap(find.text('Number is correct'));
    await tester.pumpAndSettle();
    expect(host.result, isTrue);
  });
}
