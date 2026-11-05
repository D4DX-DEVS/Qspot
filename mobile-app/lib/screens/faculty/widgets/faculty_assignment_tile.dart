import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/common/soft_icon_tile.dart';
import '../../../widgets/common/surface_card.dart';
import '../../../widgets/common/tone_chip.dart';

/// One assignment the teacher marks: title, subject, how much work waits for
/// review and the due date. Tap to open the submissions.
class FacultyAssignmentTile extends StatelessWidget {
  const FacultyAssignmentTile({
    super.key,
    required this.title,
    this.subject = '',
    this.dueAt,
    required this.submissionCount,
    required this.pendingCount,
    required this.onTap,
  });

  final String title;
  final String subject;
  final DateTime? dueAt;
  final int submissionCount;
  final int pendingCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = HomePalette.of(context);
    final tone = pendingCount > 0
        ? p.amber
        : submissionCount > 0
        ? p.mint
        : p.slate;
    final status = pendingCount > 0
        ? '$pendingCount to Review'
        : submissionCount > 0
        ? 'All Reviewed'
        : 'No Work Yet';
    final count = submissionCount == 1
        ? '1 submission'
        : '$submissionCount submissions';
    return Semantics(
      button: true,
      label: '$title. $status. $count. ${_dueLabel()}',
      excludeSemantics: true,
      child: SurfaceCard(
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SoftIconTile(icon: LucideIcons.clipboardList, tone: tone, size: 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppFonts.bold(color: p.text, fontSize: 15.5),
                  ),
                  if (subject.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      subject,
                      style: AppFonts.regular(color: p.textMuted, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ToneChip(label: status, tone: tone),
                      Text(
                        '$count · ${_dueLabel()}',
                        style: AppFonts.regular(
                          color: p.textMuted,
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
    final due = dueAt;
    if (due == null) return 'No Due Date';
    final date = due.toLocal();
    return 'Due ${date.day}/${date.month}/${date.year}';
  }
}
