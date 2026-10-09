import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../../themes/home_palette.dart';
import '../model/youtube_value_extension.dart';

/// The round button centred over a YouTube player: play while paused, pause
/// while playing and replay once the video has ended. While the video loads
/// or buffers, a spinning ring in the app's brand colour takes the icon's
/// place, and the circle turns from solid dark to the app's light surface so
/// the ring stays easy to see over any frame.
///
/// It shows and hides together with the seek bar (see
/// [YoutubeValueState.showsCentreButton]), fading in and out. It never changes
/// size. Purely visual: touches pass through to the tap zones above it.
class YoutubeCentreButton extends StatelessWidget {
  const YoutubeCentreButton({
    super.key,
    required this.controller,
    required this.started,
    required this.controlsShown,
  });

  final YoutubePlayerController controller;

  /// Whether the video has actually played yet (see [YoutubeValueState]).
  final bool started;

  /// Whether the controls were tapped open (see
  /// `VideoReelsScreenProvider.areControlsShown`).
  final bool controlsShown;

  /// Smallest the circle gets (in a phone-width player).
  static const double minDiameter = 72;

  /// YouTube draws its own play / pause button under this one, sized to the
  /// player (about 13% of its width). The circle follows the player width, a
  /// little wider than that, so it always covers YouTube's button completely
  /// and never shows as a second one.
  static const double widthRatio = 0.17;

  /// Width and height of the circle in a player [playerWidth] wide.
  static double diameterFor(double playerWidth) =>
      math.max(minDiameter, playerWidth * widthRatio);

  /// How long a buffer must last before the ring replaces the icon, so a
  /// brief buffer after a tap does not swap the icon for a ring and back.
  static const Duration grace = Duration(milliseconds: 300);

  /// Solid on purpose: YouTube draws its own, smaller play button in the same
  /// spot while paused, and a see-through circle would show it as a second one.
  static const Color discColor = Color(0xFF1F1F23);

  static const Duration _fade = Duration(milliseconds: 150);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, box) => Center(
          child: ValueListenableBuilder<YoutubePlayerValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              if (value.hasError) return const SizedBox.shrink();
              final diameter = diameterFor(
                box.hasBoundedWidth ? box.maxWidth : 0,
              );
              return AnimatedOpacity(
                opacity:
                    value.showsCentreButton(
                      controlsShown: controlsShown,
                      started: started,
                    )
                    ? 1
                    : 0,
                duration: _fade,
                child: SizedBox.square(
                  dimension: diameter,
                  child: _circle(context, value, diameter),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _circle(
    BuildContext context,
    YoutubePlayerValue value,
    double diameter,
  ) {
    final icon = Icon(
      _iconFor(value.playerState),
      color: Colors.white,
      size: diameter * 0.55,
    );
    if (!value.isLoading(started: started)) {
      return _disc(discColor, icon);
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
        Color.lerp(discColor, palette.card, ring)!,
        Stack(
          alignment: Alignment.center,
          children: [
            Opacity(opacity: 1 - ring, child: icon),
            Opacity(
              opacity: ring,
              child: SizedBox.square(
                dimension: diameter * 0.45,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
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
    PlayerState.ended => LucideIcons.rotateCcw,
    PlayerState.playing || PlayerState.buffering => LucideIcons.pause,
    _ => LucideIcons.play,
  };
}
