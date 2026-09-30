import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:qspot/screens/auth/model/user_model.dart';
import 'package:qspot/screens/auth/service/auth_service.dart';

/// These tests exercise the local-storage side of [AuthService] (session
/// persistence, `isLoggedIn`, logout) using the in-memory SharedPreferences
/// mock. They intentionally do not cover `requestOtp`/`verifyOtp`/`register`
/// themselves, because those go through the shared `ApiClient`, which talks
/// to `package:http`'s top-level functions directly rather than an
/// injectable `http.Client` - there is currently no seam to swap in a fake
/// HTTP layer without changing `ApiClient` (owned by another task).
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AuthService session persistence', () {
    test('isLoggedIn is false with no stored session', () async {
      final service = AuthService();
      expect(await service.isLoggedIn(), isFalse);
    });

    test(
      'isLoggedIn is false when only user_data is stored (no token)',
      () async {
        final service = AuthService();
        final user = UserModel.fromJson({
          'id': 'abc123',
          'phone': '9876543210',
          'name': 'Ayesha',
        });

        // Simulate a user record saved without ever completing OTP verify
        // (e.g. leftover from an older build) - no token means not logged in.
        await service.saveUserData(user);

        expect(await service.isLoggedIn(), isFalse);
      },
    );

    test('isLoggedIn is true once a session with a token is saved', () async {
      final service = AuthService();
      final user = UserModel.fromJson({
        'id': 'abc123',
        'phone': '9876543210',
        'name': 'Ayesha',
        'token': 'tok-123',
      });

      await service.saveUserData(user);

      expect(await service.isLoggedIn(), isTrue);
      expect(await service.getSavedToken(), 'tok-123');
    });

    test('saveUserData writes the "userId" key used by quiz storage', () async {
      final service = AuthService();
      final user = UserModel.fromJson({
        'id': 'abc123',
        'phone': '9876543210',
        'token': 'tok-123',
      });

      await service.saveUserData(user);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('userId'), 'abc123');
    });

    test(
      'getSavedUser round-trips the saved user, including id from _id',
      () async {
        final service = AuthService();
        final user = UserModel.fromJson({
          '_id': 'mongo-id-1',
          'phone': '9876543210',
          'name': 'Ayesha',
          'token': 'tok-123',
        });

        await service.saveUserData(user);
        final saved = await service.getSavedUser();

        expect(saved, isNotNull);
        expect(saved!.id, 'mongo-id-1');
        expect(saved.phone, '9876543210');
      },
    );

    test('logout clears token, user data and userId', () async {
      final service = AuthService();
      final user = UserModel.fromJson({
        'id': 'abc123',
        'phone': '9876543210',
        'token': 'tok-123',
      });
      await service.saveUserData(user);

      await service.logout();

      expect(await service.isLoggedIn(), isFalse);
      expect(await service.getSavedUser(), isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('userId'), isNull);
    });
  });
}
