import '../../screens/notification/model/notification_target.dart';

/// Called when the learner taps a push that points to a screen.
typedef PushOpenHandler =
    void Function(NotificationTarget target, String title);

/// A push service on the phone (for example Firebase Cloud Messaging). One
/// implementation per service; [Push] picks one.
abstract class PushMessaging {
  /// This phone's address for pushes, or null when pushes are off.
  Future<String?> token();

  /// `android`, `ios`, `web` or `other`.
  String get platform;

  /// Starts listening for taps on pushes.
  void listen(PushOpenHandler onOpen);
}
