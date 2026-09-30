import 'package:flutter_test/flutter_test.dart';
import 'package:qspot/screens/video/model/video_model.dart';

VideoModel episode(String id, String title) => VideoModel(
  id: id,
  caption: title,
  title: title,
  video: 'https://www.youtube.com/shorts/$id',
);

void main() {
  test('an episode and its "| Class NN" copy share a key', () {
    final plain = episode(
      'a',
      'Episode 29 | ഖുർആനും ഇതര വേദങ്ങളും | സി ടി സുഹൈബ്',
    );
    final classCopy = episode(
      'b',
      'Episode 29 | ഖുർആനും ഇതര വേദങ്ങളും | സി ടി സുഹൈബ് | Class 06',
    );

    expect(plain.episodeKey, classCopy.episodeKey);
    expect(plain.id, isNot(classCopy.id));
  });

  test('different episodes keep different keys', () {
    final first = episode(
      'a',
      'Episode 29 | ഖുർആനും ഇതര വേദങ്ങളും | സി ടി സുഹൈബ്',
    );
    final second = episode(
      'c',
      'Episode 27 | ദ്രോഹങ്ങൾ പലവിധം | ബശീർ മുഹ്‍യിദ്ദീൻ',
    );

    expect(first.episodeKey, isNot(second.episodeKey));
  });

  test('distinctEpisodes keeps the first copy of each episode', () {
    final videos = [
      episode('a', 'Episode 29 | ഖുർആനും ഇതര വേദങ്ങളും | സി ടി സുഹൈബ്'),
      episode(
        'b',
        'Episode 29 | ഖുർആനും ഇതര വേദങ്ങളും | സി ടി സുഹൈബ് | Class 06',
      ),
      episode('c', 'Episode 27 | ദ്രോഹങ്ങൾ പലവിധം | ബശീർ മുഹ്‍യിദ്ദീൻ'),
      episode(
        'd',
        'Episode 27 | ദ്രോഹങ്ങൾ പലവിധം | ബശീർ മുഹ്‍യിദ്ദീൻ | Class 10',
      ),
      episode('e', 'Episode 26 | സത്യത്തിന് മുമ്പിൽ'),
    ];

    final distinct = VideoModel.distinctEpisodes(videos);

    expect(distinct.length, 3);
    expect(distinct.map((video) => video.id).toList(), ['a', 'c', 'e']);
  });

  test('an episode with no title still dedupes on its id', () {
    final videos = [
      episode('same', ''),
      episode('same', ''),
      episode('other', ''),
    ];

    expect(VideoModel.distinctEpisodes(videos).length, 2);
  });
}
