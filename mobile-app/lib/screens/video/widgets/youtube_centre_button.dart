import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../../themes/home_palette.dart';
import '../model/youtube_value_extension.dart';

/// The round button centred over a YouTube player: play while paused, pause
/// while playing and replay once the video has ended. While the video loads
/// or buffers, a spinning ring in the app's brand colour takes the icon's
/// place, and the circle turns from dark glass to the app's light surface so
/// the ring stays easy to see over any frame.
///
/// It is always on screen and does not depend on whether the seek bar is
/// showing. It never changes size. Purely visual: touches pass through to the
/// tap zones above it.
class YoutubeCentreButton extends StatelessWidget {
  const YoutubeCentreButton({
    super.key,
    required this.controller,
    required this.started,
  });

  final YoutubePlayerController controller;

  /// Whether the video has actually played yet (see [YoutubeValueState]).
  final bool started;

  /// Width and height of the circle: a 56 icon with 12 of padding all round.
  static const double diameter = 80;

  /// How long a buffer must last before the ring replaces the icon, so a
  /// brief buffer after a tap does not swap the icon for a ring and back.
  static const Duration grace = Duration(milliseconds: 300);

  static const Duration _fade = Duration(milliseconds: 150);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: ValueListenableBuilder<YoutubePlayerValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            if (value.hasError) return const SizedBox.shrink();
            return SizedBox.square(
              dimension: diameter,
              child: _circle(context, value),
            );
          },
        ),
      ),
    );
  }

  Widget _circle(BuildContext context, YoutubePlayerValue value) {
    final icon = Icon(
      _iconFor(value.playerState),
      color: Colors.white,
      size: 56,
    );
    if (!value.isLoading(started: started)) {
      return _disc(Colors.black45, icon);
    }

    final palette = HomePalette.of(context);

    // Before the player is ready it is certainly loading, so the ring shows
    // straight away; after that the icon holds for the grace period first.
    final hold = value.isReady ? grace : Duration.zero;
    final total = hold + _fade;
    return TweenAnimationBuilder<double>(
      key: ValueKey(value.isReady),
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(hold.inMilliseconds / total.inMilliseconds, 1),
      builder: (_, ring, _) => _disc(
        Color.lerp(Colors.black45, palette.card, ring)!,
        Stack(
          alignment: Alignment.center,
          children: [
            Opacity(opacity: 1 - ring, child: icon),
            Opacity(
              opacity: ring,
              child: SizedBox.square(
                dimension: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3.5,
                  color: palette.brand,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _disc(Color color, Widget child) => DecoratedBox(
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    child: Center(child: child),
  );

  IconData _iconFor(PlayerState state) => switch (state) {
    PlayerState.ended => Icons.replay_rounded,
    PlayerState.playing || PlayerState.buffering => Icons.pause_rounded,
    _ => Icons.play_arrow_rounded,
  };
}
