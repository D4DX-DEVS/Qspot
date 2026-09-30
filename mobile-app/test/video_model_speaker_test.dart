import 'package:flutter_test/flutter_test.dart';
import 'package:qspot/screens/video/model/video_model.dart';

void main() {
  test('reads the faculty the API populated on an episode', () {
    final video = VideoModel.fromJson({
      '_id': 'v1',
      'title': 'Episode 30',
      'video': 'https://www.youtube.com/shorts/abc',
      'speaker': {'_id': 's1', 'name': 'Basheer Muhiyudheen'},
    });

    expect(video.speakerId, 's1');
    expect(video.speakerName, 'Basheer Muhiyudheen');
  });

  test('an episode with no faculty assigned stays empty', () {
    final video = VideoModel.fromJson({
      '_id': 'v2',
      'title': 'Episode 26',
      'video': 'https://www.youtube.com/shorts/def',
      'speaker': null,
    });

    expect(video.speakerId, isNull);
    expect(video.speakerName, isNull);
  });

  test('the faculty link survives a cache round-trip', () {
    final video = VideoModel.fromJson({
      '_id': 'v3',
      'title': 'Episode 07',
      'video': 'https://www.youtube.com/shorts/ghi',
      'speaker': {'_id': 's2', 'name': 'Suhaib CT'},
    });

    final restored = VideoModel.fromJson(video.toJson());

    expect(restored.speakerId, 's2');
    expect(restored.speakerName, 'Suhaib CT');
  });

  test('copyWith keeps the faculty link when progress changes', () {
    final video = VideoModel.fromJson({
      '_id': 'v4',
      'title': 'Episode 05',
      'video': 'https://www.youtube.com/shorts/jkl',
      'speaker': {'_id': 's3', 'name': 'Salman Azhari'},
    });

    final watched = video.copyWith(progress: 42);

    expect(watched.progress, 42);
    expect(watched.speakerId, 's3');
    expect(watched.speakerName, 'Salman Azhari');
  });
}
