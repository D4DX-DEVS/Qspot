import 'package:flutter/material.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/common/soft_icon_tile.dart';
import '../../../widgets/common/surface_card.dart';
import '../../../widgets/common/tone_chip.dart';
import '../model/assignment_model.dart';

/// One assignment in the list: tinted icon, title, subject, due date and a
/// status chip coloured by progress (to do, past due, submitted).
class AssignmentTile extends StatelessWidget {
  const AssignmentTile({
    super.key,
    required this.assignment,
    required this.onTap,
  });

  final AssignmentModel assignment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = HomePalette.of(context);
    final overdue = assignment.isOverdue;
    final submitted = assignment.isSubmitted;
    final tone = submitted
        ? p.mint
        : overdue
        ? p.coral
        : p.rose;
    final label = submitted
        ? assignment.status.toLowerCase() == 'graded'
              ? 'Reviewed'
              : 'Submitted'
        : overdue
        ? 'Past due'
        : 'To do';
    return Semantics(
      button: true,
      label: '${assignment.title}. $label. ${_dueLabel()}',
      excludeSemantics: true,
      child: SurfaceCard(
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SoftIconTile(
              icon: submitted
                  ? Icons.check_circle_outline_rounded
                  : Icons.assignment_outlined,
              tone: tone,
              size: 46,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    assignment.title,
                    style: AppFonts.bold(color: p.text, fontSize: 15.5),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (assignment.subject.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      assignment.subject,
                      style: AppFonts.regular(color: p.textMuted, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ToneChip(label: label, tone: tone),
                      Text(
                        _dueLabel(),
                        style: AppFonts.regular(
                          color: overdue && !submitted ? p.error : p.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Icon(
                Icons.chevron_right_rounded,
                color: p.textMuted,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _dueLabel() {
    final due = assignment.dueAt;
    if (due == null) return 'No due date';
    final date = due.toLocal();
    return 'Due ${date.day}/${date.month}/${date.year}';
  }
}
