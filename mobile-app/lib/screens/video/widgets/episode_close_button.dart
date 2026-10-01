import 'package:flutter/material.dart';

import '../../../widgets/common/circle_icon_action.dart';

/// Round close button that pops the current sheet.
class EpisodeCloseButton extends StatelessWidget {
  const EpisodeCloseButton({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) => CircleIconAction(
    icon: Icons.close_rounded,
    tooltip: 'Close',
    size: size,
    onPressed: () => Navigator.of(context).pop(),
  );
}
