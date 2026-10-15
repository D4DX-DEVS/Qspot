import 'package:flutter/material.dart';

import '../../themes/app_fonts.dart';
import '../animation/motion.dart';

/// Section title with an optional emoji, an optional intro line and an
/// optional trailing link (e.g. "See all"). Headers with and without a link
/// share one height.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.emoji,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;

  /// Shown before the title. Decorative, so screen readers skip it.
  final String? emoji;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 40),
          child: Row(
            children: [
              if (emoji != null) ...[
                ExcludeSemantics(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: Motion.slow,
                    curve: Curves.elasticOut,
                    builder: (_, scale, child) =>
                        Transform.scale(scale: scale, child: child),
                    child: Text(emoji!, style: const TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: AppFonts.bold(color: scheme.onSurface, fontSize: 18),
                ),
              ),
              if (actionLabel != null && onAction != null)
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    foregroundColor: scheme.onSurface,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: const Size(48, 48),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    actionLabel!,
                    style: AppFonts.medium(fontSize: 14),
                  ),
                ),
            ],
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: AppFonts.regular(
              color: scheme.onSurfaceVariant,
              fontSize: 13,
              height: 1.45,
            ),
          ),
      ],
    );
  }
}
