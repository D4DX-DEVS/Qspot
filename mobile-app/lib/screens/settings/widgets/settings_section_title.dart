import 'package:flutter/material.dart';

import '../../../themes/app_fonts.dart';

/// Section label for the settings page: a small outlined icon and a bold
/// title.
class SettingsSectionTitle extends StatelessWidget {
  const SettingsSectionTitle({
    super.key,
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
      child: Row(
        children: [
          Icon(icon, color: scheme.primary, size: 22),
          const SizedBox(width: 10),
          Text(
            title,
            style: AppFonts.bold(color: scheme.onSurface, fontSize: 17),
          ),
        ],
      ),
    );
  }
}
