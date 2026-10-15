import 'package:flutter/material.dart';

/// Two-column list of cards whose rows are as tall as their tallest card, so
/// text inside a card never has to be cut to fit a fixed cell size (which is
/// what a plain `GridView` forces).
class VideoGrid extends StatelessWidget {
  const VideoGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding = EdgeInsets.zero,
    this.spacing = 16,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final EdgeInsetsGeometry padding;

  /// Gap between the two columns and between rows.
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding,
      itemCount: (itemCount + 1) ~/ 2,
      itemBuilder: (context, row) {
        final first = row * 2;
        final second = first + 1;
        return Padding(
          padding: EdgeInsets.only(top: row == 0 ? 0 : spacing),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: itemBuilder(context, first)),
                SizedBox(width: spacing),
                Expanded(
                  child: second < itemCount
                      ? itemBuilder(context, second)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
