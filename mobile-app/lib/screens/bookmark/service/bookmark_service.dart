import '../../../services/api_client.dart';
import '../../video/model/video_model.dart';

/// Server-side bookmarks (`/api/user/bookmarks`). Replaces the old
/// sqflite-backed local store — bookmarks now sync across devices and
/// survive a reinstall, and the server returns full video objects (so cards
/// no longer show a placeholder thumbnail — see M20).
class BookmarkService {
  static Future<List<VideoModel>> getAllBookmarks() async {
    final body = await ApiClient.get('/api/user/bookmarks');
    if (body is! List) return [];
    return body
        .whereType<Map>()
        .map((json) => VideoModel.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  /// Returns the updated set of bookmarked video ids.
  static Future<List<String>> addBookmark(String videoId) async {
    final body = await ApiClient.put('/api/user/bookmarks/$videoId');
    return _ids(body);
  }

  /// Returns the updated set of bookmarked video ids.
  static Future<List<String>> removeBookmark(String videoId) async {
    final body = await ApiClient.delete('/api/user/bookmarks/$videoId');
    return _ids(body);
  }

  static List<String> _ids(dynamic body) {
    if (body is! Map || body['bookmarks'] is! List) return [];
    return (body['bookmarks'] as List).map((e) => e.toString()).toList();
  }
}
