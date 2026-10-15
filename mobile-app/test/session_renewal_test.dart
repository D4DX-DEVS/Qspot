import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:qspot/services/api_client.dart';
import 'package:qspot/services/common/storage_service.dart';
import 'package:qspot/services/session_renewal_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _now = DateTime.utc(2026, 10, 14, 10);

/// A sign-in shaped like the server's (header.payload.signature) expiring at
/// [expiry].
String _token(DateTime expiry) {
  String part(Map<String, dynamic> json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  return '${part({'alg': 'HS256'})}.'
      '${part({'userId': 'u1', 'role': 'student', 'exp': expiry.millisecondsSinceEpoch ~/ 1000})}'
      '.signature';
}

/// The sign-in is renewed only when it has less than a day left.
void main() {
  late int renewals;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    renewals = 0;
    ApiClient.clientOverride = MockClient((request) async {
      if (request.url.path == '/api/user/refresh-token') {
        renewals++;
        return http.Response(jsonEncode({'token': 'fresh-token'}), 200);
      }
      return http.Response('{}', 404);
    });
  });
  tearDown(() => ApiClient.clientOverride = null);

  Future<String> renewAt(DateTime expiry) async {
    await StorageService.setString('auth_token', _token(expiry));
    await withClock(Clock.fixed(_now), SessionRenewalService.renewIfNeeded);
    return StorageService.getString('auth_token');
  }

  test('the expiry is read from the sign-in on the phone', () {
    expect(
      SessionRenewalService.expiryOf(_token(_now)),
      DateTime.utc(2026, 10, 14, 10),
    );
    expect(SessionRenewalService.expiryOf('not-a-token'), isNull);
    expect(SessionRenewalService.expiryOf('a.%%%.c'), isNull);
  });

  test('less than a day left: renewed and the new sign-in is kept', () async {
    final stored = await renewAt(_now.add(const Duration(hours: 20)));
    expect(renewals, 1);
    expect(stored, 'fresh-token');
  });

  test('more than a day left: the server is not asked', () async {
    final token = _token(_now.add(const Duration(days: 3)));
    await StorageService.setString('auth_token', token);
    await withClock(Clock.fixed(_now), SessionRenewalService.renewIfNeeded);
    expect(renewals, 0);
    expect(await StorageService.getString('auth_token'), token);
  });

  test('already run out: not renewed, the student signs in again', () async {
    await renewAt(_now.subtract(const Duration(minutes: 1)));
    expect(renewals, 0);
  });

  test('signed out: nothing to renew', () async {
    await withClock(Clock.fixed(_now), SessionRenewalService.renewIfNeeded);
    expect(renewals, 0);
  });

  test('asked from several places at once, the server is asked once', () async {
    await StorageService.setString(
      'auth_token',
      _token(_now.add(const Duration(hours: 2))),
    );
    await withClock(
      Clock.fixed(_now),
      () => Future.wait([
        SessionRenewalService.renewIfNeeded(),
        SessionRenewalService.renewIfNeeded(),
      ]),
    );
    expect(renewals, 1);
  });

  test('a failed renewal is quiet and keeps the old sign-in', () async {
    ApiClient.clientOverride = MockClient((_) async => http.Response('', 500));
    final token = _token(_now.add(const Duration(hours: 5)));
    await StorageService.setString('auth_token', token);
    await withClock(Clock.fixed(_now), SessionRenewalService.renewIfNeeded);
    expect(await StorageService.getString('auth_token'), token);
  });
}
