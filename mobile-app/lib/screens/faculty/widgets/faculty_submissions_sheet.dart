import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/common/soft_icon_tile.dart';

/// Bottom sheet body listing one assignment's submissions. Put it inside a
/// `HomeSheetShell`; [itemBuilder] builds each submission row.
class FacultySubmissionsSheet extends StatelessWidget {
  const FacultySubmissionsSheet({
    super.key,
    required this.title,
    required this.itemCount,
    required this.itemBuilder,
  });

  final String title;
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final p = HomePalette.of(context);
    final count = itemCount == 1 ? '1 submission' : '$itemCount submissions';
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: p.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppFonts.extraBold(color: p.text, fontSize: 19),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    count,
                    style: AppFonts.regular(color: p.textMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (itemCount == 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                child: Column(
                  children: [
                    SoftIconTile(
                      icon: LucideIcons.inbox,
                      tone: p.rose,
                      size: 64,
                      circle: true,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No Submissions Yet',
                      style: AppFonts.bold(color: p.text, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Work students send will show up here.',
                      textAlign: TextAlign.center,
                      style: AppFonts.regular(color: p.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  itemCount: itemCount,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: itemBuilder,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
