import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../themes/app_fonts.dart';

/// Themed single-line field. Pass an [icon], or a custom [prefix] widget
/// (such as a country code) that sizes itself.
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.icon,
    this.prefix,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final Widget? prefix;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      validator: validator,
      style: AppFonts.regular(color: colors.onSurface, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: prefix ?? (icon == null ? null : Icon(icon, size: 22)),
        prefixIconConstraints: prefix == null ? null : const BoxConstraints(),
      ),
    );
  }
}
