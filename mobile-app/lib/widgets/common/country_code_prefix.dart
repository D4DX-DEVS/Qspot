import 'package:flutter/material.dart';

import '../../themes/app_fonts.dart';

/// Country code + divider for a phone field's `prefixIcon`.
///
/// Unlike `InputDecoration.prefixText`, a prefix icon is always visible, so an
/// empty, unfocused field still reads as a phone input.
class CountryCodePrefix extends StatelessWidget {
  const CountryCodePrefix({super.key, this.code = '+91'});

  final String code;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 18, right: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
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
