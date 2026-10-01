import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qspot/screens/video/provider/youtube_playback_toggle.dart';
import 'package:qspot/screens/video/widgets/youtube_centre_button.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

void main() {
  late YoutubePlayerController controller;
  late YoutubePlaybackToggle toggle;

  void startIn(PlayerState state, {bool ready = true}) {
    controller.updateValue(
      controller.value.copyWith(
        isReady: ready,
        playerState: state,
        isPlaying: state == PlayerState.playing,
      ),
    );
  }

  // What the plugin does when the web page reports a state change.
  void report(PlayerState state) {
    controller.updateValue(
      controller.value.copyWith(
        playerState: state,
        isPlaying: state == PlayerState.playing,
      ),
    );
  }

  PlayerState shown() => controller.value.playerState;

  setUp(() {
    controller = YoutubePlayerController(initialVideoId: 'abcdefghijk');
    toggle = YoutubePlaybackToggle(controller);
  });

  tearDown(() {
    toggle.dispose();
    controller.dispose();
  });

  testWidgets('shows the expected state at once, before the player reports', (
    tester,
  ) async {
    startIn(PlayerState.playing);
    toggle.toggle();
    expect(shown(), PlayerState.paused);
    expect(controller.value.isPlaying, isFalse);

    report(PlayerState.paused);
    toggle.toggle();
    expect(shown(), PlayerState.playing);
    expect(controller.value.isPlaying, isTrue);

    // Settle the hold-off timers.
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('buffering while starting is fine; playing confirms', (
    tester,
  ) async {
    startIn(PlayerState.paused);
    toggle.toggle();

    report(PlayerState.buffering);
    expect(shown(), PlayerState.buffering);
    report(PlayerState.playing);
    expect(shown(), PlayerState.playing);

    // Confirmed, so a real pause later is shown as it is.
    report(PlayerState.paused);
    expect(shown(), PlayerState.paused);
  });

  testWidgets('a stale "paused" after tapping play is held back', (
    tester,
  ) async {
    startIn(PlayerState.paused);
    toggle.toggle();

    report(PlayerState.paused); // late report of the earlier pause
    expect(shown(), PlayerState.playing, reason: 'no play icon flash');

    report(PlayerState.playing);
    expect(shown(), PlayerState.playing);
  });

  testWidgets('quick pause then play never flashes the wrong icon', (
    tester,
  ) async {
    startIn(PlayerState.playing);
    toggle.toggle(); // pause
    toggle.toggle(); // play again before the player has reported anything
    expect(shown(), PlayerState.playing);

    report(PlayerState.paused); // the pause finally reported
    expect(shown(), PlayerState.playing);
    report(PlayerState.buffering);
    report(PlayerState.playing);
    expect(shown(), PlayerState.playing);
  });

  testWidgets('quick play then pause never flashes the wrong icon', (
    tester,
  ) async {
    startIn(PlayerState.paused);
    toggle.toggle(); // play
    toggle.toggle(); // pause again before the player has reported anything
    expect(shown(), PlayerState.paused);

    report(PlayerState.buffering); // the play, finally reported
    report(PlayerState.playing);
    expect(shown(), PlayerState.paused);

    report(PlayerState.paused);
    expect(shown(), PlayerState.paused);

    report(PlayerState.playing); // confirmed already, so this one is real
    expect(shown(), PlayerState.playing);
  });

  testWidgets('a finished video replays as buffering, and a stale "ended" is '
      'held back', (tester) async {
    startIn(PlayerState.ended);
    toggle.toggle();
    expect(shown(), PlayerState.buffering);
    expect(controller.value.isPlaying, isFalse);

    report(PlayerState.ended);
    expect(shown(), PlayerState.buffering);

    report(PlayerState.playing);
    expect(shown(), PlayerState.playing);
  });

  testWidgets('if the player never confirms, its real state comes back', (
    tester,
  ) async {
    startIn(PlayerState.paused);
    toggle.toggle();
    report(PlayerState.paused); // play was refused; this is the truth

    expect(shown(), PlayerState.playing, reason: 'held back for now');

    await tester.pump(const Duration(milliseconds: 999));
    expect(shown(), PlayerState.playing);

    await tester.pump(const Duration(milliseconds: 1));
    expect(shown(), PlayerState.paused);
  });

  testWidgets('does nothing before the player is ready', (tester) async {
    startIn(PlayerState.paused, ready: false);
    toggle.toggle();

    expect(shown(), PlayerState.paused);
  });

  testWidgets('after the player is reset (its web view was destroyed) a tap '
      'does nothing instead of calling the dead web view', (tester) async {
    startIn(PlayerState.playing);
    controller.reset();
    expect(controller.value.isReady, isFalse);

    toggle.toggle();

    expect(shown(), PlayerState.unknown);
  });

  testWidgets('disposing stops it holding anything back or touching the '
      'player later', (tester) async {
    startIn(PlayerState.paused);
    toggle.toggle();
    toggle.dispose();

    report(PlayerState.paused);
    expect(shown(), PlayerState.paused);

    // A leftover timer would fail the test here.
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('the icon goes straight from play to pause with no flash back', (
    tester,
  ) async {
    startIn(PlayerState.paused);
    await tester.pumpWidget(
      MaterialApp(
        home: YoutubeCentreButton(controller: controller, started: true),
      ),
    );
    final seen = <IconData>[];
    void note() {
      final icon = tester.widget<Icon>(find.byType(Icon)).icon;
      if (icon != null) seen.add(icon);
    }

    note();
    toggle.toggle();
    await tester.pump();
    note();
    report(PlayerState.paused); // stale report of the earlier state
    await tester.pump();
    note();
    report(PlayerState.buffering);
    await tester.pump();
    note();
    report(PlayerState.playing);
    await tester.pump();
    note();

    expect(seen, [
      Icons.play_arrow_rounded,
      Icons.pause_rounded,
      Icons.pause_rounded,
      Icons.pause_rounded,
      Icons.pause_rounded,
    ]);
    await tester.pump(const Duration(seconds: 2));
  });
}
