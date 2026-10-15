import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../model/youtube_value_extension.dart';
import '../provider/youtube_seek_provider.dart';

/// Position, seek bar, time left, playback speed and full screen for a YouTube
/// player.
///
/// Shown while the video is paused or finished, and while it plays only when
/// the controls were tapped open. It always keeps its height so the layout
/// around it never jumps, and while it is hidden it takes no touches so a tap
/// there reaches the video instead.
class YoutubeSeekBar extends StatelessWidget {
  const YoutubeSeekBar({
    super.key,
    required this.controller,
    required this.controlsShown,
  });

  final YoutubePlayerController controller;
  final bool controlsShown;

  static const double height = 40;

  // Fixed widths and tabular digits keep the bar from shifting as the times
  // change while it is dragged.
  static const double _currentWidth = 44;
  static const double _remainingWidth = 52;
  static const TextStyle _timeStyle = TextStyle(
    color: Colors.white,
    fontSize: 12,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<YoutubeSeekProvider>(
      create: (_) => YoutubeSeekProvider(controller),
      child: SizedBox(
        height: height,
        child: Consumer<YoutubeSeekProvider>(
          // Offstage switches it on and off instantly (no fade) and, while it
          // is off, it neither paints nor takes touches.
          builder: (_, seek, _) => Offstage(
            offstage: !seek.isVisible(controlsShown: controlsShown),
            child: _bar(seek),
          ),
        ),
      ),
    );
  }

  Widget _bar(YoutubeSeekProvider seek) {
    return Row(
      children: [
        SizedBox(
          width: _currentWidth,
          child: Text(seek.position.clockText, style: _timeStyle),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 2.5,
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white24,
              secondaryActiveTrackColor: Colors.white38,
              thumbColor: Colors.white,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 6,
                elevation: 0,
                pressedElevation: 0,
              ),
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(
              value: seek.fraction,
              secondaryTrackValue: seek.buffered,
              onChangeStart: seek.canSeek ? seek.startDrag : null,
              onChanged: seek.canSeek ? seek.updateDrag : null,
              onChangeEnd: seek.canSeek ? seek.endDrag : null,
            ),
          ),
        ),
        SizedBox(
          width: _remainingWidth,
          child: Text(
            '-${seek.remaining.clockText}',
            textAlign: TextAlign.right,
            style: _timeStyle,
          ),
        ),
        PlaybackSpeedButton(controller: controller),
        FullScreenButton(controller: controller),
      ],
    );
  }
}
