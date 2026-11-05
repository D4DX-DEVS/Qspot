import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/common/surface_card.dart';
import '../../../widgets/common/tone_chip.dart';

/// A student's question for the teacher: status, subject, the question, who
/// asked, and the saved answer when there is one. Tap to answer or edit.
class FacultyQuestionCard extends StatelessWidget {
  const FacultyQuestionCard({
    super.key,
    required this.question,
    required this.studentName,
    this.studentClass = '',
    this.subject = '',
    this.answer,
    this.askedAt,
    required this.onTap,
  });

  final String question;
  final String studentName;
  final String studentClass;
  final String subject;
  final String? answer;
  final DateTime? askedAt;
  final VoidCallback onTap;

  bool get _answered => answer != null && answer!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final p = HomePalette.of(context);
    final asker = studentClass.isEmpty
        ? studentName
        : '$studentName · Class $studentClass';
    return Semantics(
      button: true,
      label:
          '$question. Asked by $asker. '
          '${_answered ? 'Answered' : 'Waiting for your answer'}',
      excludeSemantics: true,
      child: SurfaceCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ToneChip(
                  label: _answered ? 'Answered' : 'Waiting for You',
                  tone: _answered ? p.mint : p.amber,
                ),
                const Spacer(),
                if (askedAt != null)
                  Text(
                    _date(askedAt!),
                    style: AppFonts.regular(color: p.textMuted, fontSize: 12),
                  ),
              ],
            ),
            if (subject.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(subject, style: AppFonts.bold(color: p.brand, fontSize: 13)),
            ],
            const SizedBox(height: 6),
            Text(
              question,
              style: AppFonts.regular(color: p.text, fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 6),
            Text(
              'From $asker',
              style: AppFonts.regular(color: p.textMuted, fontSize: 12.5),
            ),
            if (_answered) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: p.brandSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  answer!.trim(),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.regular(
                    color: p.text,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  _answered ? LucideIcons.pencilLine : LucideIcons.reply,
                  color: p.brand,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  _answered ? 'Edit Answer' : 'Write an Answer',
                  style: AppFonts.bold(color: p.brand, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _date(DateTime date) {
    final d = date.toLocal();
    return '${d.day}/${d.month}/${d.year}';
  }
}
