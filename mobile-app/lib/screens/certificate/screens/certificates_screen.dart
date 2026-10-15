import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../themes/app_theme.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../../../widgets/common/loading_skeleton.dart';
import '../../../widgets/common/state_message_view.dart';
import '../provider/certificates_screen_provider.dart';
import '../widgets/certificate_tile.dart';
import 'certificate_screen.dart';

/// Every certificate the learner has earned. Tap one to see it and share it.
class CertificatesScreen extends StatelessWidget {
  const CertificatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CertificatesScreenProvider()..load(),
      child: Consumer<CertificatesScreenProvider>(
        builder: (context, certificates, _) => Scaffold(
          appBar: const CommonAppBar(title: 'My Certificates'),
          body: _body(context, certificates),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, CertificatesScreenProvider certificates) {
    if (certificates.showSkeleton) return const LoadingSkeleton();
    if (certificates.showError) {
      return StateMessageView(
        icon: LucideIcons.wifiOff,
        title: 'Could Not Load Certificates',
        message: certificates.error ?? 'Check your connection and try again.',
        onRetry: certificates.load,
      );
    }
    final items = certificates.items;
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: certificates.load,
        child: LayoutBuilder(
          builder: (context, box) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: box.maxHeight,
                child: const StateMessageView(
                  icon: LucideIcons.award,
                  title: 'No Certificates Yet',
                  message:
                      'Pass an exam and your certificate will show up here.',
                ),
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: certificates.load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          AppTheme.contentInset,
          8,
          AppTheme.contentInset,
          28 + MediaQuery.paddingOf(context).bottom,
        ),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) => CertificateTile(
          certificate: items[index],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CertificateScreen(certificate: items[index]),
            ),
          ),
        ),
      ),
    );
  }
}
