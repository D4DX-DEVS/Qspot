import 'package:flutter/material.dart';

/// QSPOT learner theme: an ocean-teal learning anchor with coral and amber
/// feedback accents on a quiet blue-white canvas.
class AppTheme {
  AppTheme._();

  // ---------------------------------------------------------------------------
  // Brand palette
  // ---------------------------------------------------------------------------

  /// Deep ocean teal: a calm, high-contrast anchor for learning actions.
  static const Color primary = Color(0xFF145A66);

  /// Pressed / dark shade of [primary].
  static const Color primaryDeep = Color(0xFF0C3D48);

  /// Tint used for chips, selected rows and subtle brand washes.
  static const Color primarySoft = Color(0xFFE3F1F0);

  /// Coral highlight for warmth, progress moments, and friendly emphasis.
  static const Color accent = Color(0xFFE97864);

  /// Logo diamond amber. Small highlights only.
  static const Color accentAmber = Color(0xFFF0B35B);

  static const Color background = Color(0xFFF7FAFB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFEDF3F4);
  static const Color textPrimary = Color(0xFF12252B);
  static const Color textMuted = Color(0xFF5A6C72);
  static const Color border = Color(0xFFD8E5E7);

  /// Content colour for brand-filled surfaces.
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Semantic status colours (kept distinct from the brand hues).
  static const Color success = Color(0xFF1F7A4D);
  static const Color danger = Color(0xFFB3261E);
  static const Color warning = Color(0xFF9A5B00);

  // ---------------------------------------------------------------------------
  // Legacy aliases
  //
  // These names are referenced throughout the screens. They are kept so the
  // existing widget code keeps compiling while resolving to light-theme values.
  // ---------------------------------------------------------------------------

  /// Scaffold background.
  static const Color backgroundColor = background;

  /// Content colour for brand fills and image overlays.
  static const Color primaryWhite = onPrimary;

  /// Muted / secondary text.
  static const Color secondaryGray = textMuted;

  /// Card and input surface.
  static const Color darkGray = surface;

  static const Color gradientStart = primary;
  static const Color gradientEnd = primary;

  /// Brand fill used for avatars, badges and logo fallbacks.
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDeep],
  );

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
  static const TextStyle sectionTitle = TextStyle(
    color: textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.w800,
  );
  static const TextStyle sectionIntro = TextStyle(
    color: textMuted,
    fontSize: 14,
    height: 1.4,
  );

  // ---------------------------------------------------------------------------
  // Theme
  // ---------------------------------------------------------------------------

  static ThemeData get lightTheme {
    const colorScheme = ColorScheme.light(
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primarySoft,
      onPrimaryContainer: primaryDeep,
      secondary: accent,
      onSecondary: onPrimary,
      tertiary: accentAmber,
      onTertiary: textPrimary,
      surface: background,
      onSurface: textPrimary,
      surfaceContainerLowest: background,
      surfaceContainerLow: surface,
      surfaceContainer: surfaceAlt,
      onSurfaceVariant: textMuted,
      outline: border,
      outlineVariant: border,
      error: danger,
      onError: onPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      colorScheme: colorScheme,
      dividerColor: border,

      // App bar: flat white surface with dark content.
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: textPrimary,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w600,
        ),
        displaySmall: TextStyle(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        headlineLarge: TextStyle(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
        headlineSmall: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
        titleLarge: TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: TextStyle(
          color: textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
        bodyMedium: TextStyle(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        bodySmall: TextStyle(
          color: textMuted,
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
        labelLarge: TextStyle(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelMedium: TextStyle(
          color: textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: TextStyle(
          color: textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),

      cardTheme: CardThemeData(
        color: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: border),
        ),
      ),

      iconTheme: const IconThemeData(color: textPrimary, size: 24),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          disabledBackgroundColor: surfaceAlt,
          disabledForegroundColor: textMuted,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: const TextStyle(color: textMuted),
        labelStyle: const TextStyle(color: textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: primary, width: 1.4),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          side: const BorderSide(color: border),
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: background,
        selectedItemColor: primary,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? primary : Colors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? primarySoft : surfaceAlt,
        ),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: surfaceAlt,
        circularTrackColor: surfaceAlt,
      ),

      snackBarTheme: const SnackBarThemeData(
        backgroundColor: textPrimary,
        contentTextStyle: TextStyle(color: onPrimary),
        actionTextColor: accentAmber,
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? primary : textMuted,
        ),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primary
              : Colors.transparent,
        ),
        side: const BorderSide(color: textMuted, width: 1.5),
        checkColor: const WidgetStatePropertyAll(onPrimary),
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
      gradient: primaryGradient,
      borderRadius: borderRadius ?? BorderRadius.circular(radiusMedium),
      boxShadow: boxShadow,
    );
  }

  /// Soft elevation for cards lying on the light surface.
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];
}
