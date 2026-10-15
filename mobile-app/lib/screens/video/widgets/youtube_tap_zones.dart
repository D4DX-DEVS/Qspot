import 'package:flutter/material.dart';

/// Invisible touch areas over a video: the whole video reveals or hides the
/// controls, and a square at its centre (where the play / pause button is)
/// plays or pauses. The centre works whether or not its icon is showing.
class YoutubeTapZones extends StatelessWidget {
  const YoutubeTapZones({
    super.key,
    required this.onTapVideo,
    required this.onTapCentre,
    this.centreSize = 96,
  });

  final VoidCallback onTapVideo;
  final VoidCallback onTapCentre;
  final double centreSize;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTapVideo),
        Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTapCentre,
            child: SizedBox.square(dimension: centreSize),
          ),
        ),
      ],
    );
  }
}
