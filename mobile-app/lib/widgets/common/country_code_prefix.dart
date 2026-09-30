import 'package:flutter/material.dart';

import '../../themes/app_fonts.dart';

/// Flag + country code + divider for a phone field's `prefixIcon`.
///
/// Unlike `InputDecoration.prefixText`, a prefix icon is always visible, so an
/// empty, unfocused field still reads as a phone input.
class CountryCodePrefix extends StatelessWidget {
  const CountryCodePrefix({
    super.key,
    this.code = '+91',
    this.flag = '🇮🇳',
    this.leftPadding = 18,
  });

  final String code;
  final String flag;
  final double leftPadding;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(left: leftPadding, right: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(flag, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(
            code,
            style: AppFonts.medium(color: colors.onSurface, fontSize: 16),
          ),
          const SizedBox(width: 12),
          Container(width: 1, height: 22, color: colors.outline),
        ],
      ),
    );
  }
}
