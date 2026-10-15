import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../widgets/animation/pressable_scale.dart';

/// Round, softly tinted back arrow.
class AuthBackButton extends StatelessWidget {
  const AuthBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: PressableScale(
        child: IconButton(
          onPressed: onPressed,
          tooltip: 'Back',
          style: IconButton.styleFrom(
            backgroundColor: colors.primaryContainer,
            foregroundColor: colors.onSurface,
            fixedSize: const Size(48, 48),
          ),
          icon: const Icon(LucideIcons.arrowLeft, size: 22),
        ),
      ),
    );
  }
}
