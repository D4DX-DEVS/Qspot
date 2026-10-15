import 'dart:async';

import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../model/youtube_value_extension.dart';

/// The centre play / pause button's logic for one YouTube player.
///
/// A tap pauses a playing (or still-buffering) video, plays a paused one and
/// restarts a finished one. The player only reports its new state after a round
/// trip through the web page, so the expected state is shown at once. Reports
/// are not ordered against our commands either: after a quick pause then play,
/// the earlier "paused" can arrive after we already show "playing". So until the
/// player confirms the new state, a report that contradicts it is held back.
/// If it never confirms, the real state is restored after [holdFor].
class YoutubePlaybackToggle {
  YoutubePlaybackToggle(
    this._controller, {
    this.holdFor = const Duration(seconds: 1),
  }) {
    _controller.addListener(_onValue);
  }

  final YoutubePlayerController _controller;

  /// How long to wait for the player to confirm before trusting its reports.
  final Duration holdFor;

  /// The state we asked for and are still waiting to see confirmed.
  PlayerState? _expected;

  /// The last contradicting report held back, restored if nothing confirms.
  PlayerState? _heldBack;

  Timer? _timer;

  /// True while we write to the controller ourselves, so our own writes are
  /// never mistaken for a report from the player.
  bool _writing = false;

  /// Ignored until the player is ready.
  void toggle() {
    final value = _controller.value;
    if (!value.isReady) return;

    final PlayerState expected;
    if (value.isPlayingOrBuffering) {
      _controller.pause();
      expected = PlayerState.paused;
    } else if (value.playerState == PlayerState.ended) {
      _controller.seekTo(Duration.zero);
      _controller.play();
      // Not "playing" yet: the thumbnail keeps covering YouTube's end screen
      // until a frame really plays.
      expected = PlayerState.buffering;
    } else {
      _controller.play();
      expected = PlayerState.playing;
    }

    _expected = expected;
    _heldBack = null;
    _timer?.cancel();
    _timer = Timer(holdFor, _giveUp);
    _show(expected);
  }

  void _onValue() {
    final expected = _expected;
    if (expected == null || _writing) return;

    final reported = _controller.value.playerState;
    final wantsPlaying = expected != PlayerState.paused;

    if (wantsPlaying) {
      if (reported == PlayerState.playing) return _clear();
      if (reported == PlayerState.paused || reported == PlayerState.ended) {
        _heldBack = reported;
        _show(expected);
      }
    } else {
      if (reported == PlayerState.paused) return _clear();
      if (reported == PlayerState.playing ||
          reported == PlayerState.buffering) {
        _heldBack = reported;
        _show(expected);
      }
    }
  }

  void _show(PlayerState state) {
    _writing = true;
    try {
      _controller.updateValue(_withState(state));
    } finally {
      _writing = false;
    }
  }

  YoutubePlayerValue _withState(PlayerState state) => _controller.value
      .copyWith(playerState: state, isPlaying: state == PlayerState.playing);

  void _giveUp() {
    final heldBack = _heldBack;
    _clear();
    if (heldBack != null) _controller.updateValue(_withState(heldBack));
  }

  void _clear() {
    _expected = null;
    _heldBack = null;
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    _clear();
    _controller.removeListener(_onValue);
  }
}
