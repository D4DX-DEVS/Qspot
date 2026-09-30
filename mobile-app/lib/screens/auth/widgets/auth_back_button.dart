import 'package:flutter/material.dart';

/// Round, softly tinted back arrow.
class AuthBackButton extends StatelessWidget {
  const AuthBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        onPressed: onPressed,
        tooltip: 'Back',
        style: IconButton.styleFrom(
          backgroundColor: colors.primaryContainer,
          foregroundColor: colors.onSurface,
          fixedSize: const Size(46, 46),
        ),
        icon: const Icon(Icons.arrow_back_rounded, size: 22),
      ),
    );
  }
}
