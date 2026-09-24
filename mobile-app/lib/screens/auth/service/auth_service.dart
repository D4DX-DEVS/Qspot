import 'dart:convert';

import 'package:flutter/foundation.dart';
import '../model/user_model.dart';
import '../../../services/api_client.dart';
import '../../../services/common/storage_service.dart';

/// Auth API calls, backed by [ApiClient].
///
/// Endpoint contract:
///  - POST /api/user/register            {name, phone, class, email?, dob?, consent?}
///        -> 201 {message, user}  (no token: registration does not log in)
///  - POST /api/user/login/request-otp    {phone} -> {message, phone, cooldown}
///  - POST /api/user/login/verify         {phone, code} -> {message, token, user}
class AuthService {
  static const String _userKey = 'user_data';
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'userId';

  /// Request OTP for phone number.
  Future<Map<String, dynamic>> requestOtp(String phone) async {
    try {
      final data = await ApiClient.post(
        '/api/user/login/request-otp',
        body: {'phone': phone},
      );
      return {
        'success': true,
        'message':
            (data is Map ? data['message'] : null) ?? 'OTP sent successfully',
        'cooldown': data is Map ? data['cooldown'] : null,
      };
    } on ApiException catch (e) {
      return {'success': false, 'message': e.message, 'status': e.status};
    } catch (e) {
      debugPrint('AuthService.requestOtp failed: $e');
      return {'success': false, 'message': 'Network error. Please try again.'};
    }
  }

  /// Verify OTP and, on success, persist the session (token + user + userId).
  Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    try {
      final data = await ApiClient.post(
        '/api/user/login/verify',
        body: {'phone': phone, 'code': otp},
      );

      final map = data is Map ? data : <String, dynamic>{};
      final userData = map['user'] is Map
          ? Map<String, dynamic>.from(map['user'] as Map)
          : <String, dynamic>{};
      if (map['token'] != null) {
        userData['token'] = map['token'];
      }

      final user = UserModel.fromJson(userData);
      await saveUserData(user);

      return {
        'success': true,
        'user': user,
        'message': map['message'] ?? 'Login successful',
      };
    } on ApiException catch (e) {
      return {'success': false, 'message': e.message, 'status': e.status};
    } catch (e) {
      debugPrint('AuthService.verifyOtp failed: $e');
      return {'success': false, 'message': 'Network error. Please try again.'};
    }
  }

  /// Register a new user. The API does not return a token for this call,
  /// so the caller must not be marked authenticated afterwards - the UI
  /// should move on to the OTP step instead.
  Future<Map<String, dynamic>> register({
    required String phone,
    required String name,
    required String classNumber,
    String? email,
    String? dob,
    Map<String, dynamic>? consent,
    List<String> courseIds = const [],
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name,
        'phone': phone,
        'class': classNumber,
        if (email != null && email.isNotEmpty) 'email': email,
        if (dob != null && dob.isNotEmpty) 'dob': dob,
        if (consent != null) 'consent': consent,
        if (courseIds.isNotEmpty) 'courseIds': courseIds,
      };

      final data = await ApiClient.post('/api/user/register', body: body);
      final map = data is Map ? data : <String, dynamic>{};
      final userData = map['user'] is Map
          ? Map<String, dynamic>.from(map['user'] as Map)
          : <String, dynamic>{};

      final user = userData.isNotEmpty ? UserModel.fromJson(userData) : null;

      return {
        'success': true,
        'user': user,
        'message': map['message'] ?? 'Registration successful',
      };
    } on ApiException catch (e) {
      return {'success': false, 'message': e.message, 'status': e.status};
    } catch (e) {
      debugPrint('AuthService.register failed: $e');
      return {'success': false, 'message': 'Network error. Please try again.'};
    }
  }

  /// Save user data + token + userId to local storage.
  Future<void> saveUserData(UserModel user) async {
    try {
      await StorageService.setString(_userKey, json.encode(user.toJson()));
      if (user.token != null) {
        await StorageService.setString(_tokenKey, user.token!);
      }
      if (user.id != null) {
        await StorageService.setString(_userIdKey, user.id!);
      }
    } catch (e) {
      debugPrint('AuthService.saveUserData failed: $e');
    }
  }

  /// Get saved user data.
  Future<UserModel?> getSavedUser() async {
    try {
      final userJson = await StorageService.getString(_userKey);
      if (userJson.isEmpty) return null;
      final userData = json.decode(userJson);
      if (userData is! Map<String, dynamic>) return null;
      return UserModel.fromJson(userData);
    } catch (e) {
      debugPrint('AuthService.getSavedUser failed: $e');
      return null;
    }
  }

  /// Get saved token.
  Future<String?> getSavedToken() async {
    try {
      final token = await StorageService.getString(_tokenKey);
      return token.isEmpty ? null : token;
    } catch (e) {
      debugPrint('AuthService.getSavedToken failed: $e');
      return null;
    }
  }

  /// True only when a non-empty session token is stored.
  Future<bool> isLoggedIn() async {
    final token = await getSavedToken();
    return token != null && token.isNotEmpty;
  }

  /// Logout: clears auth-related local storage only. Any cross-provider
  /// cleanup (quiz progress, etc.) is orchestrated elsewhere.
  Future<void> logout() async {
    try {
      await StorageService.remove(_userKey);
      await StorageService.remove(_tokenKey);
      await StorageService.remove(_userIdKey);
    } catch (e) {
      debugPrint('AuthService.logout failed: $e');
    }
  }
}
