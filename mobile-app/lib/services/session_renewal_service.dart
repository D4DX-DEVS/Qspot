import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'common/storage_service.dart';

/// Keeps a student signed in. A sign-in lasts 30 days; when less than
/// [threshold] is left it is swapped for a fresh one, so it can never run out
/// in the middle of a quiz. The expiry is read from the sign-in on the phone,
/// so the server is only asked when a renewal is actually due.
class SessionRenewalService {
  SessionRenewalService._();

  static const Duration threshold = Duration(days: 1);
  static const String _tokenKey = 'auth_token';
  static Future<void>? _inFlight;

  /// When the sign-in [token] (a JWT) expires, read from its payload; null
  /// when it cannot be read.
  static DateTime? expiryOf(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    try {
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      final exp = payload is Map ? payload['exp'] : null;
      return exp is num
          ? DateTime.fromMillisecondsSinceEpoch(
              (exp * 1000).round(),
              isUtc: true,
            )
          : null;
    } catch (_) {
      return null;
    }
  }

  /// Less than [threshold] left, but not run out yet: one that has run out
  /// cannot be renewed, the student signs in again.
  static bool needsRenewal(DateTime expiry, DateTime now) {
    final left = expiry.difference(now);
    return left > Duration.zero && left < threshold;
  }

  /// Renews the sign-in when it is close to running out. One request at a
  /// time; never throws.
  static Future<void> renewIfNeeded() =>
      _inFlight ??= _renew().whenComplete(() => _inFlight = null);

  static Future<void> _renew() async {
    try {
      final token = await StorageService.getString(_tokenKey);
      final expiry = token.isEmpty ? null : expiryOf(token);
      if (expiry == null || !needsRenewal(expiry, clock.now())) return;
      final data = await ApiClient.post('/api/user/refresh-token');
      final fresh = data is Map ? data['token'] : null;
      if (fresh is String && fresh.isNotEmpty) {
        await StorageService.setString(_tokenKey, fresh);
      }
    } catch (e) {
      debugPrint('Sign-in not renewed: $e');
    }
  }
}
