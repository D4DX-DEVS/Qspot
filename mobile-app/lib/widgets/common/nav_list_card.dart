import 'package:flutter/material.dart';

import '../../themes/accent_tone.dart';
import '../../themes/app_fonts.dart';
import 'soft_icon_tile.dart';
import 'surface_card.dart';

/// Tappable row card: tinted icon, title, one-line subtitle and a chevron.
class NavListCard extends StatelessWidget {
  const NavListCard({
    super.key,
    required this.icon,
    required this.tone,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.subtitleColor,
    this.circleIcon = false,
    this.subtitleLines = 1,
  });

  final IconData icon;
  final AccentTone tone;
  final String title;
  final String? subtitle;

  /// Defaults to the muted text colour.
  final Color? subtitleColor;
  final VoidCallback onTap;
  final bool circleIcon;
  final int subtitleLines;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      child: SurfaceCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            SoftIconTile(icon: icon, tone: tone, size: 46, circle: circleIcon),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.semiBold(
                      color: scheme.onSurface,
                      fontSize: 15,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      maxLines: subtitleLines,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.regular(
                        color: subtitleColor ?? scheme.onSurfaceVariant,
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: scheme.onSurfaceVariant,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
