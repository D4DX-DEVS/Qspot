/// Where the app sends crash reports and usage events. One implementation per
/// service; [Telemetry] picks one at build time.
abstract class TelemetryReporter {
  Future<void> start();

  /// An error the app did not handle. [fatal] when it reached the top level.
  void recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
    String? reason,
  });

  /// A named usage event, such as `exam_submitted`.
  void logEvent(String name, [Map<String, Object?> params = const {}]);

  /// The signed-in learner's account id (never phone, name or birth date),
  /// or null after logout.
  void setUser(String? userId);
}
