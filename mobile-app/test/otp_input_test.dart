import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qspot/widgets/common/otp_input.dart';

void main() {
  Finder box(int i) => find.byType(TextField).at(i);

  Future<TextEditingController> pumpOtp(
    WidgetTester tester, {
    int length = 6,
  }) async {
    final controller = TextEditingController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OtpInput(
            controller: controller,
            length: length,
            autofocus: false,
          ),
        ),
      ),
    );
    return controller;
  }

  testWidgets('renders one box per digit', (tester) async {
    await pumpOtp(tester);
    expect(find.byType(TextField), findsNWidgets(6));
  });

  testWidgets('typing a digit fills the box and advances focus', (
    tester,
  ) async {
    final controller = await pumpOtp(tester);

    await tester.showKeyboard(box(0));
    tester.testTextInput.enterText('1');
    await tester.pump();

    expect(controller.text, '1');
    expect(
      tester.widget<TextField>(box(1)).focusNode!.hasFocus,
      isTrue,
      reason: 'focus should move to the next box',
    );
  });

  testWidgets('pasting a whole code fills every box', (tester) async {
    final controller = await pumpOtp(tester);

    await tester.showKeyboard(box(0));
    tester.testTextInput.enterText('123456');
    await tester.pump();

    expect(controller.text, '123456');
    for (var i = 0; i < 6; i++) {
      expect(tester.widget<TextField>(box(i)).controller!.text, '${i + 1}');
    }
  });

  testWidgets('backspace on an empty box clears the previous one', (
    tester,
  ) async {
    final controller = await pumpOtp(tester);

    await tester.showKeyboard(box(0));
    tester.testTextInput.enterText('123456');
    await tester.pump();
    expect(controller.text, '123456');

    await tester.showKeyboard(box(5));
    tester.testTextInput.enterText('');
    await tester.pump();
    expect(controller.text, '12345');

    await tester.showKeyboard(box(5));
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();
    expect(controller.text, '1234');
  });

  testWidgets('onCompleted fires only for a full code', (tester) async {
    String? completed;
    final controller = TextEditingController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OtpInput(
            controller: controller,
            autofocus: false,
            onCompleted: (value) => completed = value,
          ),
        ),
      ),
    );

    await tester.showKeyboard(box(0));
    tester.testTextInput.enterText('123');
    await tester.pump();
    expect(completed, isNull);

    tester.testTextInput.enterText('123456');
    await tester.pump();
    expect(completed, '123456');
  });
}
