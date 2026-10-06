import 'package:flutter/foundation.dart';

/// Selected tab of the main navigation shell. An out-of-range index falls
/// back to the first tab.
class MainNavigationProvider extends ChangeNotifier {
  MainNavigationProvider({
    required int tabCount,
    int initialIndex = 0,
    List<String>? tabKeys,
  }) : _tabCount = tabCount,
       _tabKeys = List.unmodifiable(tabKeys ?? const <String>[]),
       _currentIndex = initialIndex < 0 || initialIndex >= tabCount
           ? 0
           : initialIndex;

  int _tabCount;
  List<String> _tabKeys;
  int _currentIndex;

  int get tabCount => _tabCount;
  int get currentIndex => _currentIndex;

  int indexForKey(String key) {
    final index = _tabKeys.indexOf(key);
    return index < 0 ? 0 : index;
  }

  bool hasKey(String key) => _tabKeys.contains(key);

  String? keyAt(int index) =>
      index >= 0 && index < _tabKeys.length ? _tabKeys[index] : null;

  String? get currentKey => keyAt(_currentIndex);

  void setTabConfiguration({required int tabCount, List<String>? tabKeys}) {
    _tabCount = tabCount;
    _tabKeys = List.unmodifiable(tabKeys ?? const <String>[]);
    if (_currentIndex >= _tabCount || _currentIndex < 0) _currentIndex = 0;
    notifyListeners();
  }

  void setIndex(int index) {
    _currentIndex = index < 0 || index >= tabCount ? 0 : index;
    notifyListeners();
  }
}
