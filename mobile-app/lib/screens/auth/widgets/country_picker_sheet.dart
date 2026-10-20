import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../themes/app_fonts.dart';
import '../model/phone_country.dart';
import '../provider/country_picker_provider.dart';
import 'auth_theme_scope.dart';
import 'country_results_list.dart';

/// Bottom sheet listing every country, with a search box, so a learner can
/// pick where their phone number is from.
class CountryPickerSheet extends StatelessWidget {
  const CountryPickerSheet({super.key, required this.selected});

  final PhoneCountry selected;

  /// Shows the sheet. Resolves to the country tapped, or null when the sheet
  /// is closed without choosing.
  static Future<PhoneCountry?> show(
    BuildContext context, {
    required PhoneCountry selected,
  }) {
    return showModalBottomSheet<PhoneCountry>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      // The sheet sits above the page's AuthThemeScope, so apply it again.
      builder: (_) =>
          AuthThemeScope(child: CountryPickerSheet(selected: selected)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return ChangeNotifierProvider(
      create: (_) => CountryPickerProvider(),
      child: Padding(
        padding: EdgeInsets.only(bottom: keyboard),
        child: SizedBox(
          // Clamped by the space above the keyboard when it is open.
          height: MediaQuery.sizeOf(context).height * 0.8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Choose your country',
                  style: AppFonts.bold(color: colors.onSurface, fontSize: 18),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Builder(
                  builder: (context) => TextField(
                    onChanged: context.read<CountryPickerProvider>().setQuery,
                    textInputAction: TextInputAction.search,
                    style: AppFonts.regular(
                      color: colors.onSurface,
                      fontSize: 16,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Search country or code',
                      prefixIcon: Icon(LucideIcons.search, size: 20),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Consumer<CountryPickerProvider>(
                  builder: (_, picker, __) => CountryResultsList(
                    countries: picker.results,
                    selected: selected,
                    onPick: (country) => Navigator.of(context).pop(country),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
