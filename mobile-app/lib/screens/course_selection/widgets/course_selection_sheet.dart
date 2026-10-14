import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/common/home_sheet_shell.dart';
import '../../auth/provider/auth_provider.dart';
import '../../auth/widgets/course_picker_card.dart';
import '../provider/course_selection_provider.dart';

/// Bottom sheet where a learner ticks the courses they are taking and saves
/// them. Open it with [CourseSelectionSheet.show].
class CourseSelectionSheet extends StatelessWidget {
  const CourseSelectionSheet({super.key});

  /// Resolves to true when the learner saved a new choice.
  static Future<bool> show(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HomeSheetShell(
        child: ChangeNotifierProvider(
          create: (_) => CourseSelectionProvider(
            initialSelection: {...?auth.user?.courseIds},
            applyUser: auth.updateUser,
          )..load(),
          child: const CourseSelectionSheet(),
        ),
      ),
    );
    return saved == true;
  }

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    final selection = context.watch<CourseSelectionProvider>();
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.78,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'My Courses',
                      style: AppFonts.bold(color: palette.text, fontSize: 18),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context, false),
                    icon: const Icon(LucideIcons.x),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _body(palette, selection),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.brand,
                    foregroundColor: palette.card,
                    minimumSize: const Size(0, 48),
                  ),
                  onPressed: selection.canSave
                      ? () async {
                          final saved = await selection.save();
                          if (saved && context.mounted) {
                            Navigator.pop(context, true);
                          }
                        }
                      : null,
                  child: Text(
                    selection.isSaving ? 'Saving...' : 'Save courses',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(HomePalette palette, CourseSelectionProvider selection) {
    final error = selection.errorMessage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CoursePickerCard(
          courses: selection.courses,
          selectedIds: selection.selected,
          onToggle: selection.toggle,
          isLoading: selection.isLoading,
        ),
        if (!selection.isLoading && selection.courses.isEmpty && error == null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'No active courses are available yet.',
              style: AppFonts.regular(color: palette.textMuted, fontSize: 14),
            ),
          ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    error,
                    style: AppFonts.medium(color: palette.error, fontSize: 13),
                  ),
                ),
                if (selection.courses.isEmpty)
                  TextButton(
                    onPressed: selection.load,
                    child: const Text('Retry'),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
