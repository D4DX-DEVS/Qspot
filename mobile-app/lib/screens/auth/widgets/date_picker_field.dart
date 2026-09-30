import 'package:flutter/material.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/auth_theme.dart';

/// Tappable field that shows a picked date ([valueText]) or the [hint].
/// Opening the picker is left to [onTap].
class DatePickerField extends StatelessWidget {
  const DatePickerField({
    super.key,
    required this.hint,
    required this.onTap,
    this.valueText,
    this.icon = Icons.calendar_month_outlined,
  });

  final String hint;
  final VoidCallback onTap;
  final String? valueText;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AuthTheme.fieldRadius);
    // The fill lives on the Material (not the decorator) so the tap ripple
    // shows above it.
    return Material(
      color: Theme.of(context).inputDecorationTheme.fillColor,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: InputDecorator(
          isEmpty: valueText == null,
          decoration: InputDecoration(
            hintText: hint,
            filled: false,
            prefixIcon: Icon(icon, size: 22),
          ),
          child: valueText == null
              ? null
              : Text(
                  valueText!,
                  style: AppFonts.regular(
                    color: colors.onSurface,
                    fontSize: 16,
                  ),
                ),
        ),
      ),
    );
  }
}
