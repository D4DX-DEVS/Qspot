import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/app_theme.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/animation/pressable_scale.dart';

/// Full-width outlined "Review Answers" button, with a spinner while the
/// answers load.
class ReviewAnswersButton extends StatelessWidget {
  const ReviewAnswersButton({
    super.key,
    required this.onPressed,
    this.loading = false,
    this.label = 'Review Answers',
  });

  final VoidCallback onPressed;
  final bool loading;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = HomePalette.of(context);
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: PressableScale(
        enabled: !loading,
        child: OutlinedButton.icon(
          onPressed: loading ? null : onPressed,
          icon: loading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: p.brand,
                  ),
                )
              : const Icon(LucideIcons.eye),
          label: Text(label, style: AppFonts.bold(fontSize: 16)),
          style: OutlinedButton.styleFrom(
            foregroundColor: p.brand,
            side: BorderSide(color: p.brand, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            ),
          ),
        ),
      ),
    );
  }
}
