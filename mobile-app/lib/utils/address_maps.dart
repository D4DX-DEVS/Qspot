import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../themes/app_colors.dart';
import '../widgets/common/app_snack_bar.dart';

const String d4dxAddress =
    'D4DX Innovations LLP, Mavoor Road, Calicut, Kerala, Pin 673004';

/// Opens the address in the device's preferred maps app or browser.
Future<void> openD4dxAddress(BuildContext context) async {
  final uri = Uri.https('www.google.com', '/maps/search/', {
    'api': '1',
    'query': d4dxAddress,
  });
  var launched = false;
  try {
    launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (e) {
    debugPrint('Error launching maps: $e');
  }
  if (launched || !context.mounted) return;
  await Clipboard.setData(const ClipboardData(text: d4dxAddress));
  if (!context.mounted) return;
  AppSnackBar.show(
    context,
    message: 'Maps unavailable. Address copied.',
    color: AppColors.warningOrange,
  );
}
