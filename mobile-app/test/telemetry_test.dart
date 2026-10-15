import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qspot/services/telemetry/noop_telemetry_reporter.dart';
import 'package:qspot/services/telemetry/telemetry.dart';
import 'package:qspot/services/telemetry/telemetry_reporter.dart';

class _FakeReporter implements TelemetryReporter {
  final errors = <Object>[];
  final events = <String>[];
  String? user = 'unset';

  @override
  Future<void> start() async {}

  @override
  void recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
    String? reason,
  }) => errors.add(error);

  @override
  void logEvent(String name, [Map<String, Object?> params = const {}]) =>
      events.add(name);

  @override
  void setUser(String? userId) => user = userId;
}

void main() {
  test('nothing is sent unless a service is chosen', () {
    expect(Telemetry.configured, 'none');
    expect(Telemetry.reporterFor('none'), isA<NoopTelemetryReporter>());
    expect(Telemetry.reporterFor('unknown'), isA<NoopTelemetryReporter>());
  });

  test(
    'uncaught Flutter errors reach the reporter and Flutter still sees them',
    () async {
      final fake = _FakeReporter();
      final original = Telemetry.reporter;
      final originalOnError = FlutterError.onError;
      final seenByFlutter = <FlutterErrorDetails>[];
      FlutterError.onError = seenByFlutter.add;
      Telemetry.reporter = fake;
      try {
        await Telemetry.install();
        FlutterError.reportError(
          FlutterErrorDetails(exception: StateError('boom')),
        );
        expect(fake.errors.single, isA<StateError>());
        expect(seenByFlutter, hasLength(1));
      } finally {
        Telemetry.reporter = original;
        FlutterError.onError = originalOnError;
      }
    },
  );

  test('events and the signed-in account go to the reporter', () {
    final fake = _FakeReporter();
    final original = Telemetry.reporter;
    Telemetry.reporter = fake;
    try {
      Telemetry.event('exam_submitted', {'quiz_id': 'q1'});
      Telemetry.setUser('u1');
      expect(fake.events, ['exam_submitted']);
      expect(fake.user, 'u1');
      Telemetry.setUser(null);
      expect(fake.user, isNull);
    } finally {
      Telemetry.reporter = original;
    }
  });
}
