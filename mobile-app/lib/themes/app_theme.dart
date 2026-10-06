import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_fonts.dart';

/// QSPOT learner theme: an ocean-teal learning anchor with coral and amber
/// feedback accents on a quiet blue-white canvas.
class AppTheme {
  AppTheme._();

  // ---------------------------------------------------------------------------
  // Spacing helpers
  // ---------------------------------------------------------------------------

  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;

  // Shared learner-surface tokens. Keeping these in one place prevents each
  // destination from inventing its own density and hierarchy.
  static const double contentInset = 16.0;
  static const double sectionGap = 24.0;
  static final TextStyle sectionTitle = AppFonts.extraBold(
    color: AppColors.textPrimary,
    fontSize: 18,
  );
  static final TextStyle sectionIntro = AppFonts.regular(
    color: AppColors.textMuted,
    fontSize: 14,
    height: 1.4,
  );

  // ---------------------------------------------------------------------------
  // Theme
  // ---------------------------------------------------------------------------

  static ThemeData get lightTheme {
    const colorScheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primarySoft,
      onPrimaryContainer: AppColors.primaryDeep,
      secondary: AppColors.accent,
      onSecondary: AppColors.onPrimary,
      tertiary: AppColors.accentAmber,
      onTertiary: AppColors.textPrimary,
      surface: AppColors.background,
      onSurface: AppColors.textPrimary,
      surfaceContainerLowest: AppColors.background,
      surfaceContainerLow: AppColors.surface,
      surfaceContainer: AppColors.surfaceAlt,
      onSurfaceVariant: AppColors.textMuted,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
      error: AppColors.danger,
      onError: AppColors.onPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: AppFonts.family,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: colorScheme,
      dividerColor: AppColors.border,

      // Screens glide forward and fade on Android; iOS keeps its swipe-back.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),

      // App bar: white-ish surface with dark content, lifted off the
      // screen by a soft shadow (same when content scrolls under it).
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.transparent,
        elevation: 2,
        scrolledUnderElevation: 2,
        shadowColor: AppColors.textPrimary,
        foregroundColor: AppColors.textPrimary,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: AppFonts.semiBold(
          color: AppColors.textPrimary,
          fontSize: 20,
        ),
      ),

      textTheme: TextTheme(
        displayLarge: AppFonts.bold(color: AppColors.textPrimary, fontSize: 32),
        displayMedium: AppFonts.semiBold(
          color: AppColors.textPrimary,
          fontSize: 28,
        ),
        displaySmall: AppFonts.semiBold(
          color: AppColors.textPrimary,
          fontSize: 24,
        ),
        headlineLarge: AppFonts.semiBold(
          color: AppColors.textPrimary,
          fontSize: 22,
        ),
        headlineMedium: AppFonts.medium(
          color: AppColors.textPrimary,
          fontSize: 20,
        ),
        headlineSmall: AppFonts.medium(
          color: AppColors.textPrimary,
          fontSize: 18,
        ),
        titleLarge: AppFonts.semiBold(
          color: AppColors.textPrimary,
          fontSize: 16,
        ),
        titleMedium: AppFonts.medium(
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
        titleSmall: AppFonts.medium(color: AppColors.textMuted, fontSize: 12),
        bodyLarge: AppFonts.regular(color: AppColors.textPrimary, fontSize: 16),
        bodyMedium: AppFonts.regular(
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
        bodySmall: AppFonts.regular(color: AppColors.textMuted, fontSize: 12),
        labelLarge: AppFonts.medium(color: AppColors.textPrimary, fontSize: 14),
        labelMedium: AppFonts.medium(color: AppColors.textMuted, fontSize: 12),
        labelSmall: AppFonts.medium(color: AppColors.textMuted, fontSize: 10),
      ),

      cardTheme: CardThemeData(
        color: AppColors.background,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        shadowColor: AppColors.black.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
      ),

      iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 24),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.surfaceAlt,
          disabledForegroundColor: AppColors.textMuted,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: AppFonts.regular(color: AppColors.textMuted),
        labelStyle: AppFonts.regular(color: AppColors.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          side: const BorderSide(color: AppColors.border),
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primarySoft
              : AppColors.surfaceAlt,
        ),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.surfaceAlt,
        circularTrackColor: AppColors.surfaceAlt,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: AppFonts.regular(color: AppColors.onPrimary),
        actionTextColor: AppColors.accentAmber,
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.textMuted,
        ),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.transparent,
        ),
        side: const BorderSide(color: AppColors.textMuted, width: 1.5),
        checkColor: const WidgetStatePropertyAll(AppColors.onPrimary),
      ),
    );
  }

  /// Retained so older call sites keep resolving; the app is light-only now.
  static ThemeData get darkTheme => lightTheme;

  /// Solid brand fill for avatars, badges and icon buttons.
  static BoxDecoration gradientDecoration({
    BorderRadius? borderRadius,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      gradient: AppColors.primaryGradient,
      borderRadius: borderRadius ?? BorderRadius.circular(radiusMedium),
      boxShadow: boxShadow,
    );
  }

  /// Soft elevation for cards lying on the light surface.
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: AppColors.black.withValues(alpha: 0.05),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];
}
