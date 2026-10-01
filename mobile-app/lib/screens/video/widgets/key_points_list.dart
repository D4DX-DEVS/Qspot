import 'package:flutter/material.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';

/// "KEY POINTS" label over a list of ticked points.
class KeyPointsList extends StatelessWidget {
  const KeyPointsList({super.key, required this.points});

  final List<String> points;

  @override
  Widget build(BuildContext context) {
    final p = HomePalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'KEY POINTS',
          style: AppFonts.bold(
            color: p.textMuted,
            fontSize: 11.5,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        for (final point in points)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(
                    color: p.brandSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check, size: 13, color: p.brand),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    point,
                    style: AppFonts.regular(
                      color: p.text,
                      fontSize: 15,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
