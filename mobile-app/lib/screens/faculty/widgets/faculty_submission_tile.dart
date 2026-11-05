import 'package:flutter/material.dart';

import '../../../themes/accent_tone.dart';
import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/common/initials_avatar.dart';
import '../../../widgets/common/surface_card.dart';
import '../../../widgets/common/tone_chip.dart';

/// One student's submission: who sent it, its status and mark, and a button
/// to mark it (or change the mark).
class FacultySubmissionTile extends StatelessWidget {
  const FacultySubmissionTile({
    super.key,
    required this.studentName,
    this.studentClass = '',
    required this.status,
    this.grade,
    this.maxPoints,
    this.submittedAt,
    required this.onMark,
  });

  final String studentName;
  final String studentClass;

  /// Server status: submitted, late, returned or graded.
  final String status;
  final num? grade;
  final num? maxPoints;
  final DateTime? submittedAt;
  final VoidCallback onMark;

  bool get _graded => status.toLowerCase() == 'graded';

  @override
  Widget build(BuildContext context) {
    final p = HomePalette.of(context);
    final details = [
      if (studentClass.isNotEmpty) 'Class $studentClass',
      if (submittedAt != null) 'Sent ${_date(submittedAt!)}',
    ].join(' · ');
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      child: Row(
        children: [
          InitialsAvatar(name: studentName, size: 42, ringWidth: 0),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  studentName,
                  style: AppFonts.bold(color: p.text, fontSize: 15),
                ),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    details,
                    style: AppFonts.regular(color: p.textMuted, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 8),
                ToneChip(label: _statusLabel(), tone: _tone(p)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: onMark,
            style: FilledButton.styleFrom(
              backgroundColor: _graded ? p.brandSoft : p.brand,
              foregroundColor: _graded ? p.brand : p.card,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              visualDensity: VisualDensity.compact,
            ),
            child: Text(
              _graded ? 'Edit' : 'Mark',
              style: AppFonts.bold(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel() {
    switch (status.toLowerCase()) {
      case 'graded':
        final mark = grade == null ? '' : ' ${_num(grade!)}';
        final out = maxPoints == null ? '' : ' / ${_num(maxPoints!)}';
        return 'Marked$mark$out';
      case 'late':
        return 'Sent Late';
      case 'returned':
        return 'Changes Asked';
      default:
        return 'To Review';
    }
  }

  AccentTone _tone(HomePalette p) {
    switch (status.toLowerCase()) {
      case 'graded':
        return p.mint;
      case 'late':
        return p.coral;
      case 'returned':
        return p.slate;
      default:
        return p.amber;
    }
  }

  String _num(num value) =>
      value == value.roundToDouble() ? value.toInt().toString() : '$value';

  String _date(DateTime date) {
    final d = date.toLocal();
    return '${d.day}/${d.month}/${d.year}';
  }
}
