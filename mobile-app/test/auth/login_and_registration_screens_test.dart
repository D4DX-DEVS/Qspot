import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:qspot/screens/auth/model/registered_account.dart';
import 'package:qspot/screens/auth/provider/auth_provider.dart';
import 'package:qspot/screens/auth/screens/login_screen.dart';
import 'package:qspot/screens/auth/screens/registration_screen.dart';
import 'package:qspot/screens/auth/widgets/date_picker_field.dart';
import 'package:qspot/screens/auth/widgets/gradient_pill_button.dart';
import 'package:qspot/screens/auth/widgets/phone_verification_alert.dart';
import 'package:qspot/services/api_client.dart';
import 'package:qspot/utils/dob_format.dart';

/// The date the picker opens on, which tapping OK picks: 12 years ago today.
String get _defaultPickedDob {
  final now = DateTime.now();
  return formatDobForApi(DateTime(now.year - 12, now.month, now.day));
}

bool _buttonEnabled(WidgetTester tester) =>
    tester
        .widget<GradientPillButton>(find.byType(GradientPillButton))
        .onPressed !=
    null;

Future<void> _pickDob(WidgetTester tester) async {
  await tester.ensureVisible(find.byType(DatePickerField));
  await tester.tap(find.byType(DatePickerField));
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

/// What the registration screen handed back to the screen that opened it.
class _Pushed {
  RegisteredAccount? account;
  bool done = false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<http.Request> requests;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    requests = [];
  });
  tearDown(() => ApiClient.clientOverride = null);

  void respondWith(Map<String, http.Response Function(http.Request)> routes) {
    ApiClient.clientOverride = MockClient((request) async {
      requests.add(request);
      final handler = routes[request.url.path];
      return handler == null ? http.Response('{}', 404) : handler(request);
    });
  }

  Future<void> pumpHome(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // The test font is one em wide per glyph, so rows that fit on a device
    // still report overflow here.
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exception.toString().contains('A RenderFlex overflowed')) {
        return;
      }
      previousOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = previousOnError);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: MaterialApp(home: home),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('LoginScreen', () {
    testWidgets('asks for a phone number and date of birth, no OTP', (
      tester,
    ) async {
      await pumpHome(tester, const LoginScreen());

      expect(find.text('Date of Birth'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.textContaining('OTP'), findsNothing);
      expect(find.text('Register Now'), findsOneWidget);
    });

    testWidgets('Sign In stays off until both phone and date are filled', (
      tester,
    ) async {
      await pumpHome(tester, const LoginScreen());
      expect(_buttonEnabled(tester), isFalse);

      await tester.enterText(find.byType(TextField).first, '98765');
      await tester.pump();
      expect(_buttonEnabled(tester), isFalse, reason: 'short number');

      await tester.enterText(find.byType(TextField).first, '9876543210');
      await tester.pump();
      expect(_buttonEnabled(tester), isFalse, reason: 'no date yet');

      await _pickDob(tester);
      expect(find.text(_defaultPickedDob), findsOneWidget);
      expect(_buttonEnabled(tester), isTrue);
    });

    testWidgets('a wrong date shows the server message and stays here', (
      tester,
    ) async {
      respondWith({
        '/api/user/login': (_) => http.Response(
          jsonEncode({
            'message':
                'No account matches this phone number and date of birth.',
          }),
          404,
        ),
      });
      await pumpHome(tester, const LoginScreen());

      await tester.enterText(find.byType(TextField).first, '9876543210');
      await _pickDob(tester);
      await tester.tap(find.byType(GradientPillButton));
      await tester.pumpAndSettle();

      final login = requests.singleWhere(
        (r) => r.url.path == '/api/user/login',
      );
      expect(jsonDecode(login.body), {
        'phone': '9876543210',
        'dob': _defaultPickedDob,
      });
      expect(
        find.text('No account matches this phone number and date of birth.'),
        findsOneWidget,
      );
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });

  group('RegistrationScreen', () {
    Future<_Pushed> openRegistration(WidgetTester tester) async {
      final pushed = _Pushed();
      await pumpHome(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  pushed.account = await Navigator.of(context)
                      .push<RegisteredAccount>(
                        MaterialPageRoute(
                          builder: (_) => const RegistrationScreen(),
                        ),
                      );
                  pushed.done = true;
                },
                child: const Text('go'),
              ),
            ),
          ),
        ),
      );
      return pushed;
    }

    Future<void> fillEverythingButDob(WidgetTester tester) async {
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '9876543210');
      await tester.enterText(fields.at(1), 'Ayesha Khan');
      // Picks "Class 8" the way the dropdown reports it. (Tapping through the
      // open menu is not reliable in the test harness.)
      tester
          .widget<DropdownButtonFormField<String>>(
            find.byType(DropdownButtonFormField<String>),
          )
          .onChanged!('8');
      await tester.pumpAndSettle();
    }

    testWidgets('the date of birth is required, not optional', (tester) async {
      respondWith({'/api/courses': (_) => http.Response('[]', 200)});
      await openRegistration(tester);
      await fillEverythingButDob(tester);

      expect(find.textContaining('Optional'), findsNothing);
      expect(
        _buttonEnabled(tester),
        isFalse,
        reason: 'everything but the date is filled',
      );

      await _pickDob(tester);
      expect(_buttonEnabled(tester), isTrue);
    });

    testWidgets(
      'Create Account warns about OTP verification; Edit number goes back, '
      'confirming registers and hands back phone + dob',
      (tester) async {
        respondWith({
          '/api/courses': (_) => http.Response('[]', 200),
          '/api/user/register': (_) => http.Response(
            jsonEncode({'message': 'User registered successfully'}),
            201,
          ),
        });
        final pushed = await openRegistration(tester);
        await fillEverythingButDob(tester);
        await _pickDob(tester);

        // First try: the student chooses to edit the number.
        await tester.ensureVisible(find.byType(GradientPillButton));
        await tester.tap(find.byType(GradientPillButton));
        await tester.pumpAndSettle();
        expect(find.byType(PhoneVerificationAlert), findsOneWidget);
        expect(find.text('+91 9876543210'), findsOneWidget);
        expect(find.textContaining('inaccessible'), findsOneWidget);
        await tester.tap(find.text('Edit number'));
        await tester.pumpAndSettle();
        expect(
          requests.where((r) => r.url.path == '/api/user/register'),
          isEmpty,
          reason: 'nothing is sent until the number is confirmed',
        );
        expect(find.byType(RegistrationScreen), findsOneWidget);

        // Second try: the student confirms.
        await tester.tap(find.byType(GradientPillButton));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Number is correct'));
        await tester.pumpAndSettle();

        final register = requests.singleWhere(
          (r) => r.url.path == '/api/user/register',
        );
        final body = jsonDecode(register.body) as Map<String, dynamic>;
        expect(body['phone'], '9876543210');
        expect(body['name'], 'Ayesha Khan');
        expect(body['class'], '8');
        expect(body['dob'], _defaultPickedDob);

        expect(pushed.done, isTrue);
        final account = pushed.account;
        expect(account?.phone, '9876543210');
        expect(formatDobForApi(account!.dob), _defaultPickedDob);
        expect(find.byType(RegistrationScreen), findsNothing);
      },
    );
  });
}
