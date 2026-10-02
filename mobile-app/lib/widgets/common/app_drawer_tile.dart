import 'package:flutter/material.dart';

import '../../themes/app_fonts.dart';
import '../../themes/home_palette.dart';

/// One full-width tappable row in [AppDrawer]: icon, label. Pressing it
/// washes the row in the brand tint. [isDestructive] paints it in the
/// theme's error colour (e.g. Logout).
class AppDrawerTile extends StatelessWidget {
  const AppDrawerTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final p = HomePalette.of(context);
    final color = isDestructive ? p.error : p.text;
    return InkWell(
      onTap: onTap,
      highlightColor: p.brand.withValues(alpha: 0.12),
      splashColor: p.brand.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: AppFonts.medium(color: color, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
