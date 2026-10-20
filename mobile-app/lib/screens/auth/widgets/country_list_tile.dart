import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../themes/app_fonts.dart';
import '../model/phone_country.dart';

/// One row of the country picker: flag, name and calling code, with a tick
/// on the country already chosen.
class CountryListTile extends StatelessWidget {
  const CountryListTile({
    super.key,
    required this.country,
    required this.isSelected,
    required this.onTap,
  });

  final PhoneCountry country;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      selected: isSelected,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: Text(country.flag, style: const TextStyle(fontSize: 24)),
      title: Text(
        country.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppFonts.medium(color: colors.onSurface, fontSize: 15.5),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '+${country.dialCode}',
            style: AppFonts.regular(
              color: colors.onSurfaceVariant,
              fontSize: 15,
            ),
          ),
          if (isSelected) ...[
            const SizedBox(width: 10),
            Icon(LucideIcons.check, size: 20, color: colors.primary),
          ],
        ],
      ),
    );
  }
}
