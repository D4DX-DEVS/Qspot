import 'package:flutter/material.dart';

import '../../../themes/app_fonts.dart';

/// Warns a student who logs out while quiz answers on this phone have not
/// reached the server: logging out deletes them. Resolves to true only for
/// "Log Out and Delete".
class QuizLogoutWarningDialog extends StatelessWidget {
  const QuizLogoutWarningDialog({super.key, required this.unsentQuizzes});

  /// How many quizzes have answers not yet sent.
  final int unsentQuizzes;

  static Future<bool> show(BuildContext context, int unsentQuizzes) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => QuizLogoutWarningDialog(unsentQuizzes: unsentQuizzes),
    );
    return confirmed ?? false;
  }

  static String message(int unsentQuizzes) {
    final what = unsentQuizzes == 1 ? '1 quiz' : '$unsentQuizzes quizzes';
    return 'You have answers for $what that have not been sent yet. If you log '
        'out now, they will be deleted from this phone and cannot be marked.\n\n'
        'Stay logged in and open the app with an internet connection to send '
        'them.';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(
        'Unsent Quiz Answers',
        style: AppFonts.bold(color: scheme.onSurface, fontSize: 20),
      ),
      content: Text(
        message(unsentQuizzes),
        style: AppFonts.regular(
          color: scheme.onSurfaceVariant,
          fontSize: 15,
          height: 1.5,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: scheme.error),
          child: const Text('Log Out and Delete'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Stay Logged In'),
        ),
      ],
    );
  }
}
