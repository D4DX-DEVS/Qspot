import 'package:flutter/foundation.dart';
import '../model/user_model.dart';
import '../service/auth_service.dart';
import '../../../utils/user_friendly_error.dart';

enum AuthState { initial, authenticated, unauthenticated, loading }

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthState _authState = AuthState.initial;
  UserModel? _user;
  String? _errorMessage;
  bool _isLoading = false;

  AuthState get authState => _authState;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _authState == AuthState.authenticated;

  /// Initialize and check authentication status
  Future<void> initialize() async {
    try {
      _setLoading(true);
      final isLoggedIn = await _authService.isLoggedIn();

      if (isLoggedIn) {
        _user = await _authService.getSavedUser();
        _authState = AuthState.authenticated;
        debugPrint('✅ [AUTH PROVIDER] User is authenticated');
      } else {
        _authState = AuthState.unauthenticated;
        debugPrint('ℹ️ [AUTH PROVIDER] User is not authenticated');
      }
    } catch (e) {
      debugPrint('❌ [AUTH PROVIDER] Initialize error: $e');
      _authState = AuthState.unauthenticated;
    } finally {
      _setLoading(false);
    }
  }

  /// Request OTP for phone number
  Future<Map<String, dynamic>> requestOtp(String phone) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      final result = await _authService.requestOtp(phone);

      if (!result['success']) {
        _errorMessage = result['message'];
      }

      return result;
    } catch (e) {
      debugPrint('❌ [AUTH PROVIDER] Request OTP error: $e');
      _errorMessage = 'We couldn’t send the code. ${userFriendlyError(e)}';
      return {'success': false, 'message': _errorMessage};
    } finally {
      _setLoading(false);
    }
  }

  /// Verify OTP
  Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      final result = await _authService.verifyOtp(phone, otp);

      if (result['success']) {
        _user = result['user'];
        _authState = AuthState.authenticated;
        debugPrint('✅ [AUTH PROVIDER] User authenticated successfully');
      } else {
        _errorMessage = result['message'];
      }

      return result;
    } catch (e) {
      debugPrint('❌ [AUTH PROVIDER] Verify OTP error: $e');
      _errorMessage = 'We couldn’t verify that code. ${userFriendlyError(e)}';
      return {'success': false, 'message': _errorMessage};
    } finally {
      _setLoading(false);
    }
  }

  /// Register a new user.
  ///
  /// Registration never authenticates the app: the API returns no token
  /// for this call, so [_authState] is intentionally left untouched here.
  /// The caller (registration screen) is expected to move on to the OTP
  /// step for the same phone number on success.
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
      _setLoading(true);
      _errorMessage = null;

      final result = await _authService.register(
        phone: phone,
        name: name,
        classNumber: classNumber,
        email: email,
        dob: dob,
        consent: consent,
        courseIds: courseIds,
      );

      if (result['success']) {
        debugPrint('✅ [AUTH PROVIDER] User registered successfully');
      } else {
        _errorMessage = result['message'];
      }

      return result;
    } catch (e) {
      debugPrint('❌ [AUTH PROVIDER] Register error: $e');
      _errorMessage =
          'We couldn’t create your account. ${userFriendlyError(e)}';
      return {'success': false, 'message': _errorMessage};
    } finally {
      _setLoading(false);
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      _setLoading(true);
      await _authService.logout();
      _user = null;
      _authState = AuthState.unauthenticated;
      debugPrint('✅ [AUTH PROVIDER] User logged out');
    } catch (e) {
      debugPrint('❌ [AUTH PROVIDER] Logout error: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Applies a server-returned profile immediately and keeps it for the next
  /// app launch. Profile/course edits should not require a new login.
  Future<void> updateUser(UserModel user) async {
    _user = user;
    await _authService.saveUserData(user);
    notifyListeners();
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
