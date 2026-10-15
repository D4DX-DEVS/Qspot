import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../themes/app_fonts.dart';
import '../../themes/app_theme.dart';
import '../../themes/home_palette.dart';
import '../animation/motion.dart';

/// A section heading with a down arrow. Tapping the heading shows or hides
/// [child] below it. The caller keeps the open state, so it survives
/// rebuilds and can be read elsewhere.
class CollapsibleSection extends StatelessWidget {
  const CollapsibleSection({
    super.key,
    required this.title,
    required this.expanded,
    required this.onToggle,
    required this.child,
  });

  final String title;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    final duration = Motion.reduced(context) ? Duration.zero : Motion.medium;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: expanded,
          excludeSemantics: true,
          onTap: onToggle,
          label: title,
          child: InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppFonts.semiBold(
                        color: palette.text,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: duration,
                    curve: Motion.smooth,
                    child: Icon(
                      LucideIcons.chevronDown,
                      color: palette.textMuted,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: duration,
          curve: Motion.smooth,
          alignment: Alignment.topCenter,
          child: expanded
              ? Padding(
                  padding: const EdgeInsets.only(top: AppTheme.paddingSmall),
                  child: child,
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
