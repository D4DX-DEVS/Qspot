import 'package:flutter/material.dart';

import '../../../../themes/auth_palette.dart';

/// Paints decorative artwork with the current light/dark [AuthPalette].
///
/// Fills its (bounded) parent, so place it in a sized or positioned slot.
class AuthArt extends StatelessWidget {
  const AuthArt({super.key, required this.painter});

  final CustomPainter Function(AuthPalette palette) painter;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: CustomPaint(painter: painter(AuthPalette.of(context))),
    );
  }
}
