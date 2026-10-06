import 'package:flutter/material.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../../../utils/first_name.dart';

/// Friendly greeting and a short learning prompt at the top of Today.
class TodayGreeting extends StatelessWidget {
  const TodayGreeting({super.key, required this.name});

  /// Full name of the learner; blank falls back to "there".
  final String name;

  /// How far the greeting pushes the card down at normal text size, so the
  /// sky backdrop can grow by the same amount.
  static const double height = 58;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    final first = firstName(name);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Hey ${first.isEmpty ? 'There' : first} 👋',
            style: AppFonts.extraBold(color: palette.text, fontSize: 22),
          ),
          const SizedBox(height: 2),
          Text(
            'Continue your Quran learning journey today.',
            style: AppFonts.regular(color: palette.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
