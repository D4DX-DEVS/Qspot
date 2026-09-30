import 'package:flutter/material.dart';

import '../../../themes/accent_tone.dart';
import '../../../themes/app_fonts.dart';
import '../../../widgets/common/soft_icon_tile.dart';
import '../../../widgets/common/surface_card.dart';

/// One recent-activity entry: tinted icon, kind label, title, detail line
/// and an optional date on the right.
class ActivityTile extends StatelessWidget {
  const ActivityTile({
    super.key,
    required this.icon,
    required this.tone,
    required this.kind,
    required this.title,
    required this.detail,
    this.dateLabel,
  });

  final IconData icon;
  final AccentTone tone;
  final String kind;
  final String title;
  final String detail;
  final String? dateLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurfaceVariant;
    return SurfaceCard(
      radius: 16,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SoftIconTile(icon: icon, tone: tone, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(kind, style: AppFonts.semiBold(color: muted, fontSize: 10.5)),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.bold(color: scheme.onSurface, fontSize: 13.5),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: AppFonts.regular(color: muted, fontSize: 12),
                ),
              ],
            ),
          ),
          if (dateLabel != null) ...[
            const SizedBox(width: 8),
            Text(
              dateLabel!,
              style: AppFonts.regular(color: muted, fontSize: 10.5),
            ),
          ],
        ],
      ),
    );
  }
}
