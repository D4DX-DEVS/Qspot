import 'package:flutter/material.dart';

import '../../../themes/app_fonts.dart';

/// Bold headline with one highlighted word ([accent]) and an optional
/// muted [subtitle] underneath.
class AuthHeadline extends StatelessWidget {
  const AuthHeadline({
    super.key,
    required this.title,
    this.accent = '',
    this.trailing = '',
    this.subtitle,
    this.textAlign = TextAlign.start,
    this.fontSize = 28,
    this.subtitleFontSize = 15,
  });

  final String title;
  final String accent;
  final String trailing;
  final String? subtitle;
  final TextAlign textAlign;
  final double fontSize;
  final double subtitleFontSize;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: title),
              TextSpan(
                text: accent,
                style: TextStyle(color: colors.primary),
              ),
              TextSpan(text: trailing),
            ],
          ),
          textAlign: textAlign,
          style: AppFonts.bold(
            color: colors.onSurface,
            fontSize: fontSize,
            height: 1.22,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 12),
          Text(
            subtitle!,
            textAlign: textAlign,
            style: AppFonts.regular(
              color: colors.onSurfaceVariant,
              fontSize: subtitleFontSize,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }
}
