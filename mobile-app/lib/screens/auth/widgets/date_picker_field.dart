import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/auth_theme.dart';
import '../../../widgets/animation/pressable_scale.dart';

/// Tappable field that shows a picked date ([valueText]) or the [hint].
/// Opening the picker is left to [onTap]. With [errorText] the border turns
/// red and the message shows underneath, like a text field's.
class DatePickerField extends StatelessWidget {
  const DatePickerField({
    super.key,
    required this.hint,
    required this.onTap,
    this.valueText,
    this.icon = LucideIcons.calendarDays,
    this.errorText,
  });

  final String hint;
  final VoidCallback onTap;
  final String? valueText;
  final IconData icon;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final inputTheme = Theme.of(context).inputDecorationTheme;
    final radius = BorderRadius.circular(AuthTheme.fieldRadius);
    // The fill lives on the Material (not the decorator) so the tap ripple
    // shows above it.
    final field = PressableScale(
      pressedScale: 0.98,
      child: Material(
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
              enabledBorder: errorText == null ? null : inputTheme.errorBorder,
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
      ),
    );
    if (errorText == null) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        field,
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
          child: Text(errorText!, style: inputTheme.errorStyle),
        ),
      ],
    );
  }
}
