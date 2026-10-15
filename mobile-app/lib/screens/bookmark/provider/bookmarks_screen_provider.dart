import 'package:flutter/foundation.dart';

import '../../video/model/video_model.dart';
import 'bookmark_provider.dart';

/// Screen-local state for the bookmarks screen: the current search query.
class BookmarksScreenProvider extends ChangeNotifier {
  String _query = '';

  String get query => _query;

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  /// Bookmarks from [source] matching the current query; all when it is empty.
  List<VideoModel> filter(BookmarkProvider source) {
    return _query.isEmpty ? source.bookmarks : source.searchBookmarks(_query);
  }
}
