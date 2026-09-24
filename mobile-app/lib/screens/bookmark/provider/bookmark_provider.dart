import 'package:flutter/foundation.dart';

import '../../video/model/video_model.dart';
import '../service/bookmark_service.dart';

class BookmarkProvider extends ChangeNotifier {
  /// The HTTP calls are injectable so widget/provider tests can supply a
  /// fake instead of hitting the network (see `test/bookmark_provider_test.dart`).
  final Future<List<VideoModel>> Function() _fetchAll;
  final Future<List<String>> Function(String videoId) _addRemote;
  final Future<List<String>> Function(String videoId) _removeRemote;

  BookmarkProvider({
    Future<List<VideoModel>> Function()? fetchAll,
    Future<List<String>> Function(String videoId)? addRemote,
    Future<List<String>> Function(String videoId)? removeRemote,
  }) : _fetchAll = fetchAll ?? BookmarkService.getAllBookmarks,
       _addRemote = addRemote ?? BookmarkService.addBookmark,
       _removeRemote = removeRemote ?? BookmarkService.removeBookmark;

  // In-memory cache — no local DB any more (server owns bookmarks). Kept
  // across screen opens so BookmarksScreen does not need to refetch every
  // time; refreshed explicitly on pull-to-refresh or after add/remove.
  List<VideoModel> _bookmarks = [];
  bool _isLoading = false;
  String _errorMessage = '';
  bool _loadedOnce = false;

  List<VideoModel> get bookmarks => _bookmarks;
  bool get isLoading => _isLoading;
  bool get hasError => _errorMessage.isNotEmpty;
  String get errorMessage => _errorMessage;
  int get bookmarksCount => _bookmarks.length;

  Future<void> initialize() async {
    if (_loadedOnce) return;
    await loadBookmarks();
  }

  Future<void> loadBookmarks() async {
    _setLoading(true);
    _clearError();

    try {
      _bookmarks = await _fetchAll();
      _loadedOnce = true;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load bookmarks: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addBookmark(VideoModel video) async {
    if (isBookmarkedSync(video.id)) return false;
    try {
      // Optimistic update so the UI reacts immediately.
      _bookmarks = [video, ..._bookmarks];
      notifyListeners();
      await _addRemote(video.id);
      return true;
    } catch (e) {
      _bookmarks = _bookmarks.where((v) => v.id != video.id).toList();
      _setError('Failed to add bookmark: $e');
      return false;
    }
  }

  Future<bool> removeBookmark(String videoId) async {
    final removed = _bookmarks.where((v) => v.id == videoId).toList();
    try {
      _bookmarks = _bookmarks.where((v) => v.id != videoId).toList();
      notifyListeners();
      await _removeRemote(videoId);
      return true;
    } catch (e) {
      if (removed.isNotEmpty) _bookmarks = [removed.first, ..._bookmarks];
      _setError('Failed to remove bookmark: $e');
      return false;
    }
  }

  Future<bool> toggleBookmark(VideoModel video) async {
    if (isBookmarkedSync(video.id)) {
      return await removeBookmark(video.id);
    } else {
      return await addBookmark(video);
    }
  }

  bool isBookmarkedSync(String videoId) {
    return _bookmarks.any((video) => video.id == videoId);
  }

  Future<bool> clearAllBookmarks() async {
    final previous = _bookmarks;
    try {
      _bookmarks = [];
      notifyListeners();
      for (final video in previous) {
        await _removeRemote(video.id);
      }
      return true;
    } catch (e) {
      _setError('Failed to clear bookmarks: $e');
      await loadBookmarks();
      return false;
    }
  }

  VideoModel? getBookmark(String videoId) {
    try {
      return _bookmarks.firstWhere((video) => video.id == videoId);
    } catch (_) {
      return null;
    }
  }

  List<VideoModel> searchBookmarks(String query) {
    if (query.isEmpty) return _bookmarks;
    final lowercaseQuery = query.toLowerCase();
    return _bookmarks.where((video) {
      return video.displayTitle.toLowerCase().contains(lowercaseQuery) ||
          video.caption.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = '';
  }

  /// Resets local state only (does NOT touch the server). Call on logout so
  /// the next account on this device doesn't see the previous user's
  /// bookmarks before its own load completes (M6).
  void clear() {
    _bookmarks = [];
    _isLoading = false;
    _errorMessage = '';
    _loadedOnce = false;
    notifyListeners();
  }
}
