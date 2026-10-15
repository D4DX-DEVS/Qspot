import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:qspot/screens/assignment/screens/assignment_detail_screen.dart';
import 'package:qspot/screens/notification/model/notification_model.dart';
import 'package:qspot/screens/notification/model/notification_target.dart';
import 'package:qspot/screens/notification/provider/notification_provider.dart';
import 'package:qspot/screens/notification/service/notification_target_opener.dart';
import 'package:qspot/services/api_client.dart';
import 'package:qspot/services/common/storage_service.dart';
import 'package:qspot/services/push/noop_push_messaging.dart';
import 'package:qspot/services/push/push.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _item(
  String id, {
  bool read = false,
  Map<String, dynamic>? target,
}) => {
  '_id': id,
  'kind': 'assignment_marked',
  'title': 'Your teacher marked Recitation',
  'description': 'Score: 8/10.',
  'target': target ?? {'kind': 'none', 'id': ''},
  'read': read,
  'createdAt': '2026-10-15T12:00:00.000Z',
};

void main() {
  late List<String> requests;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
    requests = [];
  });

  tearDown(() => ApiClient.clientOverride = null);

  group('reading a notification', () {
    test('what a tap opens', () {
      final target = NotificationTarget.fromJson({
        'kind': 'lesson',
        'id': 'v1',
      });
      expect(target?.kind, 'lesson');
      expect(NotificationTarget.fromJson({'kind': 'none', 'id': ''}), isNull);
      expect(NotificationTarget.fromJson({'kind': 'lesson', 'id': ''}), isNull);
      expect(NotificationTarget.fromJson('bad'), isNull);
    });

    test('kind, link and read state come from the inbox', () {
      final n = NotificationModel.fromJson(
        _item('n1', read: true, target: {'kind': 'assignment', 'id': 'a1'}),
      );
      expect(n.kind, 'assignment_marked');
      expect(n.target?.id, 'a1');
      expect(n.isRead, isTrue);
      expect(n.copyWith(isRead: false).target?.id, 'a1');
    });
  });

  group('the inbox', () {
    test('uses the server read state and marks reads on the server', () async {
      ApiClient.clientOverride = MockClient((request) async {
        requests.add('${request.method} ${request.url.path}');
        if (request.url.path == '/api/user/notifications') {
          return http.Response(
            jsonEncode({
              'items': [_item('n1', read: true), _item('n2')],
              'unreadCount': 1,
            }),
            200,
          );
        }
        return http.Response('{}', 200);
      });
      final provider = NotificationProvider();
      await provider.loadNotifications();
      expect(provider.notifications, hasLength(2));
      expect(provider.unreadCount, 1);

      await provider.markAsRead('n2');
      expect(provider.unreadCount, 0);
      expect(requests, contains('POST /api/user/notifications/n2/read'));
    });

    test('falls back to the announcement list on an older server', () async {
      ApiClient.clientOverride = MockClient((request) async {
        if (request.url.path == '/api/user/notifications') {
          return http.Response('{"message":"Not found"}', 404);
        }
        if (request.url.path == '/api/notifications') {
          return http.Response(
            jsonEncode([
              {'_id': 'old', 'title': 'Welcome', 'description': 'Hello'},
            ]),
            200,
          );
        }
        return http.Response('{}', 200);
      });
      final provider = NotificationProvider();
      await provider.loadNotifications();
      expect(provider.notifications.single.title, 'Welcome');
      expect(provider.unreadCount, 1);
    });
  });

  testWidgets('an assignment notification opens the assignment', (
    tester,
  ) async {
    ApiClient.clientOverride = MockClient((request) async {
      if (request.url.path.endsWith('/api/user/assignments/a1')) {
        return http.Response(
          jsonEncode({'_id': 'a1', 'title': 'Recitation', 'status': 'graded'}),
          200,
        );
      }
      return http.Response('{}', 200);
    });
    late BuildContext captured;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            captured = context;
            return const SizedBox();
          },
        ),
      ),
    );
    final opened = NotificationTargetOpener.open(
      captured,
      const NotificationTarget(kind: 'assignment', id: 'a1'),
      title: 'Recitation',
    );
    await tester.pumpAndSettle();
    expect(find.byType(AssignmentDetailScreen), findsOneWidget);
    Navigator.of(tester.element(find.byType(AssignmentDetailScreen))).pop();
    await tester.pumpAndSettle();
    expect(await opened, isTrue);
  });

  test('with no push service nothing is registered', () async {
    ApiClient.clientOverride = MockClient((request) async {
      requests.add(request.url.path);
      return http.Response('{}', 200);
    });
    expect(Push.configured, 'none');
    expect(Push.messaging, isA<NoopPushMessaging>());
    await Push.register();
    await Push.unregister();
    expect(requests, isEmpty);
  });
}
