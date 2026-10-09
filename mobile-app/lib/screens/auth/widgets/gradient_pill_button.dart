import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../themes/app_colors.dart';
import '../../../themes/app_fonts.dart';
import '../../../widgets/animation/pressable_scale.dart';

/// Full-width burgundy-to-coral pill with a centred label and a white arrow
/// badge on the right. Passing a null [onPressed] shows it faded out.
class GradientPillButton extends StatelessWidget {
  const GradientPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      // Solid page-coloured backing so the faded (disabled) state never shows
      // artwork through the button.
      child: PressableScale(
        enabled: enabled,
        haptic: true,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: Theme.of(context).colorScheme.surface,
            shape: const StadiumBorder(),
          ),
          child: AnimatedOpacity(
            opacity: onPressed == null && !isLoading ? 0.5 : 1,
            duration: const Duration(milliseconds: 200),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.authButtonGradient,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.authBrand.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: enabled ? onPressed : null,
                  customBorder: const StadiumBorder(),
                  child: SizedBox(
                    height: 58,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (isLoading)
                          const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.onPrimary,
                            ),
                          )
                        else
                          // Clear of the arrow circle; shrinks if the label is long.
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 56),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                label,
                                style: AppFonts.semiBold(
                                  color: AppColors.onPrimary,
                                  fontSize: 17,
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          right: 8,
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: const BoxDecoration(
                              color: AppColors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.arrowRight,
                              color: AppColors.authBrand,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
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
