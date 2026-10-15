import 'package:flutter/foundation.dart';

import '../../../services/video_progress_service.dart';

/// Screen-local state for the video player screen: whether the player is
/// ready, whether it is full screen, and the server-side watch status.
class VideoPlayerScreenProvider extends ChangeNotifier {
  bool _isPlayerReady = false;
  bool _isFullScreen = false;
  VideoProgressStatus? _progress;

  bool get isPlayerReady => _isPlayerReady;
  bool get isFullScreen => _isFullScreen;
  VideoProgressStatus? get progress => _progress;

  void setPlayerReady(bool value) {
    _isPlayerReady = value;
    notifyListeners();
  }

  void setFullScreen(bool value) {
    _isFullScreen = value;
    notifyListeners();
  }

  void toggleFullScreen() => setFullScreen(!_isFullScreen);

  void setProgress(VideoProgressStatus? value) {
    _progress = value;
    notifyListeners();
  }
}
