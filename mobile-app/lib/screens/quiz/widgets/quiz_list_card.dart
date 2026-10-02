import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../themes/accent_tone.dart';
import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/common/soft_icon_tile.dart';
import '../../../widgets/common/surface_card.dart';
import '../../../widgets/common/tone_chip.dart';
import '../model/quiz_model.dart';

/// One quiz in the list: tinted icon, title, type, question count, start date
/// or the learner's score, and a status chip (live, upcoming, ended, attempted).
class QuizListCard extends StatelessWidget {
  const QuizListCard({super.key, required this.quiz, required this.onTap});

  final QuizListItem quiz;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = HomePalette.of(context);
    final attempt = quiz.myAttempt;
    final practical = quiz.assessmentType == 'practical';
    final tone = _tone(p);
    final status = _status;
    final count =
        '${quiz.questionCount} Question${quiz.questionCount == 1 ? '' : 's'}';
    return Semantics(
      button: true,
      label: '${quiz.title}. $status. $count',
      excludeSemantics: true,
      child: SurfaceCard(
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SoftIconTile(
              icon: practical ? LucideIcons.wrench : LucideIcons.pencilLine,
              tone: tone,
              size: 46,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          quiz.title,
                          style: AppFonts.bold(color: p.text, fontSize: 15.5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ToneChip(label: status, tone: tone),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${practical ? 'Practical Exam' : 'Knowledge Quiz'} · $count',
                    style: AppFonts.regular(color: p.textMuted, fontSize: 13),
                  ),
                  if (quiz.isUpcoming && quiz.startDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Starts ${_formatDate(quiz.startDate!)}',
                      style: AppFonts.regular(color: p.textMuted, fontSize: 12),
                    ),
                  ],
                  if (attempt != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Your Score: ${attempt.score}/${attempt.totalQuestions} (${attempt.percentage}%)',
                      style: AppFonts.semiBold(color: p.brand, fontSize: 13.5),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _status => quiz.hasAttempted
      ? 'Attempted'
      : quiz.isLive
      ? 'Live'
      : quiz.isUpcoming
      ? 'Upcoming'
      : 'Ended';

  AccentTone _tone(HomePalette p) => quiz.hasAttempted
      ? p.rose
      : quiz.isLive
      ? p.mint
      : quiz.isUpcoming
      ? p.amber
      : p.slate;

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}
