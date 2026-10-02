import 'package:flutter/material.dart';

import '../../../themes/app_fonts.dart';
import '../../../widgets/animation/count_up_text.dart';
import '../../../widgets/animation/motion.dart';
import '../../../widgets/common/surface_card.dart';

/// Card with a percentage ring beside a title, a detail line and an
/// optional highlighted note (e.g. "1 in progress").
class MasteryRingCard extends StatelessWidget {
  const MasteryRingCard({
    super.key,
    required this.percent,
    required this.title,
    required this.detail,
    this.highlight,
    this.highlightColor,
  });

  /// 0..1.
  final double percent;
  final String title;
  final String detail;
  final String? highlight;

  /// Defaults to the theme's secondary colour.
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final value = percent.clamp(0.0, 1.0);
    return SurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 84,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Sweeps up from empty once, in step with the count-up below.
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: value),
                  duration: Motion.reduced(context)
                      ? Duration.zero
                      : Motion.slow,
                  curve: Motion.smooth,
                  builder: (_, sweep, __) => CircularProgressIndicator(
                    value: sweep,
                    strokeWidth: 8,
                    strokeCap: StrokeCap.round,
                    backgroundColor: scheme.primaryContainer,
                    color: scheme.primary,
                  ),
                ),
                Center(
                  child: CountUpText(
                    '${(value * 100).round()}%',
                    style: AppFonts.bold(color: scheme.onSurface, fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppFonts.bold(color: scheme.onSurface, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  detail,
                  style: AppFonts.regular(
                    color: scheme.onSurfaceVariant,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                if (highlight != null) ...[
                  const SizedBox(height: 7),
                  Text(
                    highlight!,
                    style: AppFonts.semiBold(
                      color: highlightColor ?? scheme.secondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
