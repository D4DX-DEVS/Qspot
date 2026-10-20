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

/// Picks a class the way the dropdown reports it. (Tapping through the open
/// menu is not reliable in the test harness.)
Future<void> _pickClass(WidgetTester tester, String classNumber) async {
  tester
      .widget<DropdownButtonFormField<String>>(
        find.byType(DropdownButtonFormField<String>),
      )
      .onChanged!(classNumber);
  await tester.pumpAndSettle();
}

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
    Future<void> fillStudent(WidgetTester tester, String phone) async {
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Ramu K');
      await tester.enterText(fields.at(1), phone);
      await tester.pump();
    }

    testWidgets('asks a student for a name and phone number, no class or OTP', (
      tester,
    ) async {
      await pumpHome(tester, const LoginScreen());

      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Which Class Are You In?'), findsNothing);
      expect(find.text('Date of Birth'), findsNothing);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.textContaining('OTP'), findsNothing);
      expect(find.text('Register Now'), findsOneWidget);
      expect(find.text('Sign in with date of birth'), findsOneWidget);
    });

    testWidgets('Sign In can always be tapped and says what is missing', (
      tester,
    ) async {
      respondWith({});
      await pumpHome(tester, const LoginScreen());
      expect(_buttonEnabled(tester), isTrue);

      await tester.tap(find.byType(GradientPillButton));
      await tester.pumpAndSettle();
      expect(find.text('Please enter your name'), findsOneWidget);
      expect(find.text('Please enter your phone number'), findsOneWidget);
      expect(requests, isEmpty, reason: 'nothing is sent');

      // From now on the messages follow the typing.
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Ramu K');
      await tester.enterText(fields.at(1), '98765');
      await tester.pump();
      expect(find.text('Please enter your name'), findsNothing);
      expect(
        find.text('Please enter a valid 10-digit phone number'),
        findsOneWidget,
      );

      await tester.enterText(fields.at(1), '9876543210');
      await tester.pump();
      expect(
        find.text('Please enter a valid 10-digit phone number'),
        findsNothing,
      );
    });

    testWidgets('a wrong name shows the server message and stays here', (
      tester,
    ) async {
      respondWith({
        '/api/user/login': (_) => http.Response(
          jsonEncode({
            'message': 'No student account matches this name and phone number.',
          }),
          404,
        ),
      });
      await pumpHome(tester, const LoginScreen());

      await fillStudent(tester, '9876543210');
      await tester.tap(find.byType(GradientPillButton));
      await tester.pumpAndSettle();

      final login = requests.singleWhere(
        (r) => r.url.path == '/api/user/login',
      );
      expect(jsonDecode(login.body), {'phone': '9876543210', 'name': 'Ramu K'});
      expect(
        find.text('No student account matches this name and phone number.'),
        findsOneWidget,
      );
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('a number from another country is sent with its code', (
      tester,
    ) async {
      respondWith({
        '/api/user/login': (_) => http.Response(
          jsonEncode({
            'message': 'No student account matches this name and phone number.',
          }),
          404,
        ),
      });
      await pumpHome(tester, const LoginScreen());
      await fillStudent(tester, '9876543210');

      await tester.tap(find.text('+91'));
      await tester.pumpAndSettle();
      expect(find.text('Choose your country'), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, 'emirates');
      await tester.pumpAndSettle();
      await tester.tap(find.text('United Arab Emirates'));
      await tester.pumpAndSettle();

      expect(find.text('Choose your country'), findsNothing);
      expect(find.text('+971'), findsOneWidget);
      expect(
        find.text('987654321'),
        findsOneWidget,
        reason: 'cut to the 9 digits a UAE number has',
      );
      await tester.tap(find.byType(GradientPillButton));
      await tester.pumpAndSettle();

      final login = requests.singleWhere(
        (r) => r.url.path == '/api/user/login',
      );
      expect(jsonDecode(login.body), {
        'phone': '+971987654321',
        'name': 'Ramu K',
      });
    });

    testWidgets('a teacher switches to date of birth and sends only that', (
      tester,
    ) async {
      respondWith({
        '/api/user/login': (_) => http.Response(
          jsonEncode({'message': 'No teacher account matches.'}),
          404,
        ),
      });
      await pumpHome(tester, const LoginScreen());
      await tester.enterText(find.byType(TextField).first, 'Ramu K');

      await tester.tap(find.text('Sign in with date of birth'));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerField), findsOneWidget);
      expect(find.text('Full Name'), findsNothing);
      expect(find.text('Register Now'), findsNothing);

      await tester.enterText(find.byType(TextField).first, '9876543210');
      await tester.tap(find.byType(GradientPillButton));
      await tester.pumpAndSettle();
      expect(find.text('Please choose your date of birth'), findsOneWidget);
      expect(requests, isEmpty, reason: 'no date yet');

      await _pickDob(tester);
      expect(find.text('Please choose your date of birth'), findsNothing);
      await tester.tap(find.byType(GradientPillButton));
      await tester.pumpAndSettle();

      final login = requests.singleWhere(
        (r) => r.url.path == '/api/user/login',
      );
      expect(jsonDecode(login.body), {
        'phone': '9876543210',
        'dob': _defaultPickedDob,
      }, reason: 'the name typed before switching is not sent');

      await tester.tap(find.text('Sign in with name'));
      await tester.pumpAndSettle();
      expect(find.text('Ramu K'), findsOneWidget, reason: 'the name is kept');
      expect(find.text('Register Now'), findsOneWidget);
    });

    testWidgets('after registering, signs in with that name and number', (
      tester,
    ) async {
      respondWith({
        '/api/courses': (_) => http.Response('[]', 200),
        '/api/user/register': (_) => http.Response(
          jsonEncode({'message': 'User registered successfully'}),
          201,
        ),
        '/api/user/login': (_) =>
            http.Response(jsonEncode({'message': 'Server busy'}), 503),
      });
      await pumpHome(tester, const LoginScreen());

      await tester.tap(find.text('Register Now'));
      await tester.pumpAndSettle();
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '9876543210');
      await tester.enterText(fields.at(1), 'Ayesha Khan');
      await _pickClass(tester, '8');
      await tester.ensureVisible(find.byType(GradientPillButton));
      await tester.tap(find.byType(GradientPillButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Number is correct'));
      await tester.pumpAndSettle();

      final login = requests.singleWhere(
        (r) => r.url.path == '/api/user/login',
      );
      expect(jsonDecode(login.body), {
        'phone': '9876543210',
        'name': 'Ayesha Khan',
      });
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Ayesha Khan'), findsOneWidget);
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

    Future<void> fillEverything(WidgetTester tester) async {
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '9876543210');
      await tester.enterText(fields.at(1), 'Ayesha Khan');
      await _pickClass(tester, '8');
    }

    testWidgets('no date of birth is asked: number, name and class do', (
      tester,
    ) async {
      respondWith({'/api/courses': (_) => http.Response('[]', 200)});
      await openRegistration(tester);
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(find.text('Date of Birth'), findsNothing);
      expect(find.byType(DatePickerField), findsNothing);
      expect(_buttonEnabled(tester), isFalse);

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '9876543210');
      await tester.enterText(fields.at(1), 'Ayesha Khan');
      await tester.pump();
      expect(_buttonEnabled(tester), isFalse, reason: 'no class yet');

      await _pickClass(tester, '8');
      expect(_buttonEnabled(tester), isTrue);
    });

    testWidgets(
      'Create Account warns about OTP verification; Edit number goes back, '
      'confirming registers and hands back name + phone',
      (tester) async {
        respondWith({
          '/api/courses': (_) => http.Response('[]', 200),
          '/api/user/register': (_) => http.Response(
            jsonEncode({'message': 'User registered successfully'}),
            201,
          ),
        });
        final pushed = await openRegistration(tester);
        await fillEverything(tester);

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
        expect(body.containsKey('dob'), isFalse);

        expect(pushed.done, isTrue);
        final account = pushed.account;
        expect(account?.phone, '9876543210');
        expect(account?.country.iso, 'IN');
        expect(account?.name, 'Ayesha Khan');
        expect(find.byType(RegistrationScreen), findsNothing);
      },
    );

    testWidgets('a UK number drops its leading 0 and is sent with +44', (
      tester,
    ) async {
      respondWith({
        '/api/courses': (_) => http.Response('[]', 200),
        '/api/user/register': (_) => http.Response(
          jsonEncode({'message': 'User registered successfully'}),
          201,
        ),
      });
      final pushed = await openRegistration(tester);
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('+91'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '+44');
      await tester.pumpAndSettle();
      await tester.tap(find.text('United Kingdom'));
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '07400123456');
      await tester.enterText(fields.at(1), 'Ayesha Khan');
      await _pickClass(tester, '8');
      expect(find.text('7400123456'), findsOneWidget);

      await tester.ensureVisible(find.byType(GradientPillButton));
      await tester.tap(find.byType(GradientPillButton));
      await tester.pumpAndSettle();
      expect(find.text('+44 7400123456'), findsOneWidget);
      await tester.tap(find.text('Number is correct'));
      await tester.pumpAndSettle();

      final register = requests.singleWhere(
        (r) => r.url.path == '/api/user/register',
      );
      expect(jsonDecode(register.body)['phone'], '+447400123456');
      expect(pushed.account?.phone, '7400123456');
      expect(pushed.account?.country.iso, 'GB');
    });
  });
}
