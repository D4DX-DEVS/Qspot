import 'package:flutter/material.dart';

import '../../themes/app_colors.dart';
import '../../themes/app_fonts.dart';
import '../../themes/app_theme.dart';

/// The one way to show a snack bar in the app.
///
/// Colour by outcome:
/// - success: [AppColors.success] (green)
/// - error: [AppColors.danger] (red)
/// - warning: [AppColors.warningOrange] (orange)
///
/// Always floating with rounded corners and white text, so it reads the same
/// in light and dark mode. A new message replaces the one on screen.
class AppSnackBar {
  AppSnackBar._();

  static const Duration defaultDuration = Duration(seconds: 3);

  static void show(
    BuildContext context, {
    required String message,
    required Color color,
    Duration duration = defaultDuration,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppFonts.medium(color: AppColors.onPrimary),
        ),
        backgroundColor: color,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        action: actionLabel == null || onAction == null
            ? null
            : SnackBarAction(
                label: actionLabel,
                textColor: AppColors.onPrimary,
                onPressed: onAction,
              ),
      ),
    );
  }
}
