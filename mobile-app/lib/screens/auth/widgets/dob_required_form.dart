import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/dob_required_provider.dart';
import '../../../themes/app_colors.dart';
import '../../../widgets/common/app_snack_bar.dart';
import '../../common/screens/main_navigation_screen.dart';
import 'auth_dob_picker.dart';
import 'date_picker_field.dart';
import 'gradient_pill_button.dart';

/// The date picker and "Save and Continue" button of the add-your-date-of-birth
/// screen. Needs a [DobRequiredProvider] above it. Once the date is saved it
/// opens the app's main screen.
class DobRequiredForm extends StatelessWidget {
  const DobRequiredForm({super.key});

  @override
  Widget build(BuildContext context) {
    final form = context.watch<DobRequiredProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DatePickerField(
          hint: 'Date of Birth',
          valueText: form.dobText,
          onTap: () => _pick(context, form),
        ),
        const SizedBox(height: 24),
        GradientPillButton(
          label: 'Save and Continue',
          isLoading: form.isSaving,
          onPressed: form.canSave ? () => _save(context, form) : null,
        ),
      ],
    );
  }

  Future<void> _pick(BuildContext context, DobRequiredProvider form) async {
    final picked = await showAuthDobPicker(context, initial: form.dob);
    if (picked != null) form.setDob(picked);
  }

  Future<void> _save(BuildContext context, DobRequiredProvider form) async {
    final navigator = Navigator.of(context);
    final saved = await form.save();
    if (!context.mounted) return;
    if (saved) {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        (route) => false,
      );
    } else {
      AppSnackBar.show(
        context,
        message:
            form.errorMessage ??
            "We couldn't save your date of birth. Please try again.",
        color: AppColors.danger,
      );
    }
  }
}
