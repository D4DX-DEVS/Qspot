import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../themes/app_theme.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../../../widgets/common/loading_skeleton.dart';
import '../../../widgets/common/state_message_view.dart';
import '../../progress/widgets/mastery_ring_card.dart';
import '../provider/grades_provider.dart';
import '../widgets/grade_filter_bar.dart';
import '../widgets/grade_tile.dart';

/// Every mark the learner has, in one place: quizzes, lesson practice and
/// assignments a teacher has marked.
class GradesScreen extends StatelessWidget {
  const GradesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GradesProvider()..load(),
      child: Consumer<GradesProvider>(
        builder: (context, grades, _) => _buildPage(context, grades),
      ),
    );
  }

  Widget _buildPage(BuildContext context, GradesProvider grades) {
    return Scaffold(
      appBar: const CommonAppBar(title: 'My Grades'),
      body: _body(context, grades),
    );
  }

  Widget _body(BuildContext context, GradesProvider grades) {
    if (grades.showSkeleton) return const LoadingSkeleton();
    if (grades.showError) {
      return StateMessageView(
        icon: LucideIcons.wifiOff,
        title: 'Could Not Load Grades',
        message: grades.error ?? 'Check your connection and try again.',
        onRetry: grades.load,
      );
    }
    if (grades.isEmpty) {
      return RefreshIndicator(
        onRefresh: grades.load,
        child: LayoutBuilder(
          builder: (context, box) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: box.maxHeight,
                child: const StateMessageView(
                  icon: LucideIcons.clipboardCheck,
                  title: 'No Grades Yet',
                  message:
                      'Your quiz, lesson practice and assignment marks will show up here.',
                ),
              ),
            ],
          ),
        ),
      );
    }

    final visible = grades.visible;
    return RefreshIndicator(
      onRefresh: grades.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          AppTheme.contentInset,
          8,
          AppTheme.contentInset,
          28 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          MasteryRingCard(
            percent: (grades.average ?? 0) / 100,
            title: '${(grades.average ?? 0).round()}% Average',
            detail:
                '${grades.entries.length} grade'
                '${grades.entries.length == 1 ? '' : 's'} so far',
          ),
          const SizedBox(height: 16),
          GradeFilterBar(
            selected: grades.filter,
            onSelected: grades.selectFilter,
            countFor: grades.countFor,
          ),
          const SizedBox(height: 12),
          if (visible.isEmpty)
            const SizedBox(
              height: 200,
              child: StateMessageView(
                icon: LucideIcons.clipboardCheck,
                title: 'Nothing Here Yet',
                message: 'No grades of this kind yet.',
              ),
            ),
          for (final entry in visible)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GradeTile(entry: entry),
            ),
        ],
      ),
    );
  }
}
