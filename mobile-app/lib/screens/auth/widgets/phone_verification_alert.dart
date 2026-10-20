import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../themes/app_fonts.dart';
import 'auth_theme_scope.dart';

/// Asks the student to be sure the number they typed is real before the
/// account is created: it will be verified with a one-time code later, and an
/// account whose number cannot be verified loses access to its data.
class PhoneVerificationAlert extends StatelessWidget {
  const PhoneVerificationAlert({
    super.key,
    required this.phone,
    required this.dialCode,
  });

  /// The number as typed, without the country code.
  final String phone;

  /// The country's calling code without the "+", such as '91'.
  final String dialCode;

  /// Shows the alert. Resolves to true only when the student confirms the
  /// number; "Edit number" and a dismissed dialog both give false.
  static Future<bool> show(
    BuildContext context, {
    required String phone,
    required String dialCode,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      // The dialog sits above the page's AuthThemeScope, so apply it again.
      builder: (_) => AuthThemeScope(
        child: PhoneVerificationAlert(phone: phone, dialCode: dialCode),
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AlertDialog(
      scrollable: true,
      icon: Icon(
        LucideIcons.messageCircleWarning,
        size: 36,
        color: colors.primary,
      ),
      title: Text(
        'Check your phone number',
        textAlign: TextAlign.center,
        style: AppFonts.bold(color: colors.onSurface, fontSize: 20),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '+$dialCode $phone',
            textAlign: TextAlign.center,
            style: AppFonts.bold(color: colors.primary, fontSize: 20),
          ),
          const SizedBox(height: 12),
          Text(
            'Please enter a valid number that you can use. We will verify it '
            'by sending a one-time code (OTP) later. If the number cannot be '
            'verified, your data will become inaccessible.',
            textAlign: TextAlign.center,
            style: AppFonts.regular(
              color: colors.onSurfaceVariant,
              fontSize: 14.5,
              height: 1.45,
            ),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsOverflowAlignment: OverflowBarAlignment.center,
      actionsOverflowButtonSpacing: 4,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Edit number'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Number is correct'),
        ),
      ],
    );
  }
}
