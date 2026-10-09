import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qspot/screens/video/widgets/video_loading_spinner.dart';
import 'package:qspot/themes/home_palette.dart';
import 'package:qspot/screens/video/widgets/youtube_loading_spinner.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

Widget host(Widget child) =>
    MaterialApp(home: SizedBox(width: 300, height: 400, child: child));

void main() {
  group('VideoLoadingSpinner', () {
    testWidgets('shows a spinner only while loading', (tester) async {
      await tester.pumpWidget(host(const VideoLoadingSpinner(loading: true)));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpWidget(host(const VideoLoadingSpinner(loading: false)));
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets(
      'waits before showing, so a quick buffering blip is invisible',
      (tester) async {
        double opacity() => tester
            .widget<Opacity>(
              find
                  .descendant(
                    of: find.byType(VideoLoadingSpinner),
                    matching: find.byType(Opacity),
                  )
                  .first,
            )
            .opacity;

        await tester.pumpWidget(host(const VideoLoadingSpinner(loading: true)));
        expect(opacity(), 0);

        await tester.pump(const Duration(milliseconds: 250));
        expect(opacity(), 0, reason: 'still inside the grace period');

        await tester.pump(const Duration(milliseconds: 400));
        expect(opacity(), 1);
      },
    );

    testWidgets('the ring is the app brand colour on the app surface colour', (
      tester,
    ) async {
      await tester.pumpWidget(host(const VideoLoadingSpinner(loading: true)));

      expect(
        tester
            .widget<CircularProgressIndicator>(
              find.byType(CircularProgressIndicator),
            )
            .color,
        HomePalette.light.brand,
      );
      final disc = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(VideoLoadingSpinner),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect((disc.decoration as BoxDecoration).color, HomePalette.light.card);
    });

    testWidgets('lets touches through to the player underneath', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        host(
          Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(onTap: () => taps++),
              const VideoLoadingSpinner(loading: true),
            ],
          ),
        ),
      );

      await tester.tapAt(const Offset(150, 200));
      expect(taps, 1);
    });
  });

  group('YoutubeLoadingSpinner', () {
    late YoutubePlayerController controller;

    setUp(() {
      controller = YoutubePlayerController(initialVideoId: 'abcdefghijk');
    });

    tearDown(() => controller.dispose());

    Future<void> pumpWith(
      WidgetTester tester, {
      bool isReady = false,
      PlayerState state = PlayerState.unknown,
      int errorCode = 0,
    }) async {
      controller.updateValue(
        controller.value.copyWith(
          isReady: isReady,
          playerState: state,
          errorCode: errorCode,
        ),
      );
      await tester.pumpWidget(
        host(YoutubeLoadingSpinner(controller: controller)),
      );
      await tester.pump(const Duration(milliseconds: 200));
    }

    final spinner = find.byType(CircularProgressIndicator);

    testWidgets('spins until the player is ready', (tester) async {
      await pumpWith(tester);
      expect(spinner, findsOneWidget);
    });

    testWidgets('stops once ready and waiting for the first tap', (
      tester,
    ) async {
      await pumpWith(tester, isReady: true, state: PlayerState.cued);
      expect(spinner, findsNothing);
    });

    testWidgets('spins again whenever the video buffers', (tester) async {
      await pumpWith(tester, isReady: true, state: PlayerState.playing);
      expect(spinner, findsNothing);

      controller.updateValue(
        controller.value.copyWith(playerState: PlayerState.buffering),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(spinner, findsOneWidget);

      controller.updateValue(
        controller.value.copyWith(playerState: PlayerState.playing),
      );
      await tester.pumpAndSettle();
      expect(spinner, findsNothing);
    });

    testWidgets('does not spin when the player reports an error', (
      tester,
    ) async {
      await pumpWith(tester, errorCode: 2);
      expect(spinner, findsNothing);
    });
  });
}
