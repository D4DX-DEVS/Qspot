import 'package:flutter/foundation.dart';

/// Selected tab of the main navigation shell. An out-of-range index falls
/// back to the first tab.
class MainNavigationProvider extends ChangeNotifier {
  MainNavigationProvider({required this.tabCount, int initialIndex = 0})
    : _currentIndex = initialIndex >= tabCount ? 0 : initialIndex;

  /// Position of the Learn tab in the shell, for screens that jump to it.
  static const learnTabIndex = 1;

  final int tabCount;
  int _currentIndex;

  int get currentIndex => _currentIndex;

  void setIndex(int index) {
    _currentIndex = index >= tabCount ? 0 : index;
    notifyListeners();
  }
}
