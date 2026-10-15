import 'package:flutter/material.dart';

/// Shared timings and curves so every animation in the app feels the same.
abstract final class Motion {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration medium = Duration(milliseconds: 260);
  static const Duration entrance = Duration(milliseconds: 420);
  static const Duration slow = Duration(milliseconds: 700);

  /// Gentle overshoot, for things that "pop" into place.
  static const Curve bounce = Curves.easeOutBack;
  static const Curve smooth = Curves.easeOutCubic;

  /// True when the user turned animations off in system settings.
  static bool reduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);
}
