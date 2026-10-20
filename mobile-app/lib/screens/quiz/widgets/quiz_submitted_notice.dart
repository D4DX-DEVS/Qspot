import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../widgets/common/notice_sheet.dart';
import '../model/answers_availability.dart';

/// "Answers Submitted" while the score is held back until the quiz closes:
/// shown right after submitting, and when a taken quiz is tapped in the list.
class QuizSubmittedNotice {
  const QuizSubmittedNotice._();

  static Future<void> show(BuildContext context, {DateTime? availableAt}) {
    return NoticeSheet.show(
      context,
      icon: LucideIcons.circleCheck,
      tone: (p) => p.mint,
      title: 'Answers Submitted',
      message: AnswersAvailability(
        revealed: false,
        availableAt: availableAt,
      ).submittedMessage(),
    );
  }
}
