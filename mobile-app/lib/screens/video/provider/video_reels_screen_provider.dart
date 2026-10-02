import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../services/video_progress_service.dart';

/// Screen-local state for the reels feed: the current page plus, per reel,
/// whether its player is ready, whether its on-screen controls are showing and
/// the latest watch progress.
class VideoReelsScreenProvider extends ChangeNotifier {
  VideoReelsScreenProvider({required int initialIndex}) : _index = initialIndex;

  /// How long tapped-open controls stay up before hiding themselves.
  static const Duration controlsHideDelay = Duration(seconds: 3);

  int _index;
  final Set<int> _ready = {};
  final Set<int> _started = {};
  final Set<int> _controlsShown = {};
  final Map<int, Timer> _controlsTimers = {};
  final Map<int, VideoProgressStatus> _progress = {};

  int get index => _index;

  bool isReady(int reel) => _ready.contains(reel);

  /// True from the moment a reel is actually playing until it ends. The
  /// thumbnail covers the player the rest of the time.
  bool isStarted(int reel) => _started.contains(reel);

  void setStarted(int reel, bool started) {
    final changed = started ? _started.add(reel) : _started.remove(reel);
    if (changed) notifyListeners();
  }

  /// Whether the controls were opened by a tap and have not hidden yet.
  bool areControlsShown(int reel) => _controlsShown.contains(reel);

  /// Shows the controls if hidden, hides them if showing.
  void toggleControls(int reel, {bool Function()? canHide}) {
    if (areControlsShown(reel)) {
      hideControls(reel);
    } else {
      showControls(reel, canHide: canHide);
    }
  }

  /// Shows the controls and (re)starts the auto-hide countdown. When it runs
  /// out, [canHide] is asked first (for example "is the seek bar being
  /// dragged?"); if it says no, the countdown starts again.
  void showControls(int reel, {bool Function()? canHide}) {
    _controlsTimers[reel]?.cancel();
    _controlsTimers[reel] = Timer(
      controlsHideDelay,
      () => _autoHide(reel, canHide),
    );
    if (_controlsShown.add(reel)) notifyListeners();
  }

  void hideControls(int reel) {
    _controlsTimers.remove(reel)?.cancel();
    if (_controlsShown.remove(reel)) notifyListeners();
  }

  void _autoHide(int reel, bool Function()? canHide) {
    if (canHide != null && !canHide()) {
      _controlsTimers[reel] = Timer(
        controlsHideDelay,
        () => _autoHide(reel, canHide),
      );
      return;
    }
    hideControls(reel);
  }

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

  @override
  void dispose() {
    for (final timer in _controlsTimers.values) {
      timer.cancel();
    }
    _controlsTimers.clear();
    super.dispose();
  }
}
