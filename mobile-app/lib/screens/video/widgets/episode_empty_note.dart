import 'package:flutter/material.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';

/// Centered quiet message for an empty episode tab.
class EpisodeEmptyNote extends StatelessWidget {
  const EpisodeEmptyNote({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final p = HomePalette.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: AppFonts.regular(
            color: p.textMuted,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}
