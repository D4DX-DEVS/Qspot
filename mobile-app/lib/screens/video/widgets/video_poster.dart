import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Thumbnail shown in place of a video while its player starts up.
///
/// The image is normally already cached from the card the learner tapped, so
/// it appears on the first frame; with no thumbnail it is plain black. It
/// never shows a spinner. Set [visible] to false to fade it out and let touches
/// through to the player underneath.
class VideoPoster extends StatelessWidget {
  const VideoPoster({
    super.key,
    required this.thumbnailUrl,
    this.visible = true,
  });

  final String thumbnailUrl;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 250),
        child: ColoredBox(
          color: Colors.black,
          child: thumbnailUrl.isEmpty
              ? const SizedBox.expand()
              : CachedNetworkImage(
                  imageUrl: thumbnailUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  fadeInDuration: Duration.zero,
                  fadeOutDuration: Duration.zero,
                  errorWidget: (_, _, _) => const SizedBox.shrink(),
                ),
        ),
      ),
    );
  }
}
