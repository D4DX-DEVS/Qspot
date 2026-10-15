import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:qspot/screens/auth/provider/auth_provider.dart';
import 'package:qspot/screens/auth/service/auth_service.dart';
import 'package:qspot/services/api_client.dart';
import 'package:qspot/services/common/storage_service.dart';

/// Sign-in with phone + date of birth, through the real service and provider
/// with a fake HTTP layer.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    // StorageService keeps its SharedPreferences instance between tests.
    await AuthService().logout();
  });
  tearDown(() => ApiClient.clientOverride = null);

  const okBody = {
    'message': 'Login successful',
    'token': 'tok-abc',
    'user': {
      'id': 'u1',
      'name': 'Ayesha',
      'phone': '9876543210',
      'class': '8',
      'role': 'student',
      'dob': '2010-05-03T00:00:00.000Z',
      'phoneVerified': false,
    },
  };

  test(
    'sends phone and dob to /api/user/login and saves the session',
    () async {
      http.Request? seen;
      ApiClient.clientOverride = MockClient((request) async {
        seen = request;
        return http.Response(jsonEncode(okBody), 200);
      });

      final result = await AuthService().login('9876543210', '2010-05-03');

      expect(seen!.url.path, '/api/user/login');
      expect(seen!.method, 'POST');
      expect(jsonDecode(seen!.body), {
        'phone': '9876543210',
        'dob': '2010-05-03',
      });
      expect(result['success'], isTrue);
      expect(await AuthService().isLoggedIn(), isTrue);
      expect(await AuthService().getSavedToken(), 'tok-abc');
      final saved = await AuthService().getSavedUser();
      expect(saved?.phoneVerified, isFalse);
      expect(saved?.hasDob, isTrue);
    },
  );

  test('a wrong date gives the server message and saves nothing', () async {
    ApiClient.clientOverride = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'message': 'No account matches this phone number and date of birth.',
        }),
        404,
      ),
    );

    final result = await AuthService().login('9876543210', '2010-05-04');

    expect(result['success'], isFalse);
    expect(
      result['message'],
      'No account matches this phone number and date of birth.',
    );
    expect(await AuthService().isLoggedIn(), isFalse);
    expect(await StorageService.getString('auth_token'), isEmpty);
  });

  test(
    'an account without a date of birth gets the explaining message',
    () async {
      ApiClient.clientOverride = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'code': 'DOB_MISSING',
            'message': 'No date of birth is saved for this number yet.',
          }),
          409,
        ),
      );

      final result = await AuthService().login('9111111111', '2010-05-03');

      expect(result['success'], isFalse);
      expect(
        result['message'],
        'No date of birth is saved for this number yet.',
      );
    },
  );

  test('too many attempts shows the wait message', () async {
    ApiClient.clientOverride = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'message':
              'Too many failed attempts. Please try again in 15 minutes.',
        }),
        429,
      ),
    );

    final result = await AuthService().login('9876543210', '2010-05-04');

    expect(result['success'], isFalse);
    expect(result['message'], contains('Too many failed attempts'));
  });

  test('no connection gives a friendly message', () async {
    ApiClient.clientOverride = MockClient(
      (_) async => throw http.ClientException('offline'),
    );

    final result = await AuthService().login('9876543210', '2010-05-03');

    expect(result['success'], isFalse);
    expect(result['message'], 'Network error. Please try again.');
  });

  test('AuthProvider.login marks the app signed in', () async {
    ApiClient.clientOverride = MockClient(
      (_) async => http.Response(jsonEncode(okBody), 200),
    );
    final auth = AuthProvider();

    final result = await auth.login('9876543210', '2010-05-03');

    expect(result['success'], isTrue);
    expect(auth.isAuthenticated, isTrue);
    expect(auth.user?.name, 'Ayesha');
    expect(auth.isLoading, isFalse);
  });

  test('AuthProvider.login stays signed out after a failure', () async {
    ApiClient.clientOverride = MockClient(
      (_) async =>
          http.Response(jsonEncode({'message': 'No account matches.'}), 404),
    );
    final auth = AuthProvider();

    final result = await auth.login('9876543210', '2010-05-04');

    expect(result['success'], isFalse);
    expect(auth.isAuthenticated, isFalse);
    expect(auth.errorMessage, 'No account matches.');
  });

  test('registration sends the date of birth', () async {
    http.Request? seen;
    ApiClient.clientOverride = MockClient((request) async {
      seen = request;
      return http.Response(
        jsonEncode({'message': 'ok', 'user': okBody['user']}),
        201,
      );
    });

    final result = await AuthService().register(
      phone: '9876543210',
      name: 'Ayesha',
      classNumber: '8',
      dob: '2010-05-03',
    );

    expect(result['success'], isTrue);
    expect(jsonDecode(seen!.body)['dob'], '2010-05-03');
    expect(
      await AuthService().isLoggedIn(),
      isFalse,
      reason: 'no token issued',
    );
  });
}
