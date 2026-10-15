import 'package:flutter/foundation.dart';

import 'noop_telemetry_reporter.dart';
import 'telemetry_reporter.dart';

/// Crash reports and usage events for the whole app.
///
/// The service is chosen at build time with `--dart-define=TELEMETRY=<name>`.
/// Only `none` exists today (nothing is sent). To connect a service, add a
/// [TelemetryReporter] for it and a case in [reporterFor].
class Telemetry {
  Telemetry._();

  static const String configured = String.fromEnvironment(
    'TELEMETRY',
    defaultValue: 'none',
  );

  static TelemetryReporter reporter = reporterFor(configured);

  static TelemetryReporter reporterFor(String name) {
    switch (name.trim().toLowerCase()) {
      default:
        return const NoopTelemetryReporter();
    }
  }

  /// Starts the reporter and routes every uncaught error to it. Flutter's own
  /// handling (the red error screen in debug, console output) is kept.
  static Future<void> install() async {
    await reporter.start();
    final previousFlutterHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      reporter.recordError(
        details.exception,
        details.stack,
        fatal: true,
        reason: details.context?.toString(),
      );
      (previousFlutterHandler ?? FlutterError.presentError)(details);
    };
    final previousPlatformHandler = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stack) {
      reporter.recordError(error, stack, fatal: true);
      return previousPlatformHandler?.call(error, stack) ?? false;
    };
  }

  static void event(String name, [Map<String, Object?> params = const {}]) =>
      reporter.logEvent(name, params);

  static void setUser(String? userId) => reporter.setUser(userId);
}
