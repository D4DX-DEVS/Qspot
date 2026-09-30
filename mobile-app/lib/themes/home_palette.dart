import 'package:flutter/material.dart';

import 'accent_tone.dart';
import 'app_colors.dart';

/// Light and dark colour sets for the learner home tabs.
///
/// `HomeTheme` builds the Material theme from these; widgets read the extra
/// roles (accent tones, hero gradient) through [HomePalette.of].
class HomePalette {
  const HomePalette._({
    required this.brightness,
    required this.background,
    required this.card,
    required this.cardBorder,
    required this.text,
    required this.textMuted,
    required this.brand,
    required this.brandSoft,
    required this.error,
    required this.skyTop,
    required this.heroGradient,
    required this.rose,
    required this.coral,
    required this.amber,
    required this.teal,
    required this.mint,
    required this.slate,
  });

  final Brightness brightness;
  final Color background;
  final Color card;
  final Color cardBorder;
  final Color text;
  final Color textMuted;
  final Color brand;

  /// Nav highlight, icon circles and other quiet brand washes.
  final Color brandSoft;
  final Color error;

  /// Warm glow at the top of the Today header.
  final Color skyTop;

  /// Hero cards and banners.
  final LinearGradient heroGradient;

  /// Brand burgundy on its soft tint.
  final AccentTone rose;
  final AccentTone coral;
  final AccentTone amber;
  final AccentTone teal;
  final AccentTone mint;
  final AccentTone slate;

  bool get isDark => brightness == Brightness.dark;

  static const HomePalette light = HomePalette._(
    brightness: Brightness.light,
    background: AppColors.authLightBackground,
    card: AppColors.white,
    cardBorder: AppColors.authLightFieldBorder,
    text: AppColors.authLightText,
    textMuted: AppColors.authLightTextMuted,
    brand: AppColors.authBrand,
    brandSoft: AppColors.authLightSoftFill,
    error: AppColors.danger,
    skyTop: AppColors.homeLightSkyTop,
    heroGradient: AppColors.homeLightHeroGradient,
    rose: AccentTone(AppColors.authBrand, AppColors.authLightSoftFill),
    coral: AccentTone(AppColors.homeLightCoral, AppColors.homeLightCoralSoft),
    amber: AccentTone(AppColors.homeLightAmber, AppColors.homeLightAmberSoft),
    teal: AccentTone(AppColors.homeLightTeal, AppColors.homeLightTealSoft),
    mint: AccentTone(AppColors.homeLightMint, AppColors.homeLightMintSoft),
    slate: AccentTone(AppColors.homeLightSlate, AppColors.homeLightSlateSoft),
  );

  static const HomePalette dark = HomePalette._(
    brightness: Brightness.dark,
    background: AppColors.authDarkBackground,
    card: AppColors.authDarkFieldFill,
    cardBorder: AppColors.authDarkFieldBorder,
    text: AppColors.authDarkText,
    textMuted: AppColors.authDarkTextMuted,
    brand: AppColors.authDarkAccent,
    brandSoft: AppColors.authDarkSoftFill,
    error: AppColors.authDarkError,
    skyTop: AppColors.homeDarkSkyTop,
    heroGradient: AppColors.homeDarkHeroGradient,
    rose: AccentTone(AppColors.authDarkAccent, AppColors.authDarkSoftFill),
    coral: AccentTone(AppColors.homeDarkCoral, AppColors.homeDarkCoralSoft),
    amber: AccentTone(AppColors.homeDarkAmber, AppColors.homeDarkAmberSoft),
    teal: AccentTone(AppColors.homeDarkTeal, AppColors.homeDarkTealSoft),
    mint: AccentTone(AppColors.homeDarkMint, AppColors.homeDarkMintSoft),
    slate: AccentTone(AppColors.homeDarkSlate, AppColors.homeDarkSlateSoft),
  );

  /// Palette matching the nearest [Theme], which `HomeThemeScope` sets from
  /// the phone's light/dark setting.
  static HomePalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}
