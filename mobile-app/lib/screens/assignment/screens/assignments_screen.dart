import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../themes/app_theme.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/animation/staggered_entrance.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../../../widgets/common/loading_skeleton.dart';
import '../../../widgets/common/state_message_view.dart';
import '../../common/widgets/home_theme_scope.dart';
import '../model/assignment_model.dart';
import '../provider/assignments_screen_provider.dart';
import '../widgets/assignment_tile.dart';
import 'assignment_detail_screen.dart';

class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  final AssignmentsScreenProvider _list = AssignmentsScreenProvider();

  @override
  void dispose() {
    _list.dispose();
    super.dispose();
  }

  Future<void> _reload() => _list.reload();

  @override
  Widget build(BuildContext context) {
    // Burgundy home theme; the page reads colours from the context inside it.
    return HomeThemeScope(
      child: ChangeNotifierProvider.value(
        value: _list,
        child: Consumer<AssignmentsScreenProvider>(
          builder: (context, list, _) => _buildPage(context, list),
        ),
      ),
    );
  }

  Widget _buildPage(BuildContext context, AssignmentsScreenProvider list) {
    final p = HomePalette.of(context);
    return Scaffold(
      appBar: const CommonAppBar(title: 'Assignments'),
      body: FutureBuilder<List<AssignmentModel>>(
        future: list.assignments,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingSkeleton();
          }
          if (snapshot.hasError) {
            return StateMessageView(
              icon: LucideIcons.wifiOff,
              title: 'Could Not Load Assignments',
              message: 'Check your connection and try again.',
              onRetry: _reload,
            );
          }
          final assignments = snapshot.data ?? const <AssignmentModel>[];
          if (assignments.isEmpty) {
            return RefreshIndicator(
              onRefresh: _reload,
              backgroundColor: p.card,
              color: p.brand,
              child: LayoutBuilder(
                builder: (context, box) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: box.maxHeight,
                      child: const StateMessageView(
                        icon: LucideIcons.clipboardList,
                        title: 'You Are All Caught Up',
                        message:
                            'New assignments from your teachers will show up here.',
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          final sorted = [...assignments]
            ..sort((a, b) {
              if (a.isSubmitted != b.isSubmitted) return a.isSubmitted ? 1 : -1;
              final aDue = a.dueAt ?? DateTime(2100);
              final bDue = b.dueAt ?? DateTime(2100);
              return aDue.compareTo(bDue);
            });
          return RefreshIndicator(
            onRefresh: _reload,
            backgroundColor: p.card,
            color: p.brand,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                AppTheme.contentInset,
                8,
                AppTheme.contentInset,
                28 + MediaQuery.paddingOf(context).bottom,
              ),
              itemCount: sorted.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = sorted[index];
                return StaggeredEntrance(
                  index: index,
                  child: AssignmentTile(
                    assignment: item,
                    onTap: () async {
                      final changed = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AssignmentDetailScreen(assignment: item),
                        ),
                      );
                      if (changed == true && mounted) _reload();
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
