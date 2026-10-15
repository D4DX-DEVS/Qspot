import 'package:flutter/material.dart';

import '../../themes/app_fonts.dart';

/// Asks the user to confirm logging out. Resolves to true only on "Logout".
Future<bool> showLogoutConfirmDialog(BuildContext context) async {
  final scheme = Theme.of(context).colorScheme;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(
        'Logout',
        style: AppFonts.bold(color: scheme.onSurface, fontSize: 20),
      ),
      content: Text(
        'Are you sure you want to logout?',
        style: AppFonts.regular(color: scheme.onSurfaceVariant, fontSize: 16),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: TextButton.styleFrom(foregroundColor: scheme.error),
          child: const Text('Logout'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
