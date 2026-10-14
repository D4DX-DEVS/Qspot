import 'package:flutter/material.dart';

import '../../../widgets/common/filter_chip_bar.dart';
import '../model/grade_filter.dart';

/// Chips that narrow the grades list by kind, each with how many it holds.
class GradeFilterBar extends StatelessWidget {
  const GradeFilterBar({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.countFor,
  });

  final GradeFilter selected;
  final ValueChanged<GradeFilter> onSelected;
  final int Function(GradeFilter filter) countFor;

  @override
  Widget build(BuildContext context) {
    return FilterChipBar<GradeFilter>(
      options: GradeFilter.values,
      selected: selected,
      onSelected: onSelected,
      labelFor: (filter) => '${filter.label} (${countFor(filter)})',
    );
  }
}
