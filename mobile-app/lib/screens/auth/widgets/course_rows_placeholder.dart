import 'package:flutter/material.dart';

import '../../../themes/auth_theme.dart';
import '../../../widgets/common/loading_skeleton.dart';

/// Two shimmering rows the size of real course rows, shown while the course
/// list loads so the form does not jump when it arrives.
class CourseRowsPlaceholder extends StatelessWidget {
  const CourseRowsPlaceholder({super.key});

  /// Height of one course row (title and short subtitle).
  static const double rowHeight = 64;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AuthTheme.fieldRadius);
    return Semantics(
      label: 'Loading courses',
      excludeSemantics: true,
      child: Column(
        children: [
          LoadingSkeleton(
            height: rowHeight,
            width: double.infinity,
            borderRadius: radius,
          ),
          const SizedBox(height: 8),
          LoadingSkeleton(
            height: rowHeight,
            width: double.infinity,
            borderRadius: radius,
          ),
        ],
      ),
    );
  }
}
