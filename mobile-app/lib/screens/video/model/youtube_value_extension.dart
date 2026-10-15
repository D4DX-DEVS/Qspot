import 'package:flutter/foundation.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

/// Playback questions the reels controls ask of a YouTube player, kept in one
/// place so the tap handler, centre icon and seek bar always agree.
extension YoutubeValueState on YoutubePlayerValue {
  /// The video is playing, or has been told to play and is still buffering.
  /// The centre button should pause it.
  bool get isPlayingOrBuffering =>
      playerState == PlayerState.playing ||
      playerState == PlayerState.buffering;

  /// Ready and stopped (paused or finished).
  bool get isStopped =>
      isReady &&
      (playerState == PlayerState.paused || playerState == PlayerState.ended);

  /// Whether the video is still loading, so the centre button shows a ring
  /// instead of its icon: the player is not ready, it is buffering, or the
  /// video has not played yet and is only cued (the short gap between "ready"
  /// and the first frame, where a play icon would flash).
  bool isLoading({required bool started}) =>
      !hasError &&
      (!isReady ||
          playerState == PlayerState.buffering ||
          (!started &&
              (playerState == PlayerState.cued ||
                  playerState == PlayerState.unStarted ||
                  playerState == PlayerState.unknown)));

  /// Whether the seek bar is on screen: always while stopped, otherwise only
  /// when the controls were tapped open. It never disappears under a finger
  /// that is still dragging it.
  bool showsSeekBar({required bool controlsShown}) =>
      isReady && (controlsShown || isStopped || isDragging);

  /// Whether the centre button is on screen: whenever the seek bar is, so a
  /// tap hides or reveals both together, and always while loading so the ring
  /// never vanishes mid-buffer.
  bool showsCentreButton({
    required bool controlsShown,
    required bool started,
  }) =>
      isLoading(started: started) || showsSeekBar(controlsShown: controlsShown);
}

extension YoutubeSeeking on YoutubePlayerController {
  /// Jumps to [position] without changing whether the video is playing.
  ///
  /// The plugin's own `seekTo` also calls `play()`, so a paused video would
  /// start playing the moment it is scrubbed. This runs the same page-level
  /// `seekTo` the plugin does, minus the `play()`.
  void seekWithoutPlaying(Duration position) {
    if (!value.isReady) return;
    value.webViewController
        ?.evaluateJavascript(
          source: 'seekTo(${position.inMilliseconds / 1000},true)',
        )
        .catchError((Object error) {
          // The web view can be torn down just as the finger lifts.
          debugPrint('Seek skipped: $error');
          return null;
        });
    // The player keeps reporting the old spot until the new one loads.
    holdPositionAt(position);
    updateValue(value.copyWith(position: position));
  }
}

extension ClockText on Duration {
  /// `mm:ss`, or `h:mm:ss` from one hour up.
  String get clockText {
    String two(int n) => n.toString().padLeft(2, '0');
    final hours = inHours;
    final minutes = two(inMinutes.remainder(60));
    final seconds = two(inSeconds.remainder(60));
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }
}
