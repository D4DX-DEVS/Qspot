import 'package:flutter/foundation.dart';

import '../model/speaker_model.dart';

/// Screen-local state for the faculties screen: whether the search field is
/// open and the current search query.
class FacultiesScreenProvider extends ChangeNotifier {
  bool _isSearching = false;
  String _query = '';

  bool get isSearching => _isSearching;
  String get query => _query;

  void setQuery(String value) {
    _query = value.trim();
    notifyListeners();
  }

  /// Opens or closes the search field; closing also clears the query.
  void toggleSearching() {
    _isSearching = !_isSearching;
    if (!_isSearching) _query = '';
    notifyListeners();
  }

  /// [all] narrowed to the speakers matching the current query.
  List<SpeakerModel> filter(List<SpeakerModel> all) {
    if (_query.isEmpty) return all;
    return all.where((speaker) => _matches(speaker, _query)).toList();
  }

  bool _matches(SpeakerModel speaker, String query) {
    final needle = query.toLowerCase();
    return speaker.name.toLowerCase().contains(needle) ||
        speaker.designation.toLowerCase().contains(needle);
  }
}
