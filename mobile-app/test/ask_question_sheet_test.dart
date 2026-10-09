import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:qspot/screens/question/screens/ask_question_screen.dart';
import 'package:qspot/screens/speaker/model/speaker_model.dart';
import 'package:qspot/screens/speaker/provider/speaker_provider.dart';
import 'package:qspot/services/api_client.dart';
import 'package:qspot/services/common/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Opens the ask sheet over a plain screen on a [screen]-sized phone.
Future<void> openSheet(WidgetTester tester, Size screen) async {
  tester.view.physicalSize = screen;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final speakers = SpeakerProvider()
    ..seedSpeakers([
      SpeakerModel(id: 's1', name: 'Dr. Asha', designation: 'Physics'),
    ]);
  addTearDown(speakers.dispose);

  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: speakers,
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => AskQuestionScreen.show(context),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

/// Picks the faculty and types a subject and question.
Future<void> fillForm(WidgetTester tester) async {
  await tester.tap(find.byType(DropdownButton<SpeakerModel>));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Dr. Asha').last);
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField).first, 'Gravity');
  await tester.enterText(find.byType(TextFormField).last, 'Why do we fall?');
}

Future<void> tapSubmit(WidgetTester tester) async {
  final submit = find.text('Submit Question');
  await tester.ensureVisible(submit);
  await tester.pumpAndSettle();
  await tester.tap(submit);
  await tester.pumpAndSettle();
}

/// The snack bar must be shown by the sheet itself; one shown on the screen
/// behind the sheet is covered and never seen.
Finder sheetSnackBar(String text) => find.descendant(
  of: find.byType(AskQuestionScreen),
  matching: find.widgetWithText(SnackBar, text),
);

void main() {
  // Phone portrait and landscape, each with a typical keyboard height.
  const cases = {
    'portrait': (Size(390, 844), 350.0),
    'landscape': (Size(844, 390), 200.0),
  };

  for (final MapEntry(key: name, value: (screen, keyboard)) in cases.entries) {
    testWidgets('ask sheet keeps the question field above the keyboard '
        '($name)', (tester) async {
      await openSheet(tester, screen);

      // Phone keyboard opens while the last field (the question) is focused.
      final question = find.byType(TextFormField).last;
      await tester.ensureVisible(question);
      await tester.pumpAndSettle();
      await tester.tap(question);
      tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
      await tester.pumpAndSettle();

      final keyboardTop = screen.height - keyboard;
      final scroll = find.byType(SingleChildScrollView);
      expect(tester.getRect(scroll).bottom, lessThanOrEqualTo(keyboardTop));
      // The first line of the question field shows above the keyboard.
      expect(
        tester.getTopLeft(question).dy + 48,
        lessThanOrEqualTo(keyboardTop),
      );
      expect(tester.getTopLeft(question).dy, greaterThanOrEqualTo(0));
      expect(tester.takeException(), isNull);
    });
  }

  group('ask sheet snack bars', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await StorageService.init();
    });
    tearDown(() => ApiClient.clientOverride = null);

    testWidgets('no faculty: warning shows on the sheet above the keyboard', (
      tester,
    ) async {
      await openSheet(tester, const Size(390, 844));
      await tester.tap(find.byType(TextFormField).last);
      tester.view.viewInsets = const FakeViewPadding(bottom: 350);
      await tester.pumpAndSettle();

      await tapSubmit(tester);

      final snack = sheetSnackBar(
        'Please choose a faculty to send your question to',
      );
      expect(snack, findsOneWidget);
      expect(tester.getRect(snack).bottom, lessThanOrEqualTo(844.0 - 350));
      expect(tester.takeException(), isNull);
    });

    testWidgets('sent: success shows on the sheet and the form clears', (
      tester,
    ) async {
      String? postedPath;
      ApiClient.clientOverride = MockClient((request) async {
        postedPath = request.url.path;
        return http.Response('{"message":"ok"}', 201);
      });
      await openSheet(tester, const Size(390, 844));
      await fillForm(tester);

      await tapSubmit(tester);

      expect(postedPath, endsWith('/api/questions'));
      expect(
        sheetSnackBar('Your question has been sent to the faculty'),
        findsOneWidget,
      );
      expect(find.text('Gravity'), findsNothing);
      expect(find.text('Choose a Faculty'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('offline: friendly error shows on the sheet', (tester) async {
      ApiClient.clientOverride = MockClient(
        (_) async => throw http.ClientException('Failed host lookup'),
      );
      await openSheet(tester, const Size(390, 844));
      await fillForm(tester);

      await tapSubmit(tester);

      expect(
        sheetSnackBar(
          "We couldn't send your question. Can't reach the server. "
          'Please check your internet connection and try again.',
        ),
        findsOneWidget,
      );
      // The typed question stays so the student can retry.
      expect(find.text('Gravity'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
