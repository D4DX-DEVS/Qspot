import 'package:flutter_test/flutter_test.dart';
import 'package:qspot/screens/home/model/lesson_counts.dart';
import 'package:qspot/screens/video/model/video_model.dart';
import 'package:qspot/services/video_progress_service.dart';

VideoModel _video(String id, {bool upcoming = false}) =>
    VideoModel(id: id, caption: 'Lesson $id', video: 'x', isUpcoming: upcoming);

VideoProgressStatus _done(String id) =>
    VideoProgressStatus(videoId: id, completed: true);

void main() {
  test('counts finished lessons out of every lesson that can be opened', () {
    final videos = [for (var i = 0; i < 40; i++) _video('v$i')];

    final counts = LessonCounts.from(videos, {'v0': _done('v0')});

    expect(counts.completed, 1);
    expect(counts.total, 40);
    expect(counts.label, '1/40');
  });

  test('lessons that open later are not counted', () {
    final videos = [_video('a'), _video('b'), _video('later', upcoming: true)];

    final counts = LessonCounts.from(videos, {'a': _done('a')});

    expect(counts.label, '1/2');
  });

  test('progress on lessons outside the list is ignored', () {
    final videos = [_video('a'), _video('b')];

    final counts = LessonCounts.from(videos, {
      'a': _done('a'),
      'left-course': _done('left-course'),
    });

    expect(counts.label, '1/2');
  });

  test('a watched but unfinished lesson is not complete', () {
    final videos = [_video('a')];

    final counts = LessonCounts.from(videos, {
      'a': const VideoProgressStatus(videoId: 'a', watchedSeconds: 30),
    });

    expect(counts.label, '0/1');
  });

  test('no lessons reads 0/0', () {
    expect(LessonCounts.from(const [], const {}).label, '0/0');
  });
}
