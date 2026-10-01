import 'package:flutter/foundation.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../model/youtube_value_extension.dart';

/// State behind the reels seek bar: what to show for the position, the time
/// left and the buffered part, and the drag itself.
///
/// While a finger is on the bar the handle follows the finger and ignores the
/// player's own (lagging) position reports; the video is only moved when the
/// finger lifts, and playing or paused stays as it was.
class YoutubeSeekProvider extends ChangeNotifier {
  YoutubeSeekProvider(this._controller) {
    _controller.addListener(notifyListeners);
  }

  final YoutubePlayerController _controller;

  /// Fraction (0..1) under the finger while dragging, otherwise null.
  double? _drag;

  Duration get _total => _controller.metadata.duration;

  /// The video length is known, so there is something to seek in.
  bool get canSeek => _total > Duration.zero;

  /// Where the handle sits, 0..1.
  double get fraction {
    if (!canSeek) return 0;
    final shown =
        _drag ??
        _controller.value.position.inMilliseconds / _total.inMilliseconds;
    return shown.clamp(0.0, 1.0);
  }

  /// How much of the video is buffered, 0..1.
  double get buffered => _controller.value.buffered.clamp(0.0, 1.0);

  /// The time the left label shows: the dragged-to time while dragging.
  Duration get position =>
      _drag == null ? _controller.value.position : _total * fraction;

  Duration get remaining {
    final left = _total - position;
    return left.isNegative ? Duration.zero : left;
  }

  bool isVisible({required bool controlsShown}) =>
      _controller.value.showsSeekBar(controlsShown: controlsShown);

  void startDrag(double fraction) {
    _drag = fraction;
    _setDragging(true);
    notifyListeners();
  }

  void updateDrag(double fraction) {
    _drag = fraction;
    notifyListeners();
  }

  void endDrag(double fraction) {
    _controller.seekWithoutPlaying(_total * fraction);
    _drag = null;
    _setDragging(false);
    notifyListeners();
  }

  void _setDragging(bool dragging) =>
      _controller.updateValue(_controller.value.copyWith(isDragging: dragging));

  @override
  void dispose() {
    _controller.removeListener(notifyListeners);
    super.dispose();
  }
}
