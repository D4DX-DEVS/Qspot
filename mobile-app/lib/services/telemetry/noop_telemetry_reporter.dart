import 'package:flutter/foundation.dart';

import 'telemetry_reporter.dart';

/// Sends nothing anywhere. The default until a crash-reporting service is
/// chosen; in debug builds it prints what would have been sent.
class NoopTelemetryReporter implements TelemetryReporter {
  const NoopTelemetryReporter();

  @override
  Future<void> start() async {}

  @override
  void recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
    String? reason,
  }) {
    if (kDebugMode) {
      debugPrint('[telemetry] ${fatal ? 'fatal' : 'error'}: $error');
    }
  }

  @override
  void logEvent(String name, [Map<String, Object?> params = const {}]) {
    if (kDebugMode) debugPrint('[telemetry] event $name $params');
  }

  @override
  void setUser(String? userId) {}
}
