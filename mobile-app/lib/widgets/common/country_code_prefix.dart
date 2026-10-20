import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../themes/app_fonts.dart';

/// Flag + country code + divider for a phone field's `prefixIcon`.
///
/// Unlike `InputDecoration.prefixText`, a prefix icon is always visible, so an
/// empty, unfocused field still reads as a phone input. With [onTap] it shows
/// a down arrow and opens a country picker.
class CountryCodePrefix extends StatelessWidget {
  const CountryCodePrefix({
    super.key,
    this.code = '+91',
    this.flag = '🇮🇳',
    this.leftPadding = 18,
    this.onTap,
  });

  final String code;
  final String flag;
  final double leftPadding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final content = Padding(
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
          if (onTap != null) ...[
            const SizedBox(width: 2),
            Icon(
              LucideIcons.chevronDown,
              size: 18,
              color: colors.onSurfaceVariant,
            ),
          ],
          const SizedBox(width: 12),
          Container(width: 1, height: 22, color: colors.outline),
        ],
      ),
    );
    if (onTap == null) return content;
    return Semantics(
      button: true,
      label: 'Country code $code, change country',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(height: 48, child: content),
      ),
    );
  }
}
