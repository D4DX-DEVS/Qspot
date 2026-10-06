import 'package:flutter/material.dart';

/// Single source for every colour used in the app.
///
/// No other file should create a colour (`Color(0x...)` or `Colors.*`).
/// Change a value here and it updates everywhere, including the Material
/// theme built in `app_theme.dart`.
class AppColors {
  AppColors._();

  // ---------------------------------------------------------------------------
  // Brand
  // ---------------------------------------------------------------------------

  /// Deep ocean teal: a calm, high-contrast anchor for learning actions.
  static const Color primary = Color(0xFF145A66);

  /// Pressed / dark shade of [primary].
  static const Color primaryDeep = Color(0xFF0C3D48);

  /// Tint used for chips, selected rows and subtle brand washes.
  static const Color primarySoft = Color(0xFFE3F1F0);

  /// Coral highlight for warmth, progress moments, and friendly emphasis.
  static const Color accent = Color(0xFFE97864);

  /// Dark coral for urgent / overdue highlight cards.
  static const Color accentDeep = Color(0xFF8D3F34);

  /// Logo diamond amber. Small highlights only.
  static const Color accentAmber = Color(0xFFF0B35B);

  /// Brand fill used for avatars, badges and logo fallbacks.
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDeep],
  );

  // ---------------------------------------------------------------------------
  // Surfaces & text
  // ---------------------------------------------------------------------------

  static const Color background = Color(0xFFF7FAFB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFEDF3F4);
  static const Color border = Color(0xFFD8E5E7);
  static const Color textPrimary = Color(0xFF12252B);
  static const Color textMuted = Color(0xFF5A6C72);

  /// Content colour for brand-filled surfaces.
  static const Color onPrimary = Color(0xFFFFFFFF);

  // ---------------------------------------------------------------------------
  // Status (kept distinct from the brand hues)
  // ---------------------------------------------------------------------------

  static const Color success = Color(0xFF1F7A4D);
  static const Color successSoft = Color(0xFFE8F3EC);
  static const Color danger = Color(0xFFB3261E);
  static const Color dangerSoft = Color(0xFFFFEFED);
  static const Color warning = Color(0xFF9A5B00);
  static const Color warningSoft = Color(0xFFFFF7EA);

  /// Orange fill for warning snack bars (white text stays readable on it).
  static const Color warningOrange = Color(0xFFC75000);

  // ---------------------------------------------------------------------------
  // Neutrals & overlays (video, images, shadows)
  // ---------------------------------------------------------------------------

  static const Color white = Color(0xFFFFFFFF);
  static const Color white70 = Color(0xB3FFFFFF);
  static const Color white38 = Color(0x61FFFFFF);
  static const Color white24 = Color(0x3DFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);

  /// Dark fade at the bottom of video frames.
  static const Color scrim = Color(0xCC000000);

  /// Stronger dark fade behind text on images.
  static const Color scrimStrong = Color(0xE6000000);

  // ---------------------------------------------------------------------------
  // Sign-in & registration (logo-matched burgundy, light + dark)
  // Read through `AuthPalette`, not directly from screens.
  // ---------------------------------------------------------------------------

  /// Logo burgundy: accent text, links and snack bars on the auth screens.
  static const Color authBrand = Color(0xFF740C3B);

  /// Pill button fill, burgundy to logo coral (same in light and dark).
  static const LinearGradient authButtonGradient = LinearGradient(
    colors: [Color(0xFF87174A), Color(0xFFB02C50), Color(0xFFE46C5C)],
  );

  static const Color authLightBackground = Color(0xFFFBF7F3);
  static const Color authLightFieldBorder = Color(0xFFEDE3E5);
  static const Color authLightFieldIcon = Color(0xFF6A0F35);
  static const Color authLightText = Color(0xFF141C2A);
  static const Color authLightTextMuted = Color(0xFF5E646C);
  static const Color authLightSoftFill = Color(0xFFFAEDEF);
  static const Color authLightArchFill = Color(0xFFFFFDFA);
  static const Color authLightArchHalo = Color(0xFFF6E8E0);
  static const Color authLightArchEdge = Color(0xFFEBD3C5);
  static const Color authLightLanternFrame = Color(0xFFC9A07A);
  static const Color authLightLanternGlow = Color(0xFFFFE3B8);
  static const Color authLightSkylineFar = Color(0xFFF0DDD6);
  static const Color authLightSkylineNear = Color(0xFFE2C6BF);
  static const Color authLightWindow = Color(0xFFF8EAE2);
  static const Color authLightMoon = Color(0xFFF3C58F);
  static const Color authLightFloor = Color(0xFFF1E0D6);
  static const Color authLightWood = Color(0xFF8E5230);
  static const Color authLightPages = Color(0xFFFFF9EF);
  static const Color authLightWaveSoft = Color(0xFFF6DFDF);
  static const Color authLightWaveMid = Color(0xFFEECBCB);
  static const Color authLightCornerStart = Color(0xFF8C1D4B);
  static const Color authLightCornerEnd = Color(0xFFD96A73);

  static const Color authDarkBackground = Color(0xFF0C0E1A);
  static const Color authDarkFieldFill = Color(0xFF151926);
  static const Color authDarkFieldBorder = Color(0xFF23253A);
  static const Color authDarkFieldIcon = Color(0xFFF0EEF4);
  static const Color authDarkText = Color(0xFFF6F5F8);
  static const Color authDarkTextMuted = Color(0xFF9CA0B4);
  static const Color authDarkAccent = Color(0xFFE4589A);
  static const Color authDarkError = Color(0xFFF2B8B5);
  static const Color authDarkSoftFill = Color(0xFF1D1B2B);
  static const Color authDarkArchFill = Color(0xFF080913);
  static const Color authDarkArchHalo = Color(0xFF1A1320);
  static const Color authDarkArchEdge = Color(0xFFD9894F);
  static const Color authDarkLanternFrame = Color(0xFFB8844C);
  static const Color authDarkLanternGlow = Color(0xFFFFC266);
  static const Color authDarkSkylineFar = Color(0xFF2A1F2C);
  static const Color authDarkSkylineNear = Color(0xFF17121D);
  static const Color authDarkWindow = Color(0xFFD98A5E);
  static const Color authDarkMoon = Color(0xFFFFE7A6);
  static const Color authDarkFloor = Color(0xFF1B1520);
  static const Color authDarkWood = Color(0xFF7A4222);
  static const Color authDarkPages = Color(0xFFEADBC0);
  static const Color authDarkCornerStart = Color(0xFF5B0E2E);
  static const Color authDarkCornerEnd = Color(0xFF2A1420);

  /// Night-scene artwork on the burgundy splash.
  static const Color splashArchFill = Color(0xFF5E0930);
  static const Color splashArchHalo = Color(0xFF680B36);
  static const Color splashArchEdge = Color(0xFFF2A98A);
  static const Color splashLanternFrame = Color(0xFFE7B07A);
  static const Color splashLanternGlow = Color(0xFFFFD08A);
  static const Color splashSkylineFar = Color(0xFF5E0A31);
  static const Color splashSkylineNear = Color(0xFF4C0828);
  static const Color splashWindow = Color(0xFFF2A36B);
  static const Color splashMoon = Color(0xFFFFE3A8);

  // ---------------------------------------------------------------------------
  // Learner home tabs (Today, Learn, Practice, Progress, Me), light + dark.
  // Base roles reuse the auth colours above. Read through `HomePalette`.
  // ---------------------------------------------------------------------------

  /// Hero cards and banners, deep burgundy to rose.
  static const LinearGradient homeLightHeroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF720B3A), Color(0xFFA9365B)],
  );
  static const LinearGradient homeDarkHeroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3E0720), Color(0xFF65113A), Color(0xFF8A2A4A)],
  );

  /// Gold call-to-action pill on the hero card (same in light and dark).
  static const LinearGradient homeGoldGradient = LinearGradient(
    colors: [Color(0xFFFBD495), Color(0xFFF3AC66)],
  );

  /// Warm glow at the top of the Today header, behind the skyline.
  static const Color homeLightSkyTop = Color(0xFFFFFBF6);
  static const Color homeDarkSkyTop = Color(0xFF2A1522);

  static const Color homeLightAmber = Color(0xFFA8660F);
  static const Color homeLightAmberSoft = Color(0xFFFCEFDA);
  static const Color homeLightCoral = Color(0xFFBE3F45);
  static const Color homeLightCoralSoft = Color(0xFFFDE8E6);
  static const Color homeLightTeal = Color(0xFF1F6F6B);
  static const Color homeLightTealSoft = Color(0xFFE0F0EE);
  static const Color homeLightMint = Color(0xFF2E7D57);
  static const Color homeLightMintSoft = Color(0xFFE2F2E9);
  static const Color homeLightSlate = Color(0xFF3C5A7A);
  static const Color homeLightSlateSoft = Color(0xFFEDF1F6);

  static const Color homeDarkAmber = Color(0xFFF0B35B);
  static const Color homeDarkAmberSoft = Color(0xFF2B2216);
  static const Color homeDarkCoral = Color(0xFFF2877F);
  static const Color homeDarkCoralSoft = Color(0xFF2E1A1D);
  static const Color homeDarkTeal = Color(0xFF6CC5BD);
  static const Color homeDarkTealSoft = Color(0xFF12262A);
  static const Color homeDarkMint = Color(0xFF6FCB9C);
  static const Color homeDarkMintSoft = Color(0xFF13261D);
  static const Color homeDarkSlate = Color(0xFF9DB4D6);
  static const Color homeDarkSlateSoft = Color(0xFF1A2131);

  // ---------------------------------------------------------------------------
  // System
  // ---------------------------------------------------------------------------

  /// Notification LED for class alarms (Android).
  static const Color alarmLed = Color(0xFFFF0000);
}
