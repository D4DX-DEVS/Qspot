import '../api_client.dart';
import 'noop_push_messaging.dart';
import 'push_messaging.dart';

/// Push notifications for the signed-in learner. The service is chosen at
/// build time with `--dart-define=PUSH=<name>`; only `none` exists today.
class Push {
  Push._();

  static const String configured = String.fromEnvironment(
    'PUSH',
    defaultValue: 'none',
  );

  static PushMessaging messaging = messagingFor(configured);

  static PushMessaging messagingFor(String name) {
    switch (name.trim().toLowerCase()) {
      default:
        return const NoopPushMessaging();
    }
  }

  static void listen(PushOpenHandler onOpen) => messaging.listen(onOpen);

  /// Tells the server this phone can receive the learner's pushes.
  static Future<void> register() async {
    try {
      final token = await messaging.token();
      if (token == null || token.isEmpty) return;
      await ApiClient.put(
        '/api/user/notifications/push-token',
        body: {'token': token, 'platform': messaging.platform},
      );
    } catch (_) {
      // Tried again at the next sign-in or app start.
    }
  }

  /// Stops pushes to this phone; called before logging out.
  static Future<void> unregister() async {
    try {
      final token = await messaging.token();
      if (token == null || token.isEmpty) return;
      await ApiClient.delete(
        '/api/user/notifications/push-token',
        body: {'token': token},
      );
    } catch (_) {}
  }
}
