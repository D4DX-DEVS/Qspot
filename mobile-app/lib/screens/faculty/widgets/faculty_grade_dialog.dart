import 'package:flutter/material.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/home_field_decoration.dart';
import '../../../themes/home_palette.dart';

/// Popup for one mark and feedback on a submission. Pops true on Save once
/// [formKey] validates, false on Cancel. Show it inside a `HomeThemeScope`.
class FacultyGradeDialog extends StatelessWidget {
  const FacultyGradeDialog({
    super.key,
    required this.formKey,
    required this.grade,
    required this.feedback,
    required this.maxPointsLabel,
    required this.gradeValidator,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController grade;
  final TextEditingController feedback;
  final String maxPointsLabel;
  final FormFieldValidator<String> gradeValidator;

  @override
  Widget build(BuildContext context) {
    final p = HomePalette.of(context);
    final fieldStyle = AppFonts.regular(color: p.text, fontSize: 15);
    return AlertDialog(
      title: Text(
        'Grade Submission',
        style: AppFonts.bold(color: p.text, fontSize: 19),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: grade,
                style: fieldStyle,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: HomeFieldDecoration.of(
                  context,
                  label: 'Grade (Max $maxPointsLabel)',
                ),
                validator: gradeValidator,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: feedback,
                style: fieldStyle,
                maxLines: 3,
                maxLength: 10000,
                decoration: HomeFieldDecoration.of(context, label: 'Feedback'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (formKey.currentState?.validate() != true) return;
            Navigator.pop(context, true);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
