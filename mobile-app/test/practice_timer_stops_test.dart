import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:qspot/screens/video/screens/video_questions_screen.dart';
import 'package:qspot/services/api_client.dart';
import 'package:qspot/services/common/storage_service.dart';
import 'package:qspot/services/video_progress_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
  });
  tearDown(() => ApiClient.clientOverride = null);

  testWidgets('submitting early stops the practice countdown', (tester) async {
    var submits = 0;
    ApiClient.clientOverride = MockClient((request) async {
      if (request.url.path.endsWith('/api/user/video-quiz')) submits++;
      return http.Response(
        '{"attempt":{"score":1,"total":1,"percentage":100}}',
        201,
      );
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: VideoQuestionsScreen(
          videoId: 'v1',
          videoTitle: 'Episode 30',
          questions: [
            VideoQuestionItem(
              id: 'q1',
              questionEn: 'What is 1 + 1?',
              questionMl: 'What is 1 + 1?',
              optionsEn: ['1', '2', '3'],
              optionsMl: ['1', '2', '3'],
            ),
          ],
          settings: VideoPracticeSettings(
            timerMode: 'overall',
            overallTimeLimit: 5,
          ),
        ),
      ),
    );

    await tester.tap(find.text('2'));
    await tester.pump();
    await tester.tap(find.text('Submit'));
    await tester.pump();
    expect(submits, 1);

    // Well past the 5-second limit: the countdown must not send again.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(submits, 1);
  });
}
