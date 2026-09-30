import 'package:flutter/material.dart';

import '../../themes/app_colors.dart';
import '../../themes/app_fonts.dart';
import '../../utils/name_initials.dart';

/// Round avatar showing the initials of [name] on a gradient (or solid
/// [color]) fill, with an optional white ring.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    super.key,
    required this.name,
    this.size = 44,
    this.gradient,
    this.color,
    this.ringWidth = 2,
  });

  final String name;
  final double size;
  final Gradient? gradient;

  /// Used when [gradient] is null.
  final Color? color;

  /// 0 hides the ring.
  final double ringWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient,
        color: gradient == null
            ? color ?? Theme.of(context).colorScheme.primary
            : null,
        border: ringWidth > 0
            ? Border.all(color: AppColors.white, width: ringWidth)
            : null,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.14),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        nameInitials(name),
        style: AppFonts.bold(color: AppColors.white, fontSize: size * 0.36),
      ),
    );
  }
}
