import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
        ? 'Past Due'
        : 'To Do';
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
                  ? LucideIcons.circleCheck
                  : LucideIcons.clipboardList,
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
                  ),
                  if (assignment.subject.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      assignment.subject,
                      style: AppFonts.regular(color: p.textMuted, fontSize: 13),
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
                LucideIcons.chevronRight,
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
    if (due == null) return 'No Due Date';
    final date = due.toLocal();
    return 'Due ${date.day}/${date.month}/${date.year}';
  }
}
