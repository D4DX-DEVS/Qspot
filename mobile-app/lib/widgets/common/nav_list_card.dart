import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../themes/accent_tone.dart';
import '../../themes/app_fonts.dart';
import 'soft_icon_tile.dart';
import 'surface_card.dart';

/// Tappable row card: tinted icon, title, optional subtitle and a chevron.
/// Title and subtitle wrap so they are always fully visible.
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
  });

  final IconData icon;
  final AccentTone tone;
  final String title;
  final String? subtitle;

  /// Defaults to the muted text colour.
  final Color? subtitleColor;
  final VoidCallback onTap;
  final bool circleIcon;

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
                    style: AppFonts.semiBold(
                      color: scheme.onSurface,
                      fontSize: 15,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
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
              LucideIcons.chevronRight,
              color: scheme.onSurfaceVariant,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
