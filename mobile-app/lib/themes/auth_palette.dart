import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Light and dark colour sets for the sign-in and registration screens.
///
/// `AuthTheme` builds the Material theme from these; widgets read the extra
/// roles (artwork, field icons) through [AuthPalette.of].
class AuthPalette {
  const AuthPalette._({
    required this.brightness,
    required this.background,
    required this.fieldFill,
    required this.fieldBorder,
    required this.fieldIcon,
    required this.text,
    required this.textMuted,
    required this.accent,
    required this.error,
    required this.softFill,
    required this.archFill,
    required this.archHalo,
    required this.archEdge,
    required this.lanternFrame,
    required this.lanternGlow,
    required this.skylineFar,
    required this.skylineNear,
    required this.window,
    required this.moon,
    required this.floor,
    required this.wood,
    required this.pages,
    required this.waveSoft,
    required this.waveMid,
    required this.cornerStart,
    required this.cornerEnd,
  });

  final Brightness brightness;
  final Color background;
  final Color fieldFill;
  final Color fieldBorder;
  final Color fieldIcon;
  final Color text;
  final Color textMuted;
  final Color accent;
  final Color error;

  /// Back button, consent card and other quiet tinted surfaces.
  final Color softFill;

  final Color archFill;
  final Color archHalo;
  final Color archEdge;
  final Color lanternFrame;
  final Color lanternGlow;
  final Color skylineFar;
  final Color skylineNear;
  final Color window;
  final Color moon;
  final Color floor;
  final Color wood;
  final Color pages;
  final Color waveSoft;
  final Color waveMid;
  final Color cornerStart;
  final Color cornerEnd;

  bool get isDark => brightness == Brightness.dark;

  static const AuthPalette light = AuthPalette._(
    brightness: Brightness.light,
    background: AppColors.authLightBackground,
    fieldFill: AppColors.white,
    fieldBorder: AppColors.authLightFieldBorder,
    fieldIcon: AppColors.authLightFieldIcon,
    text: AppColors.authLightText,
    textMuted: AppColors.authLightTextMuted,
    accent: AppColors.authBrand,
    error: AppColors.danger,
    softFill: AppColors.authLightSoftFill,
    archFill: AppColors.authLightArchFill,
    archHalo: AppColors.authLightArchHalo,
    archEdge: AppColors.authLightArchEdge,
    lanternFrame: AppColors.authLightLanternFrame,
    lanternGlow: AppColors.authLightLanternGlow,
    skylineFar: AppColors.authLightSkylineFar,
    skylineNear: AppColors.authLightSkylineNear,
    window: AppColors.authLightWindow,
    moon: AppColors.authLightMoon,
    floor: AppColors.authLightFloor,
    wood: AppColors.authLightWood,
    pages: AppColors.authLightPages,
    waveSoft: AppColors.authLightWaveSoft,
    waveMid: AppColors.authLightWaveMid,
    cornerStart: AppColors.authLightCornerStart,
    cornerEnd: AppColors.authLightCornerEnd,
  );

  static const AuthPalette dark = AuthPalette._(
    brightness: Brightness.dark,
    background: AppColors.authDarkBackground,
    fieldFill: AppColors.authDarkFieldFill,
    fieldBorder: AppColors.authDarkFieldBorder,
    fieldIcon: AppColors.authDarkFieldIcon,
    text: AppColors.authDarkText,
    textMuted: AppColors.authDarkTextMuted,
    accent: AppColors.authDarkAccent,
    error: AppColors.authDarkError,
    softFill: AppColors.authDarkSoftFill,
    archFill: AppColors.authDarkArchFill,
    archHalo: AppColors.authDarkArchHalo,
    archEdge: AppColors.authDarkArchEdge,
    lanternFrame: AppColors.authDarkLanternFrame,
    lanternGlow: AppColors.authDarkLanternGlow,
    skylineFar: AppColors.authDarkSkylineFar,
    skylineNear: AppColors.authDarkSkylineNear,
    window: AppColors.authDarkWindow,
    moon: AppColors.authDarkMoon,
    floor: AppColors.authDarkFloor,
    wood: AppColors.authDarkWood,
    pages: AppColors.authDarkPages,
    waveSoft: AppColors.authDarkSoftFill,
    waveMid: AppColors.authDarkCornerEnd,
    cornerStart: AppColors.authDarkCornerStart,
    cornerEnd: AppColors.authDarkCornerEnd,
  );

  /// Night scene on the burgundy splash (same in light and dark). Only the
  /// artwork roles matter here; the rest mirror [dark].
  static const AuthPalette splash = AuthPalette._(
    brightness: Brightness.dark,
    background: AppColors.authBrand,
    fieldFill: AppColors.authDarkFieldFill,
    fieldBorder: AppColors.authDarkFieldBorder,
    fieldIcon: AppColors.authDarkFieldIcon,
    text: AppColors.authDarkText,
    textMuted: AppColors.authDarkTextMuted,
    accent: AppColors.authDarkAccent,
    error: AppColors.authDarkError,
    softFill: AppColors.authDarkSoftFill,
    archFill: AppColors.splashArchFill,
    archHalo: AppColors.splashArchHalo,
    archEdge: AppColors.splashArchEdge,
    lanternFrame: AppColors.splashLanternFrame,
    lanternGlow: AppColors.splashLanternGlow,
    skylineFar: AppColors.splashSkylineFar,
    skylineNear: AppColors.splashSkylineNear,
    window: AppColors.splashWindow,
    moon: AppColors.splashMoon,
    floor: AppColors.splashSkylineNear,
    wood: AppColors.authDarkWood,
    pages: AppColors.authDarkPages,
    waveSoft: AppColors.authDarkSoftFill,
    waveMid: AppColors.authDarkCornerEnd,
    cornerStart: AppColors.authDarkCornerStart,
    cornerEnd: AppColors.authDarkCornerEnd,
  );

  /// Palette matching the nearest [Theme], which `AuthThemeScope` sets from
  /// the phone's light/dark setting.
  static AuthPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}
