import 'package:flutter/material.dart';

/// Single source for every font used in the app.
///
/// Every text style is built from one of the weight helpers below, so the
/// family and weights stay consistent. A plain `Text` without a style falls
/// back to [regular] through the app theme.
class AppFonts {
  AppFonts._();

  /// Bundled from `assets/fonts` (see pubspec.yaml).
  static const String family = 'Poppins';

  /// Default body text (w400).
  static TextStyle regular({
    double? fontSize,
    Color? color,
    double? height,
    double? letterSpacing,
  }) => _style(FontWeight.w400, fontSize, color, height, letterSpacing);

  /// Labels, buttons and gentle emphasis (w500).
  static TextStyle medium({
    double? fontSize,
    Color? color,
    double? height,
    double? letterSpacing,
  }) => _style(FontWeight.w500, fontSize, color, height, letterSpacing);

  /// Titles and list headings (w600).
  static TextStyle semiBold({
    double? fontSize,
    Color? color,
    double? height,
    double? letterSpacing,
  }) => _style(FontWeight.w600, fontSize, color, height, letterSpacing);

  /// Strong emphasis, numbers and card titles (w700).
  static TextStyle bold({
    double? fontSize,
    Color? color,
    double? height,
    double? letterSpacing,
  }) => _style(FontWeight.w700, fontSize, color, height, letterSpacing);

  /// Section and hero headings (w800).
  static TextStyle extraBold({
    double? fontSize,
    Color? color,
    double? height,
    double? letterSpacing,
  }) => _style(FontWeight.w800, fontSize, color, height, letterSpacing);

  static TextStyle _style(
    FontWeight fontWeight,
    double? fontSize,
    Color? color,
    double? height,
    double? letterSpacing,
  ) {
    return TextStyle(
      fontFamily: family,
      fontWeight: fontWeight,
      fontSize: fontSize,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }
}
