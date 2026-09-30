import 'package:flutter/material.dart';

import '../../../themes/app_fonts.dart';

/// Centred "prompt + action" line, e.g. "Don't have an account? Register Now".
/// A null [onTap] shows the action greyed out.
class AuthLinkRow extends StatelessWidget {
  const AuthLinkRow({
    super.key,
    required this.prompt,
    required this.action,
    required this.onTap,
    this.showChevron = true,
  });

  final String prompt;
  final String action;
  final VoidCallback? onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            prompt,
            style: AppFonts.regular(
              color: colors.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
        ),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            minimumSize: const Size(0, 40),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(action, style: AppFonts.semiBold(fontSize: 14)),
              if (showChevron)
                const Icon(Icons.chevron_right_rounded, size: 20),
            ],
          ),
        ),
      ],
    );
  }
}
