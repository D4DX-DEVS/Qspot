import 'package:flutter/material.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/auth_theme.dart';

/// Class picker (1 to 12 by default). Values are the bare numbers the API
/// expects, shown as "Class N".
class ClassDropdownField extends StatelessWidget {
  const ClassDropdownField({
    super.key,
    required this.value,
    required this.onChanged,
    this.hint = 'Class (for example 9, 10, 11)',
    this.classes = defaultClasses,
  });

  static const List<String> defaultClasses = [
    '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', //
  ];

  final String? value;
  final ValueChanged<String?> onChanged;
  final String hint;
  final List<String> classes;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    // Aligned mode drops Flutter's default 16/24 pt side margins, so the
    // open list is exactly as wide as the field.
    return ButtonTheme(
      alignedDropdown: true,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        onChanged: onChanged,
        validator: (selected) =>
            selected == null ? 'Please choose your class' : null,
        items: [
          for (final item in classes)
            DropdownMenuItem(value: item, child: Text('Class $item')),
        ],
        style: AppFonts.regular(color: colors.onSurface, fontSize: 16),
        icon: const Icon(Icons.keyboard_arrow_down_rounded),
        iconEnabledColor: colors.onSurface,
        borderRadius: BorderRadius.circular(AuthTheme.fieldRadius),
        menuMaxHeight: 360,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.school_outlined, size: 22),
        ),
      ),
    );
  }
}
