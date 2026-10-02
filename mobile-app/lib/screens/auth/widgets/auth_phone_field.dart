import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../widgets/common/country_code_prefix.dart';
import 'auth_text_field.dart';

/// 10-digit Indian mobile number field with the +91 prefix always visible.
class AuthPhoneField extends StatelessWidget {
  const AuthPhoneField({
    super.key,
    required this.controller,
    this.hint = 'Enter Your Phone Number',
    this.showPhoneIcon = false,
  });

  final TextEditingController controller;
  final String hint;
  final bool showPhoneIcon;

  @override
  Widget build(BuildContext context) {
    return AuthTextField(
      controller: controller,
      hint: hint,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      prefix: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showPhoneIcon)
            const Padding(
              padding: EdgeInsets.only(left: 16),
              child: Icon(LucideIcons.phone, size: 22),
            ),
          CountryCodePrefix(leftPadding: showPhoneIcon ? 12 : 18),
        ],
      ),
      validator: (value) {
        final phone = value?.trim() ?? '';
        if (phone.isEmpty) return 'Please enter your phone number';
        if (phone.length != 10) {
          return 'Please enter a valid 10-digit phone number';
        }
        return null;
      },
    );
  }
}
