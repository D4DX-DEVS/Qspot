import 'package:flutter/material.dart';

import '../../../themes/app_fonts.dart';

/// Title with a "done/total" count above a rounded progress bar.
class MasteryProgressRow extends StatelessWidget {
  const MasteryProgressRow({
    super.key,
    required this.title,
    required this.completed,
    required this.total,
    required this.percent,
  });

  final String title;
  final int completed;
  final int total;

  /// 0..1.
  final double percent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.semiBold(
                  color: scheme.onSurface,
                  fontSize: 13.5,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '$completed/$total',
              style: AppFonts.semiBold(
                color: scheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: scheme.primaryContainer,
            color: scheme.primary,
          ),
        ),
      ],
    );
  }
}
