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
  // System
  // ---------------------------------------------------------------------------

  /// Notification LED for class alarms (Android).
  static const Color alarmLed = Color(0xFFFF0000);
}
