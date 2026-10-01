import 'package:flutter/material.dart';

import '../../../themes/accent_tone.dart';
import '../../../themes/app_fonts.dart';
import '../../../widgets/common/soft_icon_tile.dart';

/// A row inside a settings card: tinted icon, title, optional subtitle and a
/// trailing widget (a chevron by default). Tappable when [onTap] is set.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.tone,
    required this.title,
    this.subtitle,
    this.subtitleStyle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final AccentTone tone;
  final String title;
  final String? subtitle;

  /// Overrides the muted subtitle look, e.g. a bold brand-coloured value.
  final TextStyle? subtitleStyle;

  /// Defaults to a chevron when the row is tappable.
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final end =
        trailing ??
        (onTap == null
            ? null
            : Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurfaceVariant,
                size: 22,
              ));
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SoftIconTile(icon: icon, tone: tone, size: 44),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppFonts.semiBold(
                      color: scheme.onSurface,
                      fontSize: 15,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style:
                          subtitleStyle ??
                          AppFonts.regular(
                            color: scheme.onSurfaceVariant,
                            fontSize: 12.5,
                            height: 1.3,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            if (end != null) ...[const SizedBox(width: 8), end],
          ],
        ),
      ),
    );
  }
}
