import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../themes/app_colors.dart';
import '../../../themes/app_fonts.dart';
import '../../../themes/app_theme.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/animation/pressable_scale.dart';
import '../model/certificate_model.dart';
import '../provider/certificates_screen_provider.dart';
import '../screens/certificate_screen.dart';

/// "View Certificate" button for one exam. Takes no space until a
/// certificate issued for [quizId] is found, so it can sit in any page
/// whether or not the student has one; a failed lookup also stays hidden.
class ViewCertificateButton extends StatelessWidget {
  const ViewCertificateButton({
    super.key,
    required this.quizId,
    this.padding = EdgeInsets.zero,
    this.fetch,
  });

  final String quizId;

  /// Space around the button when it shows.
  final EdgeInsetsGeometry padding;

  /// Replaces the API call in tests.
  final Future<List<CertificateModel>> Function()? fetch;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CertificatesScreenProvider(fetch: fetch)..load(),
      child: Consumer<CertificatesScreenProvider>(
        builder: (context, provider, _) {
          final certificate = provider.forQuiz(quizId);
          if (certificate == null) return const SizedBox.shrink();
          return Padding(
            padding: padding,
            child: _button(context, certificate),
          );
        },
      ),
    );
  }

  Widget _button(BuildContext context, CertificateModel certificate) {
    final p = HomePalette.of(context);
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: PressableScale(
        child: FilledButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CertificateScreen(certificate: certificate),
            ),
          ),
          icon: const Icon(LucideIcons.award),
          label: Text('View Certificate', style: AppFonts.bold(fontSize: 16)),
          style: FilledButton.styleFrom(
            backgroundColor: p.brand,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            ),
          ),
        ),
      ),
    );
  }
}
