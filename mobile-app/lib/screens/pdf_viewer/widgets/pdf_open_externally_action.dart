import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../themes/app_colors.dart';
import '../../../widgets/common/app_snack_bar.dart';
import '../../../widgets/common/circle_icon_action.dart';
import '../provider/pdf_viewer_provider.dart';

/// App bar action that hands the PDF to the device's browser or PDF app,
/// e.g. to save it or when it won't render inside the app.
class PdfOpenExternallyAction extends StatelessWidget {
  const PdfOpenExternallyAction({super.key});

  @override
  Widget build(BuildContext context) {
    return CircleIconAction(
      icon: LucideIcons.externalLink,
      tooltip: 'Open in another app',
      onPressed: () => _open(context),
    );
  }

  Future<void> _open(BuildContext context) async {
    final opened = await context.read<PdfViewerProvider>().openExternally();
    if (opened || !context.mounted) return;
    AppSnackBar.show(
      context,
      message:
          'We couldn’t open this file. Check your connection and try again.',
      color: AppColors.danger,
    );
  }
}
