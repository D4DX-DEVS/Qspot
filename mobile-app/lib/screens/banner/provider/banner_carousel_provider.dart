import 'package:flutter/foundation.dart';

/// Which banner the carousel is currently showing (drives the indicators).
class BannerCarouselProvider extends ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void setIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }
}
