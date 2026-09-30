import 'package:flutter/material.dart';

import '../../themes/accent_tone.dart';

/// Icon on a soft tinted square (or circle) in the given [tone].
class SoftIconTile extends StatelessWidget {
  const SoftIconTile({
    super.key,
    required this.icon,
    required this.tone,
    this.size = 44,
    this.iconSize,
    this.circle = false,
  });

  final IconData icon;
  final AccentTone tone;
  final double size;
  final double? iconSize;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tone.soft,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(size * 0.3),
      ),
      child: Icon(icon, color: tone.color, size: iconSize ?? size * 0.5),
    );
  }
}
