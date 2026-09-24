import 'package:flutter_test/flutter_test.dart';
import 'package:qspot/screens/bookmark/provider/bookmark_provider.dart';
import 'package:qspot/screens/video/model/video_model.dart';

VideoModel _video(String id) => VideoModel.fromJson({
  '_id': id,
  'title': 'Episode $id',
  'video': 'https://cdn.example.com/$id.mp4',
});

void main() {
  group('BookmarkProvider (server-backed, no sqflite)', () {
    test('loadBookmarks populates from the injected fetch call', () async {
      final provider = BookmarkProvider(
        fetchAll: () async => [_video('a'), _video('b')],
      );

      await provider.loadBookmarks();

      expect(provider.bookmarks.length, 2);
      expect(provider.isBookmarkedSync('a'), isTrue);
      expect(provider.hasError, isFalse);
    });

    test(
      'addBookmark applies optimistically and calls the remote add',
      () async {
        final calls = <String>[];
        final provider = BookmarkProvider(
          fetchAll: () async => [],
          addRemote: (id) async {
            calls.add(id);
            return [id];
          },
        );

        final added = await provider.addBookmark(_video('v1'));

        expect(added, isTrue);
        expect(provider.isBookmarkedSync('v1'), isTrue);
        expect(calls, ['v1']);
      },
    );

    test(
      'addBookmark rolls back the optimistic update when the call fails',
      () async {
        final provider = BookmarkProvider(
          fetchAll: () async => [],
          addRemote: (id) async => throw Exception('network down'),
        );

        final added = await provider.addBookmark(_video('v1'));

        expect(added, isFalse);
        expect(provider.isBookmarkedSync('v1'), isFalse);
        expect(provider.hasError, isTrue);
      },
    );

    test('addBookmark is a no-op when already bookmarked', () async {
      var callCount = 0;
      final provider = BookmarkProvider(
        fetchAll: () async => [_video('v1')],
        addRemote: (id) async {
          callCount++;
          return [id];
        },
      );
      await provider.loadBookmarks();

      final added = await provider.addBookmark(_video('v1'));

      expect(added, isFalse);
      expect(callCount, 0);
    });

    test(
      'removeBookmark applies optimistically and calls the remote remove',
      () async {
        final calls = <String>[];
        final provider = BookmarkProvider(
          fetchAll: () async => [_video('v1'), _video('v2')],
          removeRemote: (id) async {
            calls.add(id);
            return [];
          },
        );
        await provider.loadBookmarks();

        final removed = await provider.removeBookmark('v1');

        expect(removed, isTrue);
        expect(provider.isBookmarkedSync('v1'), isFalse);
        expect(provider.isBookmarkedSync('v2'), isTrue);
        expect(calls, ['v1']);
      },
    );

    test('removeBookmark restores the item when the call fails', () async {
      final provider = BookmarkProvider(
        fetchAll: () async => [_video('v1')],
        removeRemote: (id) async => throw Exception('network down'),
      );
      await provider.loadBookmarks();

      final removed = await provider.removeBookmark('v1');

      expect(removed, isFalse);
      expect(provider.isBookmarkedSync('v1'), isTrue);
    });

    test('toggleBookmark adds when absent and removes when present', () async {
      final provider = BookmarkProvider(
        fetchAll: () async => [],
        addRemote: (id) async => [id],
        removeRemote: (id) async => [],
      );

      await provider.toggleBookmark(_video('v1'));
      expect(provider.isBookmarkedSync('v1'), isTrue);

      await provider.toggleBookmark(_video('v1'));
      expect(provider.isBookmarkedSync('v1'), isFalse);
    });

    test('clear() resets local state without calling the network', () async {
      var removeCalls = 0;
      final provider = BookmarkProvider(
        fetchAll: () async => [_video('v1')],
        removeRemote: (id) async {
          removeCalls++;
          return [];
        },
      );
      await provider.loadBookmarks();

      provider.clear();

      expect(provider.bookmarks, isEmpty);
      expect(removeCalls, 0);
    });
  });
}
