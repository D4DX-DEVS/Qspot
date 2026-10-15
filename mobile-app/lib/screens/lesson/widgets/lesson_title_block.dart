import 'package:flutter/material.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';

/// "LESSON 3 OF 8", the lesson's title, and where it sits and when it came.
class LessonTitleBlock extends StatelessWidget {
  const LessonTitleBlock({
    super.key,
    required this.title,
    required this.subtitle,
    this.positionLabel,
  });

  final String title;
  final String subtitle;
  final String? positionLabel;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (positionLabel != null) ...[
          Text(
            positionLabel!.toUpperCase(),
            style: AppFonts.bold(
              color: palette.brand,
              fontSize: 11.5,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 3),
        ],
        Text(
          title,
          style: AppFonts.bold(color: palette.text, fontSize: 20, height: 1.25),
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: AppFonts.regular(color: palette.textMuted, fontSize: 12.5),
          ),
        ],
      ],
    );
  }
}
