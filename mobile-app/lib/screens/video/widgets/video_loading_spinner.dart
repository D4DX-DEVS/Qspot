import 'package:flutter/material.dart';

import '../../../themes/home_palette.dart';

/// Spinner centred over a video while it is loading or buffering.
///
/// It waits a moment before showing, so the brief buffering blip that follows
/// a play or seek never flashes it; real loading shows it after that grace
/// period. The ring is the app's brand colour on the app's light surface colour,
/// a solid disc, so it stays visible on any thumbnail or frame and hides a
/// player's own play icon underneath. Nothing is built while [loading] is
/// false, and touches always pass through to the player.
class VideoLoadingSpinner extends StatelessWidget {
  const VideoLoadingSpinner({super.key, required this.loading});

  final bool loading;

  /// How long loading must last before the spinner starts to appear.
  static const Duration grace = Duration(milliseconds: 300);

  /// The grace period plus a 150 ms fade-in.
  static const Duration _total = Duration(milliseconds: 450);

  @override
  Widget build(BuildContext context) {
    if (!loading) return const SizedBox.shrink();

    final palette = HomePalette.of(context);
    return IgnorePointer(
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: _total,
          curve: Interval(grace.inMilliseconds / _total.inMilliseconds, 1),
          builder: (_, opacity, child) =>
              Opacity(opacity: opacity, child: child),
          child: SizedBox(
            width: 72,
            height: 72,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: palette.card,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: palette.brand,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
