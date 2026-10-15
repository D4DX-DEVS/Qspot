import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../services/api_client.dart';

/// Turns a thrown error into text that is safe to show a user. Raw exception
/// text (host names, URLs, errno codes) never leaves this function - log the
/// original error with `debugPrint` instead.
String userFriendlyError(Object error) {
  if (error is TimeoutException) {
    return 'This is taking longer than usual. '
        'Please check your connection and try again.';
  }
  // The http package wraps a SocketException in a ClientException, so both
  // mean the same thing here: the request never reached the server.
  if (error is SocketException || error is http.ClientException) {
    return "Can't reach the server. "
        'Please check your internet connection and try again.';
  }
  if (error is ApiException) {
    if (error.status == 401) {
      return 'Your session has expired. Please sign in again.';
    }
    if (error.status == 403) {
      return "You don't have permission to do that.";
    }
    if (error.status == 404) {
      return _readableApiMessage(error.message)
          ? error.message
          : "We couldn't find what you requested.";
    }
    if (error.status >= 500) {
      return 'Something went wrong on our side. Please try again in a moment.';
    }
    return _readableApiMessage(error.message)
        ? error.message
        : 'Please check the details and try again.';
  }
  return 'Something went wrong. Please try again.';
}

bool _readableApiMessage(String message) {
  final lower = message.toLowerCase();
  return message.trim().isNotEmpty &&
      !lower.contains('exception') &&
      !lower.contains('socket') &&
      !lower.contains('errno') &&
      !lower.contains('uri=') &&
      !lower.contains('failed host lookup') &&
      !lower.contains('internal server error') &&
      !lower.contains('bad gateway');
}
