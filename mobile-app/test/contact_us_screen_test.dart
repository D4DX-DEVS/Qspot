import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qspot/screens/common/screens/contact_us_screen.dart';

void main() {
  testWidgets('phone row offers call and WhatsApp actions', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ContactUsScreen()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Call or WhatsApp'), findsOneWidget);
    await tester.tap(find.textContaining('Call or WhatsApp'));
    await tester.pumpAndSettle();

    expect(find.text('Call us'), findsOneWidget);
    expect(find.text('Message on WhatsApp'), findsOneWidget);
  });
}
