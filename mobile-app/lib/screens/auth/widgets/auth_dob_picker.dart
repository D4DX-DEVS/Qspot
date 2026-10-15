import 'package:flutter/material.dart';

import 'auth_theme_scope.dart';

/// Opens the date-of-birth picker on the year list, so a teen taps their birth
/// year first. Resolves to null when the picker is dismissed.
///
/// The picker's dialog sits above the page's [AuthThemeScope], so the scope is
/// applied again to it here.
Future<DateTime?> showAuthDobPicker(BuildContext context, {DateTime? initial}) {
  final now = DateTime.now();
  return showDatePicker(
    context: context,
    initialDate: initial ?? DateTime(now.year - 12, now.month, now.day),
    firstDate: DateTime(now.year - 100),
    lastDate: now,
    initialDatePickerMode: DatePickerMode.year,
    builder: (context, child) => AuthThemeScope(child: child!),
  );
}
