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
    return error.status >= 500
        ? 'Something went wrong on our side. Please try again in a moment.'
        : error.message;
  }
  return 'Something went wrong. Please try again.';
}
