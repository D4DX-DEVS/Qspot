import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:qspot/services/api_client.dart';
import 'package:qspot/services/common/storage_service.dart';

/// Only a real auth failure may sign the user out. A 403 that is a business
/// rule (quiz not live / not ready) must surface its message and keep the
/// session.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.setString('auth_token', 'tok-123');
  });
  tearDown(() => ApiClient.clientOverride = null);

  void respond(int status, String message) {
    ApiClient.clientOverride = MockClient(
      (_) async => http.Response(jsonEncode({'message': message}), status),
    );
  }

  Future<ApiException> failure() async {
    try {
      await ApiClient.get('/api/user-quizzes/x/questions');
    } on ApiException catch (e) {
      return e;
    }
    fail('expected an ApiException');
  }

  Future<String> token() => StorageService.getString('auth_token');

  test('business 403 keeps the session and shows the server message', () async {
    respond(403, "This quiz isn't ready yet. Please check back later.");
    final e = await failure();
    expect(e.status, 403);
    expect(e.message, "This quiz isn't ready yet. Please check back later.");
    expect(await token(), 'tok-123');
  });

  test('quiz-not-live 403 keeps the session', () async {
    respond(403, 'Quiz is not live right now');
    final e = await failure();
    expect(e.message, 'Quiz is not live right now');
    expect(await token(), 'tok-123');
  });

  test('expired-token 403 signs the user out', () async {
    respond(403, 'Invalid or expired token');
    final e = await failure();
    expect(e.message, 'Your session has expired. Please sign in again.');
    expect(await token(), isEmpty);
  });

  test('401 signs the user out', () async {
    respond(401, 'User not found');
    await failure();
    expect(await token(), isEmpty);
  });
}
