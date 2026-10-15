import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../themes/app_colors.dart';
import '../widgets/common/app_snack_bar.dart';

/// Opens the phone's dialer with [number]. When no dialer can be opened,
/// copies the number instead and says so.
Future<void> callPhone(BuildContext context, String number) async {
  final digits = number.replaceAll(RegExp(r'[^\d+]'), '');
  var launched = false;
  try {
    launched = await launchUrl(
      Uri(scheme: 'tel', path: digits),
      mode: LaunchMode.externalApplication,
    );
  } catch (e) {
    debugPrint('Error launching dialer: $e');
  }
  if (launched || !context.mounted) return;
  await Clipboard.setData(ClipboardData(text: number));
  if (!context.mounted) return;
  AppSnackBar.show(
    context,
    message: "Can't make calls here. Number copied: $number",
    color: AppColors.warningOrange,
    duration: const Duration(seconds: 4),
  );
}

/// Opens WhatsApp for [number]. If WhatsApp is unavailable, the web handoff
/// is attempted before falling back to copying the number.
Future<void> messageOnWhatsApp(BuildContext context, String number) async {
  final digits = number.replaceAll(RegExp(r'\D'), '');
  var launched = false;
  try {
    launched = await launchUrl(
      Uri(scheme: 'whatsapp', host: 'send', queryParameters: {'phone': digits}),
      mode: LaunchMode.externalApplication,
    );
  } catch (e) {
    debugPrint('Error launching WhatsApp: $e');
  }

  if (!launched) {
    try {
      launched = await launchUrl(
        Uri.https('wa.me', digits),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('Error launching WhatsApp web: $e');
    }
  }

  if (launched || !context.mounted) return;
  await Clipboard.setData(ClipboardData(text: number));
  if (!context.mounted) return;
  AppSnackBar.show(
    context,
    message: "Can't open WhatsApp. Number copied: $number",
    color: AppColors.warningOrange,
    duration: const Duration(seconds: 4),
  );
}
