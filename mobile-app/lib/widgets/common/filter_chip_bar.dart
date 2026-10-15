import 'package:flutter/material.dart';

import '../../themes/app_fonts.dart';
import '../../themes/home_palette.dart';

/// A row of chips, one of which is selected, that scrolls sideways when the
/// labels do not fit. Works with any list of choices, e.g. an enum's values.
class FilterChipBar<T> extends StatelessWidget {
  const FilterChipBar({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    required this.labelFor,
  });

  final List<T> options;
  final T selected;
  final ValueChanged<T> onSelected;
  final String Function(T option) labelFor;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            ChoiceChip(
              selected: selected == options[i],
              label: Text(labelFor(options[i])),
              onSelected: (_) => onSelected(options[i]),
              selectedColor: palette.brandSoft,
              labelStyle: AppFonts.semiBold(
                color: selected == options[i]
                    ? palette.brand
                    : palette.textMuted,
                fontSize: 12,
              ),
              side: BorderSide(color: palette.cardBorder),
              backgroundColor: palette.card,
              showCheckmark: false,
            ),
          ],
        ],
      ),
    );
  }
}
