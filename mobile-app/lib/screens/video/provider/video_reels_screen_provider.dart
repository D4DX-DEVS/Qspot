import 'package:flutter/foundation.dart';

import '../../../services/video_progress_service.dart';

/// Screen-local state for the reels feed: the current page plus, per reel,
/// whether its player is ready and the latest watch progress.
class VideoReelsScreenProvider extends ChangeNotifier {
  VideoReelsScreenProvider({required int initialIndex}) : _index = initialIndex;

  int _index;
  final Set<int> _ready = {};
  final Map<int, VideoProgressStatus> _progress = {};

  int get index => _index;

  bool isReady(int reel) => _ready.contains(reel);

  VideoProgressStatus? progressFor(int reel) => _progress[reel];

  void setIndex(int value) {
    _index = value;
    notifyListeners();
  }

  void markReady(int reel) {
    _ready.add(reel);
    notifyListeners();
  }

  void setProgress(int reel, VideoProgressStatus status) {
    _progress[reel] = status;
    notifyListeners();
  }
}
