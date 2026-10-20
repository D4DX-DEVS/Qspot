import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../widgets/common/country_code_prefix.dart';
import '../model/phone_country.dart';
import 'auth_text_field.dart';
import 'country_picker_sheet.dart';

/// Mobile number field with the country's flag and calling code always
/// visible. Tapping them picks another country; the number may have only as
/// many digits as a mobile number there (India 10, UAE 9…).
class AuthPhoneField extends StatelessWidget {
  const AuthPhoneField({
    super.key,
    required this.controller,
    required this.country,
    required this.onCountryChanged,
    this.hint = 'Enter Your Phone Number',
  });

  final TextEditingController controller;
  final PhoneCountry country;
  final ValueChanged<PhoneCountry> onCountryChanged;
  final String hint;

  Future<void> _pickCountry(BuildContext context) async {
    final picked = await CountryPickerSheet.show(context, selected: country);
    if (picked != null) onCountryChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return AuthTextField(
      controller: controller,
      hint: hint,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        // A leading 0 is only dialled inside the country, not stored.
        if (country.trunkZero) FilteringTextInputFormatter.deny(RegExp(r'^0+')),
        LengthLimitingTextInputFormatter(country.maxLength),
      ],
      prefix: CountryCodePrefix(
        code: '+${country.dialCode}',
        flag: country.flag,
        onTap: () => _pickCountry(context),
      ),
      validator: (value) {
        final phone = value?.trim() ?? '';
        if (phone.isEmpty) return 'Please enter your phone number';
        if (!country.acceptsLength(phone.length)) {
          return 'Please enter a valid ${country.lengthLabel}-digit phone number';
        }
        return null;
      },
    );
  }
}
