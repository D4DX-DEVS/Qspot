import 'package:flutter/material.dart';

import '../../themes/app_fonts.dart';
import '../../themes/home_palette.dart';

/// Small muted heading that groups rows in [AppDrawer].
class AppDrawerSectionLabel extends StatelessWidget {
  const AppDrawerSectionLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final p = HomePalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Text(
        label,
        style: AppFonts.semiBold(color: p.textMuted, fontSize: 13),
      ),
    );
  }
}
