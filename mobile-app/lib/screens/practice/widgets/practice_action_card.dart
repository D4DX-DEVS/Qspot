import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../themes/accent_tone.dart';
import '../../../themes/app_fonts.dart';
import '../../../widgets/common/soft_icon_tile.dart';
import '../../../widgets/common/surface_card.dart';
import '../../../widgets/common/tinted_pill_link.dart';

/// Tappable Practice destination: tinted icon, title, short explanation and
/// a pill naming the action, all in one accent [tone].
class PracticeActionCard extends StatelessWidget {
  const PracticeActionCard({
    super.key,
    required this.icon,
    required this.tone,
    required this.title,
    required this.body,
    required this.action,
    required this.onTap,
  });

  final IconData icon;
  final AccentTone tone;
  final String title;
  final String body;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: '$title. $body',
      excludeSemantics: true,
      child: SurfaceCard(
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(16, 18, 14, 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SoftIconTile(icon: icon, tone: tone, size: 52),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppFonts.bold(color: scheme.onSurface, fontSize: 17),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    body,
                    style: AppFonts.regular(
                      color: scheme.onSurfaceVariant,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TintedPillLink(label: action, tone: tone),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(LucideIcons.arrowRight, color: scheme.onSurface, size: 22),
          ],
        ),
      ),
    );
  }
}
