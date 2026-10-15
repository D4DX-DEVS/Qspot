import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

/// Default YouTube bottom bar that ignores taps while the controls are hidden,
/// so a tap there only reveals the controls instead of firing a hidden button.
class YoutubeBottomActions extends StatelessWidget {
  final YoutubePlayerController controller;
  final ProgressBarColors? progressColors;

  const YoutubeBottomActions({
    super.key,
    required this.controller,
    this.progressColors,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<YoutubePlayerValue>(
      valueListenable: controller,
      builder: (context, value, child) =>
          IgnorePointer(ignoring: !value.isControlsVisible, child: child),
      child: Row(
        children: [
          const SizedBox(width: 14.0),
          const CurrentPosition(),
          const SizedBox(width: 8.0),
          ProgressBar(isExpanded: true, colors: progressColors),
          const RemainingDuration(),
          const PlaybackSpeedButton(),
          const FullScreenButton(),
        ],
      ),
    );
  }
}
