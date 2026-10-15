import 'dart:math';

import 'package:flutter/material.dart';

/// Stacks [children] in one column on a phone and in as many columns as fit
/// on a wider screen. Cards in a row share the height of the tallest, so a
/// card is never cut to fit a fixed cell.
class AdaptiveCardColumns extends StatelessWidget {
  const AdaptiveCardColumns({
    super.key,
    required this.children,
    this.minColumnWidth = 340,
    this.spacing = 16,
  });

  final List<Widget> children;

  /// A column is never narrower than this.
  final double minColumnWidth;

  /// Gap between columns and between rows.
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fitting =
            ((constraints.maxWidth + spacing) / (minColumnWidth + spacing))
                .floor();
        final columns = fitting.clamp(1, max(1, children.length)).toInt();
        final rows = (children.length / columns).ceil();

        return Column(
          children: [
            for (var row = 0; row < rows; row++)
              Padding(
                padding: EdgeInsets.only(top: row == 0 ? 0 : spacing),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var column = 0; column < columns; column++) ...[
                        if (column > 0) SizedBox(width: spacing),
                        Expanded(
                          child: row * columns + column < children.length
                              ? children[row * columns + column]
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
