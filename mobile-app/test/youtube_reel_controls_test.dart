import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qspot/screens/video/model/youtube_value_extension.dart';
import 'package:qspot/themes/home_palette.dart';
import 'package:qspot/screens/video/widgets/youtube_centre_button.dart';
import 'package:qspot/screens/video/widgets/youtube_seek_bar.dart';
import 'package:qspot/screens/video/widgets/youtube_tap_zones.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

Widget host(Widget child) => MaterialApp(
  home: Scaffold(
    body: Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(width: 400, child: child),
    ),
  ),
);

void main() {
  late YoutubePlayerController controller;

  setUp(() {
    controller = YoutubePlayerController(initialVideoId: 'abcdefghijk');
  });

  tearDown(() => controller.dispose());

  void emit({bool ready = true, required PlayerState state}) {
    controller.updateValue(
      controller.value.copyWith(isReady: ready, playerState: state),
    );
  }

  bool isStoppedState(PlayerState state) =>
      state == PlayerState.paused || state == PlayerState.ended;

  group('YoutubeValueState', () {
    test('the centre button pauses while playing or buffering', () {
      for (final state in PlayerState.values) {
        emit(state: state);
        final shouldPause =
            state == PlayerState.playing || state == PlayerState.buffering;
        expect(
          controller.value.isPlayingOrBuffering,
          shouldPause,
          reason: '$state',
        );
      }
    });

    test('stopped means ready and paused or ended', () {
      for (final state in PlayerState.values) {
        emit(state: state);
        expect(
          controller.value.isStopped,
          isStoppedState(state),
          reason: '$state',
        );
      }
      emit(ready: false, state: PlayerState.paused);
      expect(controller.value.isStopped, isFalse);
    });

    test('loading: not ready, buffering, or cued before the first play', () {
      emit(ready: false, state: PlayerState.paused);
      expect(controller.value.isLoading(started: true), isTrue);

      for (final state in PlayerState.values) {
        emit(state: state);
        expect(
          controller.value.isLoading(started: true),
          state == PlayerState.buffering,
          reason: '$state, already played',
        );
        final beforeFirstPlay =
            state == PlayerState.buffering ||
            state == PlayerState.cued ||
            state == PlayerState.unStarted ||
            state == PlayerState.unknown;
        expect(
          controller.value.isLoading(started: false),
          beforeFirstPlay,
          reason: '$state, not played yet',
        );
      }
    });

    test('an error is not loading', () {
      controller.updateValue(
        controller.value.copyWith(isReady: false, errorCode: 2),
      );
      expect(controller.value.isLoading(started: false), isFalse);
    });

    test('seek bar: always when stopped, otherwise only if opened', () {
      for (final state in PlayerState.values) {
        emit(state: state);
        expect(
          controller.value.showsSeekBar(controlsShown: false),
          isStoppedState(state),
          reason: '$state, controls hidden',
        );
        expect(
          controller.value.showsSeekBar(controlsShown: true),
          isTrue,
          reason: '$state, controls open',
        );
      }
      emit(ready: false, state: PlayerState.unknown);
      expect(controller.value.showsSeekBar(controlsShown: true), isFalse);
    });
  });

  group('seek bar visibility while dragging', () {
    test('a drag keeps the bar up even when it would otherwise hide', () {
      emit(state: PlayerState.playing);
      expect(controller.value.showsSeekBar(controlsShown: false), isFalse);

      controller.updateValue(controller.value.copyWith(isDragging: true));
      expect(controller.value.showsSeekBar(controlsShown: false), isTrue);
    });
  });

  group('ClockText', () {
    test('formats as mm:ss, and h:mm:ss from one hour', () {
      expect(Duration.zero.clockText, '00:00');
      expect(const Duration(seconds: 8).clockText, '00:08');
      expect(const Duration(minutes: 1, seconds: 46).clockText, '01:46');
      expect(
        const Duration(hours: 1, minutes: 2, seconds: 3).clockText,
        '1:02:03',
      );
    });
  });

  group('YoutubeCentreButton', () {
    final button = find.byType(YoutubeCentreButton);
    final ring = find.byType(CircularProgressIndicator);

    double opacityOf(WidgetTester tester, Finder child) => tester
        .widget<Opacity>(
          find.ancestor(of: child, matching: find.byType(Opacity)).first,
        )
        .opacity;

    Future<void> pump(WidgetTester tester, {bool started = true}) =>
        tester.pumpWidget(
          host(YoutubeCentreButton(controller: controller, started: started)),
        );

    testWidgets('paused: a play icon', (tester) async {
      emit(state: PlayerState.paused);
      await pump(tester);

      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      expect(ring, findsNothing);
    });

    testWidgets('playing: a pause icon that stays up whatever the seek bar '
        'is doing', (tester) async {
      emit(state: PlayerState.playing);
      await pump(tester);

      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
      expect(
        find.descendant(of: button, matching: find.byType(DecoratedBox)),
        findsWidgets,
        reason: 'the circle is there too',
      );
    });

    testWidgets('ended: a single replay icon, never play as well', (
      tester,
    ) async {
      emit(state: PlayerState.ended);
      await pump(tester);

      expect(find.byIcon(Icons.replay_rounded), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
      expect(find.byIcon(Icons.pause_rounded), findsNothing);
    });

    testWidgets('keeps one size in every state, loading included', (
      tester,
    ) async {
      final sizes = <Size>[];
      for (final (ready, state) in [
        (true, PlayerState.paused),
        (true, PlayerState.playing),
        (true, PlayerState.ended),
        (true, PlayerState.buffering),
        (false, PlayerState.unknown),
      ]) {
        emit(ready: ready, state: state);
        await pump(tester);
        await tester.pump(const Duration(seconds: 1));
        sizes.add(
          tester.getSize(
            find
                .descendant(of: button, matching: find.byType(DecoratedBox))
                .first,
          ),
        );
      }

      expect(sizes.toSet(), {const Size.square(YoutubeCentreButton.diameter)});
    });

    testWidgets('before the player is ready the ring shows at once, no icon', (
      tester,
    ) async {
      emit(ready: false, state: PlayerState.unknown);
      await pump(tester);
      await tester.pump(const Duration(milliseconds: 200));

      expect(opacityOf(tester, ring), 1);
      expect(opacityOf(tester, find.byIcon(Icons.play_arrow_rounded)), 0);
    });

    testWidgets('a brief buffer keeps the icon; a long one swaps in the ring', (
      tester,
    ) async {
      emit(state: PlayerState.buffering);
      await pump(tester);
      final icon = find.byIcon(Icons.pause_rounded);

      expect(opacityOf(tester, icon), 1);
      expect(opacityOf(tester, ring), 0);

      await tester.pump(const Duration(milliseconds: 250));
      expect(opacityOf(tester, icon), 1, reason: 'still inside the grace');

      await tester.pump(const Duration(milliseconds: 300));
      expect(opacityOf(tester, ring), 1);
      expect(opacityOf(tester, icon), 0);

      emit(state: PlayerState.playing);
      await tester.pump();
      expect(ring, findsNothing, reason: 'back to the plain icon');
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    });

    testWidgets('the ring is the app brand colour on the app surface colour', (
      tester,
    ) async {
      emit(ready: false, state: PlayerState.unknown);
      await pump(tester);
      await tester.pump(const Duration(seconds: 1));

      final disc = tester.widget<DecoratedBox>(
        find.descendant(of: button, matching: find.byType(DecoratedBox)).first,
      );
      expect(
        tester.widget<CircularProgressIndicator>(ring).color,
        HomePalette.light.brand,
      );
      expect((disc.decoration as BoxDecoration).color, HomePalette.light.card);
    });

    testWidgets('the ring follows the dark palette in dark mode', (
      tester,
    ) async {
      emit(ready: false, state: PlayerState.unknown);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          home: YoutubeCentreButton(controller: controller, started: true),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(
        tester.widget<CircularProgressIndicator>(ring).color,
        HomePalette.dark.brand,
      );
    });

    testWidgets('the circle stays dark glass whenever it is not loading', (
      tester,
    ) async {
      emit(state: PlayerState.playing);
      await pump(tester);

      final disc = tester.widget<DecoratedBox>(
        find.descendant(of: button, matching: find.byType(DecoratedBox)).first,
      );
      expect((disc.decoration as BoxDecoration).color, Colors.black45);
    });

    testWidgets('cued before the first play is loading, not a play icon', (
      tester,
    ) async {
      emit(state: PlayerState.cued);
      await pump(tester, started: false);
      await tester.pump(const Duration(seconds: 1));

      expect(opacityOf(tester, ring), 1);
      expect(opacityOf(tester, find.byIcon(Icons.play_arrow_rounded)), 0);
    });

    testWidgets('shows nothing when the player reports an error', (
      tester,
    ) async {
      controller.updateValue(controller.value.copyWith(errorCode: 2));
      await pump(tester);

      expect(find.byType(Icon), findsNothing);
      expect(ring, findsNothing);
    });

    testWidgets('lets taps through to the zones beneath it', (tester) async {
      var taps = 0;
      emit(state: PlayerState.paused);
      await tester.pumpWidget(
        host(
          SizedBox(
            height: 300,
            child: Stack(
              fit: StackFit.expand,
              children: [
                GestureDetector(onTap: () => taps++),
                YoutubeCentreButton(controller: controller, started: true),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      expect(taps, 1);
    });
  });

  group('YoutubeSeekBar', () {
    final seekBar = find.byType(YoutubeSeekBar);

    bool offstage(WidgetTester tester) => tester
        .widget<Offstage>(
          find.descendant(of: seekBar, matching: find.byType(Offstage)),
        )
        .offstage;

    Future<void> pump(WidgetTester tester, {required bool controlsShown}) =>
        tester.pumpWidget(
          host(
            YoutubeSeekBar(
              controller: controller,
              controlsShown: controlsShown,
            ),
          ),
        );

    testWidgets('is shown while paused, even with the controls hidden', (
      tester,
    ) async {
      emit(state: PlayerState.paused);
      await pump(tester, controlsShown: false);

      expect(offstage(tester), isFalse);
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('while playing it shows only when the controls are open', (
      tester,
    ) async {
      emit(state: PlayerState.playing);
      await pump(tester, controlsShown: false);
      final hiddenHeight = tester.getSize(seekBar).height;
      expect(offstage(tester), isTrue);

      await pump(tester, controlsShown: true);
      expect(offstage(tester), isFalse);
      expect(tester.getSize(seekBar).height, hiddenHeight);
      expect(hiddenHeight, YoutubeSeekBar.height);
    });
  });

  group('YoutubeSeekBar controls and dragging', () {
    Future<void> pumpBar(WidgetTester tester) {
      controller.updateValue(
        controller.value.copyWith(
          isReady: true,
          playerState: PlayerState.paused,
          metaData: const YoutubeMetaData(duration: Duration(minutes: 2)),
          position: const Duration(seconds: 30),
        ),
      );
      return tester.pumpWidget(
        host(YoutubeSeekBar(controller: controller, controlsShown: false)),
      );
    }

    testWidgets('full screen sits right of the playback speed button', (
      tester,
    ) async {
      await pumpBar(tester);

      final speed = tester.getCenter(find.byType(PlaybackSpeedButton)).dx;
      final full = tester.getCenter(find.byType(FullScreenButton)).dx;
      expect(full, greaterThan(speed));
    });

    testWidgets('dragging holds the controls open, seeks only on release and '
        'never changes play/pause', (tester) async {
      await pumpBar(tester);
      final slider = find.byType(Slider);
      final start = tester.getCenter(slider);

      final gesture = await tester.startGesture(start);
      await gesture.moveBy(const Offset(60, 0));
      await tester.pump();
      expect(controller.value.isDragging, isTrue);
      expect(
        controller.value.position,
        const Duration(seconds: 30),
        reason: 'the video is not moved until the finger lifts',
      );

      await gesture.up();
      await tester.pump();
      expect(controller.value.isDragging, isFalse);
      expect(
        controller.value.position,
        greaterThan(const Duration(seconds: 60)),
      );
      expect(controller.value.playerState, PlayerState.paused);
    });
  });

  group('YoutubeTapZones', () {
    testWidgets('the centre square plays/pauses; the rest of the video only '
        'toggles the controls', (tester) async {
      var video = 0;
      var centre = 0;
      await tester.pumpWidget(
        host(
          SizedBox(
            height: 400,
            child: YoutubeTapZones(
              onTapVideo: () => video++,
              onTapCentre: () => centre++,
            ),
          ),
        ),
      );

      final zones = find.byType(YoutubeTapZones);
      final middle = tester.getCenter(zones);

      await tester.tapAt(middle);
      expect((video, centre), (0, 1));

      await tester.tapAt(middle + const Offset(0, 120));
      expect((video, centre), (1, 1));

      await tester.tapAt(tester.getTopLeft(zones) + const Offset(10, 10));
      expect((video, centre), (2, 1));
    });
  });
}
