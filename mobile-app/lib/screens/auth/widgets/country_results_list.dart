import 'package:flutter/material.dart';

import '../../../themes/app_fonts.dart';
import '../model/phone_country.dart';
import 'country_list_tile.dart';

/// The countries matching a search, or a short note when none do.
class CountryResultsList extends StatelessWidget {
  const CountryResultsList({
    super.key,
    required this.countries,
    required this.selected,
    required this.onPick,
  });

  final List<PhoneCountry> countries;
  final PhoneCountry selected;
  final ValueChanged<PhoneCountry> onPick;

  @override
  Widget build(BuildContext context) {
    if (countries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'No country matches your search.',
          textAlign: TextAlign.center,
          style: AppFonts.regular(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 14.5,
          ),
        ),
      );
    }
    return ListView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: countries.length,
      itemBuilder: (_, index) {
        final country = countries[index];
        return CountryListTile(
          country: country,
          isSelected: country.iso == selected.iso,
          onTap: () => onPick(country),
        );
      },
    );
  }
}
