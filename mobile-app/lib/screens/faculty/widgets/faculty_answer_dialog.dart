import 'package:flutter/material.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/home_field_decoration.dart';
import '../../../themes/home_palette.dart';
import '../../common/widgets/home_theme_scope.dart';

/// Popup where the teacher writes (or edits) the answer to a student's
/// question. Shows the question above the box so it stays in view while
/// typing.
class FacultyAnswerDialog extends StatelessWidget {
  const FacultyAnswerDialog({
    super.key,
    required this.question,
    required this.controller,
  });

  final String question;
  final TextEditingController controller;

  /// The trimmed answer, or null when cancelled.
  static Future<String?> show(
    BuildContext context, {
    required String question,
    String initialAnswer = '',
  }) async {
    final controller = TextEditingController(text: initialAnswer);
    final answer = await showDialog<String>(
      context: context,
      builder: (_) => HomeThemeScope(
        child: FacultyAnswerDialog(question: question, controller: controller),
      ),
    );
    controller.dispose();
    return answer;
  }

  @override
  Widget build(BuildContext context) {
    final p = HomePalette.of(context);
    return AlertDialog(
      title: Text(
        'Answer Student Question',
        style: AppFonts.bold(color: p.text, fontSize: 19),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.regular(
                color: p.textMuted,
                fontSize: 14,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              maxLines: 6,
              maxLength: 10000,
              autofocus: true,
              style: AppFonts.regular(color: p.text, fontSize: 15),
              decoration: HomeFieldDecoration.of(
                context,
                hint: 'Write a Clear Answer',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: const Text('Save Answer'),
        ),
      ],
    );
  }
}
