import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:qspot/utils/api_urls.dart';
import 'package:qspot/screens/auth/screens/login_screen.dart';
import 'package:qspot/services/common/storage_service.dart';

/// Global navigator key used to route to LoginScreen from anywhere (e.g. when
/// ApiClient detects an expired/invalid session) without a BuildContext.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Typed exception for API errors. [message] is always human readable text
/// suitable for direct display (it is read from the server's `{message}`
/// envelope wherever the server follows the contract).
class ApiException implements Exception {
  final int status;
  final String message;

  /// The decoded JSON response body, when the server returned one (e.g. a
  /// `409` body like `{message, attempt}`). Callers that need structured
  /// data beyond [message] (rather than just displaying the message) can
  /// read it here instead of re-parsing `response.body` themselves.
  final dynamic body;

  ApiException(this.status, String message, [this.body])
    : message = _normaliseMessage(status, message);

  static String _normaliseMessage(int status, String message) {
    final trimmed = message.trim();
    // Server diagnostics are useful in logs, but they are confusing and may
    // disclose infrastructure details when rendered in the app.
    final technical =
        trimmed.isEmpty ||
        trimmed.toLowerCase().contains('internal server error') ||
        trimmed.toLowerCase().contains('bad gateway') ||
        trimmed.toLowerCase().contains('service unavailable') ||
        trimmed.toLowerCase().contains('socketexception') ||
        trimmed.toLowerCase().contains('clientexception') ||
        trimmed.toLowerCase().contains('failed host lookup') ||
        trimmed.toLowerCase().contains('errno') ||
        trimmed.toLowerCase().contains('uri=') ||
        trimmed.toLowerCase().contains('exception:');

    if (status == 401 ||
        (status == 403 && trimmed == ApiClient._expiredTokenMessage)) {
      return 'Your session has expired. Please sign in again.';
    }
    // Other 403s are business rules ("Quiz is not live right now") whose
    // message is the useful part.
    if (status == 403 && technical) {
      return "You don't have permission to do that.";
    }
    if (status == 404 && technical) {
      return "We couldn't find what you requested.";
    }
    if (status >= 500 || technical) {
      return 'Something went wrong on our side. Please try again in a moment.';
    }
    return trimmed.isEmpty
        ? 'Something went wrong. Please try again.'
        : trimmed;
  }

  @override
  String toString() => 'ApiException($status): $message';
}

/// Single HTTP wrapper used by every provider/service in the app.
///
/// - Adds `Authorization: Bearer <token>` automatically when a session
///   token is stored.
/// - Applies a 15 second timeout to every request.
/// - Parses error bodies as `{message}` and throws [ApiException].
/// - On 401, or a 403 carrying [_expiredTokenMessage], for an authenticated
///   call, clears the local session and routes to [LoginScreen] using
///   [navigatorKey].
class ApiClient {
  ApiClient._();

  /// What the server's auth middleware (Qspot-API/middlewares/auth.js) sends
  /// with a 403 for a bad or expired token. Every other 403 is a business
  /// rule (quiz not live, not ready, ...) and must not sign the user out.
  static const String _expiredTokenMessage = 'Invalid or expired token';

  static const Duration timeout = Duration(seconds: 15);
  static const String _tokenKey = 'auth_token';
  static final http.Client _defaultClient = http.Client();
  static Future<void>? _sessionExpiryInFlight;

  /// Replaced by deterministic clients in tests. Production always uses
  /// [_defaultClient].
  static http.Client? clientOverride;

  static http.Client get _client => clientOverride ?? _defaultClient;

  static Future<String?> _token() =>
      StorageService.getString(_tokenKey).then((v) => v.isEmpty ? null : v);

  static Future<Map<String, String>> _headers({bool json = true}) async {
    final headers = <String, String>{};
    if (json) headers['Content-Type'] = 'application/json';
    final token = await _token();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Uri _uri(String path, [Map<String, dynamic>? query]) {
    final url = path.startsWith('http') ? path : '${ApiUrls.baseUrl}$path';
    var uri = Uri.parse(url);
    if (query != null && query.isNotEmpty) {
      final stringQuery = <String, String>{};
      query.forEach((key, value) {
        if (value != null) stringQuery[key] = value.toString();
      });
      uri = uri.replace(
        queryParameters: {...uri.queryParameters, ...stringQuery},
      );
    }
    return uri;
  }

  /// Handles the raw [http.Response]: decodes JSON, throws [ApiException]
  /// on non-2xx, and triggers session-expiry handling on auth failures.
  static Future<dynamic> _handle(http.Response response) async {
    final status = response.statusCode;
    dynamic body;
    try {
      body = response.body.isEmpty ? null : json.decode(response.body);
    } catch (_) {
      body = null;
    }

    if (status >= 200 && status < 300) {
      return body;
    }

    final message = (body is Map && body['message'] is String)
        ? body['message'] as String
        : 'Something went wrong. Please try again.';

    if (status == 401 || (status == 403 && message == _expiredTokenMessage)) {
      // Only force logout/navigation for calls that were actually
      // authenticated (i.e. a token was present). Public endpoints that
      // happen to return 403 for other reasons should not log the user out.
      final hadToken = await _token() != null;
      if (hadToken) {
        await _handleSessionExpired();
      }
    }

    throw ApiException(status, message, body);
  }

  static Future<void> _handleSessionExpired() async {
    final existing = _sessionExpiryInFlight;
    if (existing != null) return existing;
    final work = () async {
      await StorageService.remove(_tokenKey);
      await StorageService.remove('user_data');
      final nav = navigatorKey.currentState;
      if (nav != null && nav.mounted) {
        nav.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }();
    _sessionExpiryInFlight = work;
    try {
      await work;
    } finally {
      _sessionExpiryInFlight = null;
    }
  }

  static Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    final response = await _client
        .get(_uri(path, query), headers: await _headers(json: false))
        .timeout(timeout);
    return _handle(response);
  }

  static Future<dynamic> post(String path, {Object? body}) async {
    final response = await _client
        .post(
          _uri(path),
          headers: await _headers(),
          body: body == null ? null : json.encode(body),
        )
        .timeout(timeout);
    return _handle(response);
  }

  static Future<dynamic> put(String path, {Object? body}) async {
    final response = await _client
        .put(
          _uri(path),
          headers: await _headers(),
          body: body == null ? null : json.encode(body),
        )
        .timeout(timeout);
    return _handle(response);
  }

  static Future<dynamic> delete(String path, {Object? body}) async {
    final response = await _client
        .delete(
          _uri(path),
          headers: await _headers(),
          body: body == null ? null : json.encode(body),
        )
        .timeout(timeout);
    return _handle(response);
  }

  /// Multipart upload helper (used for admin-style uploads if ever needed
  /// from the app; kept generic).
  static Future<dynamic> multipart(
    String path, {
    required String method,
    Map<String, String>? fields,
    List<http.MultipartFile> files = const [],
  }) async {
    final request = http.MultipartRequest(method, _uri(path));
    final headers = await _headers(json: false);
    request.headers.addAll(headers);
    if (fields != null) request.fields.addAll(fields);
    request.files.addAll(files);
    final streamed = await _client.send(request).timeout(timeout);
    final response = await http.Response.fromStream(streamed);
    return _handle(response);
  }
}
