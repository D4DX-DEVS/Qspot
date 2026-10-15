import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../themes/app_theme.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../../common/widgets/home_theme_scope.dart';
import '../model/certificate_model.dart';
import '../provider/certificate_share_provider.dart';
import '../widgets/certificate_preview.dart';
import '../widgets/certificate_share_button.dart';

/// One issued certificate, scaled to fit the screen, with a button to share
/// it as a PDF.
class CertificateScreen extends StatelessWidget {
  const CertificateScreen({super.key, required this.certificate});

  final CertificateModel certificate;

  @override
  Widget build(BuildContext context) {
    // Burgundy home theme; the page reads colours from the context inside it.
    return HomeThemeScope(
      child: ChangeNotifierProvider(
        create: (_) => CertificateShareProvider(certificate),
        child: Scaffold(
          appBar: CommonAppBar(title: 'Certificate'),
          body: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.contentInset,
                AppTheme.paddingSmall,
                AppTheme.contentInset,
                AppTheme.paddingLarge,
              ),
              child: Column(
                children: [
                  Expanded(child: CertificatePreview(certificate: certificate)),
                  const SizedBox(height: AppTheme.paddingLarge),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: const CertificateShareButton(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
