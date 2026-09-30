import 'package:flutter/foundation.dart';

/// Screen-local state for the video list screen: whether the search field
/// is showing in the app bar.
class VideoListScreenProvider extends ChangeNotifier {
  VideoListScreenProvider({bool isSearching = false})
    : _isSearching = isSearching;

  bool _isSearching;

  bool get isSearching => _isSearching;

  void toggleSearching() {
    _isSearching = !_isSearching;
    notifyListeners();
  }
}
