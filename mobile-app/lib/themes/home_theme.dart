import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_fonts.dart';
import 'home_palette.dart';

/// Material themes for the learner home tabs (Today, Learn, Practice,
/// Progress, Me): logo burgundy on a warm cream page, or on navy in dark.
class HomeTheme {
  HomeTheme._();

  static final ThemeData light = _build(HomePalette.light);
  static final ThemeData dark = _build(HomePalette.dark);

  static ThemeData of(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  static ThemeData _build(HomePalette p) {
    final scheme = ColorScheme(
      brightness: p.brightness,
      primary: p.brand,
      onPrimary: AppColors.onPrimary,
      primaryContainer: p.isDark ? p.brandSoft : const Color(0xFFF8E9EE),
      onPrimaryContainer: p.text,
      secondary: p.coral.color,
      onSecondary: AppColors.onPrimary,
      error: p.error,
      onError: p.isDark ? p.background : AppColors.onPrimary,
      surface: p.background,
      onSurface: p.text,
      onSurfaceVariant: p.textMuted,
      surfaceContainerLowest: p.card,
      surfaceContainerLow: p.card,
      surfaceContainer: p.card,
      surfaceContainerHigh: p.card,
      surfaceContainerHighest: p.cardBorder,
      outline: p.cardBorder,
      outlineVariant: p.cardBorder,
      shadow: AppColors.black,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: AppFonts.family,
      scaffoldBackgroundColor: p.background,
      canvasColor: p.card,
      dividerColor: p.cardBorder,
      // Highlighted row in open menus (e.g. dropdowns).
      focusColor: p.brandSoft,
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        surfaceTintColor: AppColors.transparent,
        foregroundColor: p.text,
        elevation: 2,
        scrolledUnderElevation: 2,
        shadowColor: AppColors.black.withValues(alpha: p.isDark ? 0.6 : 0.25),
        centerTitle: true,
        iconTheme: IconThemeData(color: p.text),
        actionsIconTheme: IconThemeData(color: p.text),
        titleTextStyle: AppFonts.extraBold(color: p.text, fontSize: 21),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.card,
        surfaceTintColor: AppColors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.brand,
        linearTrackColor: p.brandSoft,
        circularTrackColor: p.brandSoft,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: p.brand),
      ),
    );
  }
}
