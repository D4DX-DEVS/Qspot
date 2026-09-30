import 'package:flutter/material.dart';

import '../../themes/app_fonts.dart';
import 'surface_card.dart';

/// Small card with a coloured icon over a bold value and a short label.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: '$value $label',
      excludeSemantics: true,
      child: SurfaceCard(
        radius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.bold(color: scheme.onSurface, fontSize: 18),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.regular(
                  color: scheme.onSurfaceVariant,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
