import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../themes/app_colors.dart';
import '../../themes/app_fonts.dart';
import '../animation/pressable_scale.dart';

/// Compact gold pill (icon, label, arrow) for the main action on a
/// burgundy `GradientCard`.
class GoldPillButton extends StatelessWidget {
  const GoldPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  // Deep burgundy ink stays readable on gold in light and dark.
  static const Color _ink = AppColors.authLightFieldIcon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: PressableScale(
        haptic: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppColors.homeGoldGradient,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.18),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onPressed,
              customBorder: const StadiumBorder(),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: _ink, size: 18),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          style: AppFonts.semiBold(color: _ink, fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(LucideIcons.arrowRight, color: _ink, size: 17),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
