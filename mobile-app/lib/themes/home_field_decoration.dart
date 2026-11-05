import 'package:flutter/material.dart';

import 'app_fonts.dart';
import 'app_theme.dart';
import 'home_palette.dart';

/// Rounded, filled text field look used on the learner pages (the same one as
/// the Ask a Question form), in the light or dark home palette.
class HomeFieldDecoration {
  HomeFieldDecoration._();

  static InputDecoration of(
    BuildContext context, {
    String? hint,
    String? label,
  }) {
    final p = HomePalette.of(context);
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color, width: width),
        );
    return InputDecoration(
      hintText: hint,
      labelText: label,
      hintStyle: AppFonts.regular(color: p.textMuted),
      labelStyle: AppFonts.medium(color: p.textMuted),
      floatingLabelStyle: AppFonts.semiBold(color: p.brand),
      filled: true,
      fillColor: p.card,
      border: border(p.cardBorder),
      enabledBorder: border(p.cardBorder),
      focusedBorder: border(p.brand, 1.6),
      errorBorder: border(p.error),
      focusedErrorBorder: border(p.error, 1.6),
      contentPadding: const EdgeInsets.all(AppTheme.paddingMedium),
    );
  }
}
