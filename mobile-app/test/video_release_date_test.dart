import 'package:flutter_test/flutter_test.dart';
import 'package:qspot/screens/video/model/video_model.dart';

void main() {
  DateTime? read(Object? releaseDate) =>
      VideoModel.fromJson({'_id': 'v1', 'releaseDate': releaseDate}).date;

  test('a release date saved from the admin panel is read, in local time', () {
    final date = read('2026-10-20T04:30:00.000Z');
    expect(date, isNotNull);
    expect(date!.isUtc, isFalse);
    expect(date.isAtSameMomentAs(DateTime.utc(2026, 10, 20, 4, 30)), isTrue);
  });

  test('a plain day is still read as that day', () {
    expect(read('2026-09-15'), DateTime(2026, 9, 15));
  });

  test('the date survives the local cache', () {
    final video = VideoModel.fromJson({
      '_id': 'v1',
      'releaseDate': '2026-10-20T04:30:00.000Z',
    });
    final cached = VideoModel.fromJson(video.toJson());
    expect(cached.date!.isAtSameMomentAs(video.date!), isTrue);
  });

  test('an unreadable date is left empty', () {
    expect(read('not a date'), isNull);
  });
}
