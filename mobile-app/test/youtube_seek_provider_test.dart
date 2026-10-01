import 'package:flutter_test/flutter_test.dart';
import 'package:qspot/screens/video/provider/youtube_seek_provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

void main() {
  late YoutubePlayerController controller;
  late YoutubeSeekProvider seek;

  void emit({
    Duration position = const Duration(seconds: 30),
    Duration duration = const Duration(minutes: 2),
    PlayerState state = PlayerState.paused,
    bool ready = true,
  }) {
    controller.updateValue(
      controller.value.copyWith(
        isReady: ready,
        playerState: state,
        position: position,
        metaData: YoutubeMetaData(duration: duration),
      ),
    );
  }

  setUp(() {
    controller = YoutubePlayerController(initialVideoId: 'abcdefghijk');
    emit();
    seek = YoutubeSeekProvider(controller);
  });

  tearDown(() {
    seek.dispose();
    controller.dispose();
  });

  test('shows the player position, time left and buffered part', () {
    controller.updateValue(controller.value.copyWith(buffered: 0.6));

    expect(seek.canSeek, isTrue);
    expect(seek.fraction, 0.25);
    expect(seek.position, const Duration(seconds: 30));
    expect(seek.remaining, const Duration(seconds: 90));
    expect(seek.buffered, 0.6);
  });

  test('cannot seek until the video length is known', () {
    emit(duration: Duration.zero);

    expect(seek.canSeek, isFalse);
    expect(seek.fraction, 0);
  });

  test('follows the player and tells the screen when it changes', () {
    var notified = 0;
    seek.addListener(() => notified++);

    emit(position: const Duration(seconds: 60));

    expect(seek.fraction, 0.5);
    expect(notified, greaterThan(0));
  });

  test('while dragging, the handle follows the finger, not the player', () {
    seek.startDrag(0.5);
    expect(controller.value.isDragging, isTrue);
    expect(seek.fraction, 0.5);
    expect(seek.position, const Duration(seconds: 60));
    expect(seek.remaining, const Duration(seconds: 60));

    // The player reports a lagging position; the handle must not jump.
    emit(position: const Duration(seconds: 31));
    expect(seek.fraction, 0.5);

    seek.updateDrag(0.75);
    expect(seek.position, const Duration(seconds: 90));
    expect(controller.value.position, const Duration(seconds: 31));
  });

  test('releasing seeks once and leaves play/pause alone', () {
    for (final state in [PlayerState.paused, PlayerState.playing]) {
      emit(state: state);
      seek.startDrag(0.25);
      seek.endDrag(0.5);

      expect(controller.value.position, const Duration(seconds: 60));
      expect(controller.value.isDragging, isFalse);
      expect(controller.value.playerState, state);
      expect(seek.fraction, 0.5, reason: 'back to following the player');
    }
  });

  test('handle and times stay within range', () {
    emit(position: const Duration(minutes: 5));

    expect(seek.fraction, 1);
    expect(seek.remaining, Duration.zero);
  });

  test('is visible while dragging even when the controls are hidden', () {
    emit(state: PlayerState.playing);
    expect(seek.isVisible(controlsShown: false), isFalse);

    seek.startDrag(0.5);
    expect(seek.isVisible(controlsShown: false), isTrue);
  });
}
