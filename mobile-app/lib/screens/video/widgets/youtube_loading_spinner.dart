import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import 'video_loading_spinner.dart';

/// [VideoLoadingSpinner] driven by a YouTube player: shown until the player is
/// ready and again whenever it buffers, at the start or in the middle of a
/// video. It is hidden if the player reports an error.
class YoutubeLoadingSpinner extends StatelessWidget {
  const YoutubeLoadingSpinner({super.key, required this.controller});

  final YoutubePlayerController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<YoutubePlayerValue>(
      valueListenable: controller,
      builder: (_, value, _) => VideoLoadingSpinner(
        loading:
            !value.hasError &&
            (!value.isReady || value.playerState == PlayerState.buffering),
      ),
    );
  }
}
