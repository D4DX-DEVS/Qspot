import 'push_messaging.dart';

/// No push service: no token, never a tap. The default until a service is
/// chosen; learners still see every notification in the app's list.
class NoopPushMessaging implements PushMessaging {
  const NoopPushMessaging();

  @override
  Future<String?> token() async => null;

  @override
  String get platform => 'other';

  @override
  void listen(PushOpenHandler onOpen) {}
}
