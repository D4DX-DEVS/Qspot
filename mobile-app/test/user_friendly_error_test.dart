import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:qspot/screens/subject/provider/subject_provider.dart';
import 'package:qspot/services/api_client.dart';
import 'package:qspot/utils/user_friendly_error.dart';

const _techTerms = [
  'Exception',
  'Socket',
  'errno',
  'uri=',
  'https://',
  'digitalocean',
];

void _expectNoTechnicalText(String message) {
  for (final term in _techTerms) {
    expect(message, isNot(contains(term)));
  }
}

class _FailingClient extends http.BaseClient {
  _FailingClient(this._error);

  final Object _error;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      Future.error(_error);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('userFriendlyError', () {
    test('timeout reads as a slow connection', () {
      final message = userFriendlyError(
        TimeoutException('Future not completed', const Duration(seconds: 15)),
      );

      expect(message, contains('taking longer than usual'));
      _expectNoTechnicalText(message);
    });

    test('ClientException wrapping a failed host lookup reads as offline', () {
      final message = userFriendlyError(
        http.ClientException(
          "SocketException: Failed host lookup: 'qspot-app-vcbgp.ondigitalocean.app' "
          '(OS Error: nodename nor servname provided, or not known, errno = 8), '
          'uri=https://qspot-app-vcbgp.ondigitalocean.app/api/subjects',
        ),
      );

      expect(message, contains("Can't reach the server"));
      _expectNoTechnicalText(message);
    });

    test('plain SocketException reads as offline', () {
      final message = userFriendlyError(const SocketException('no route'));

      expect(message, contains("Can't reach the server"));
    });

    test('server 5xx hides the server text', () {
      final message = userFriendlyError(ApiException(502, 'Bad gateway'));

      expect(message, contains('on our side'));
      expect(message, isNot(contains('Bad gateway')));
    });

    test('4xx keeps the server-provided readable message', () {
      expect(
        userFriendlyError(ApiException(404, 'Subject not found')),
        'Subject not found',
      );
    });

    test('unknown error falls back to a generic line', () {
      final message = userFriendlyError(StateError('boom'));

      expect(message, 'Something went wrong. Please try again.');
    });
  });

  group('SubjectProvider error message', () {
    tearDown(() => ApiClient.clientOverride = null);

    test('offline failure shows a user-facing message', () async {
      ApiClient.clientOverride = _FailingClient(
        http.ClientException(
          "SocketException: Failed host lookup: 'qspot-app-vcbgp.ondigitalocean.app'",
        ),
      );
      final provider = SubjectProvider();

      await provider.initialize();

      expect(provider.hasError, isTrue);
      expect(provider.errorMessage, contains("Can't reach the server"));
      _expectNoTechnicalText(provider.errorMessage);
      expect(provider.errorMessage, isNot(contains('Failed to initialize')));
    });
  });
}
