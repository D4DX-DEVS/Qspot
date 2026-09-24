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

  ApiException(this.status, this.message, [this.body]);

  @override
  String toString() => 'ApiException($status): $message';
}

/// Single HTTP wrapper used by every provider/service in the app.
///
/// - Adds `Authorization: Bearer <token>` automatically when a session
///   token is stored.
/// - Applies a 15 second timeout to every request.
/// - Parses error bodies as `{message}` and throws [ApiException].
/// - On 401/403 for an authenticated call, clears the local session and
///   routes to [LoginScreen] using [navigatorKey].
class ApiClient {
  ApiClient._();

  static const Duration timeout = Duration(seconds: 15);
  static const String _tokenKey = 'auth_token';
  static final http.Client _defaultClient = http.Client();

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
  /// on non-2xx, and triggers session-expiry handling on 401/403.
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
        : 'Something went wrong ($status)';

    if (status == 401 || status == 403) {
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
    await StorageService.remove(_tokenKey);
    await StorageService.remove('user_data');
    final nav = navigatorKey.currentState;
    if (nav != null) {
      nav.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
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
