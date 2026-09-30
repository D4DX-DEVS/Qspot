import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_fonts.dart';
import 'auth_palette.dart';

/// Material themes for the sign-in and registration screens.
///
/// Fields, checkboxes, the class menu and the date picker all style
/// themselves from here, so the screens stay free of colour decisions.
class AuthTheme {
  AuthTheme._();

  static final ThemeData light = _build(AuthPalette.light);
  static final ThemeData dark = _build(AuthPalette.dark);

  static const double fieldRadius = 16;

  static ThemeData _build(AuthPalette p) {
    final scheme = ColorScheme(
      brightness: p.brightness,
      primary: p.accent,
      onPrimary: AppColors.onPrimary,
      primaryContainer: p.softFill,
      onPrimaryContainer: p.text,
      secondary: p.accent,
      onSecondary: AppColors.onPrimary,
      error: p.error,
      onError: p.isDark ? p.background : AppColors.onPrimary,
      surface: p.background,
      onSurface: p.text,
      onSurfaceVariant: p.textMuted,
      surfaceContainerLow: p.fieldFill,
      surfaceContainer: p.fieldFill,
      surfaceContainerHigh: p.fieldFill,
      outline: p.fieldBorder,
      outlineVariant: p.fieldBorder,
    );

    OutlineInputBorder border(Color color, [double width = 1.2]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldRadius),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: AppFonts.family,
      scaffoldBackgroundColor: p.background,
      canvasColor: p.fieldFill,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.fieldFill,
        hintStyle: AppFonts.regular(color: p.textMuted, fontSize: 15),
        errorStyle: AppFonts.regular(color: p.error, fontSize: 12),
        prefixIconColor: p.fieldIcon,
        suffixIconColor: p.text,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: border(p.fieldBorder),
        enabledBorder: border(p.fieldBorder),
        focusedBorder: border(p.accent, 1.6),
        errorBorder: border(p.error),
        focusedErrorBorder: border(p.error, 1.6),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? p.accent
              : AppColors.transparent,
        ),
        checkColor: const WidgetStatePropertyAll(AppColors.onPrimary),
        side: BorderSide(color: p.accent, width: 1.6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? p.accent : p.textMuted,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.accent,
        linearTrackColor: p.softFill,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: p.accent),
      ),
      dividerColor: p.fieldBorder,
    );
  }
}
