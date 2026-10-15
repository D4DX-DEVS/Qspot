import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../themes/app_colors.dart';
import '../../../themes/app_fonts.dart';
import '../../../themes/app_theme.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/animation/pressable_scale.dart';
import '../../../widgets/common/app_snack_bar.dart';
import '../provider/certificate_share_provider.dart';

/// Full-width "Share PDF" button for the [CertificateShareProvider] above it.
/// Shows a spinner while the PDF is being prepared.
class CertificateShareButton extends StatelessWidget {
  const CertificateShareButton({super.key});

  Future<void> _share(BuildContext context) async {
    final failure = await context.read<CertificateShareProvider>().share();
    if (failure != null && context.mounted) {
      AppSnackBar.show(context, message: failure, color: AppColors.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = HomePalette.of(context);
    final sharing = context.select<CertificateShareProvider, bool>(
      (provider) => provider.isSharing,
    );
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: PressableScale(
        child: FilledButton.icon(
          onPressed: sharing ? null : () => _share(context),
          icon: sharing
              ? SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.white,
                  ),
                )
              : const Icon(LucideIcons.share2),
          label: Text(
            sharing ? 'Preparing PDF…' : 'Share PDF',
            style: AppFonts.bold(fontSize: 16),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: p.brand,
            foregroundColor: AppColors.white,
            disabledBackgroundColor: p.brand.withValues(alpha: 0.6),
            disabledForegroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            ),
          ),
        ),
      ),
    );
  }
}
