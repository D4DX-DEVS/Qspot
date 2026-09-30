import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../themes/app_colors.dart';
import '../../../themes/home_theme.dart';

/// Applies the light or dark home theme to [child], following the phone's
/// light/dark setting, and keeps the status bar icons readable on top of it.
class HomeThemeScope extends StatelessWidget {
  const HomeThemeScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final isDark = brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
        // Android reads the icon brightness, iOS reads the bar brightness.
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: Theme(data: HomeTheme.of(brightness), child: child),
    );
  }
}
