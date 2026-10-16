import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:qspot/screens/video/provider/video_provider.dart';
import 'package:qspot/services/api_client.dart';
import 'package:qspot/services/common/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
  });
  tearDown(() => ApiClient.clientOverride = null);

  test('a failed progress refresh keeps the progress already shown', () async {
    var serverDown = false;
    ApiClient.clientOverride = MockClient((request) async {
      if (serverDown) return http.Response('{"message":"busy"}', 503);
      return http.Response(
        '[{"videoId":"v1","positionSeconds":300,"completed":true}]',
        200,
      );
    });
    final videos = VideoProvider();

    await videos.loadProgress();
    expect(videos.progressFor('v1')?.completed, isTrue);

    serverDown = true;
    await videos.loadProgress();
    expect(videos.progressFor('v1')?.completed, isTrue);
    expect(videos.progressFor('v1')?.positionSeconds, 300);
  });
}
