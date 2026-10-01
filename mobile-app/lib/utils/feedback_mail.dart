import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../themes/app_colors.dart';
import '../widgets/common/app_snack_bar.dart';

const String _feedbackEmail = 'mail@d4dx.co';
const String _feedbackSubject = 'QSpot App Feedback';
const String _feedbackBody =
    'Hi D4DX Team,\n\nI would like to share my feedback about the QSpot app:\n\n[Please write your feedback here]\n\nThank you!';

/// Opens the phone's mail app with a feedback draft to the D4DX team. When no
/// mail app can be opened, copies the address instead and says so.
Future<void> sendFeedbackMail(BuildContext context) async {
  final uri = Uri.parse(
    'mailto:$_feedbackEmail'
    '?subject=${Uri.encodeComponent(_feedbackSubject)}'
    '&body=${Uri.encodeComponent(_feedbackBody)}',
  );
  var launched = false;
  try {
    launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (e) {
    debugPrint('Error launching email: $e');
  }
  if (launched || !context.mounted) return;
  await Clipboard.setData(const ClipboardData(text: _feedbackEmail));
  if (!context.mounted) return;
  AppSnackBar.show(
    context,
    message: 'No email app found. Address copied: $_feedbackEmail',
    color: AppColors.warningOrange,
    duration: const Duration(seconds: 4),
  );
}
