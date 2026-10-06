import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../themes/app_fonts.dart';
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

enum _AssignmentView { todo, history, all }

class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  final AssignmentsScreenProvider _list = AssignmentsScreenProvider();
  _AssignmentView _view = _AssignmentView.todo;

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
      appBar: CommonAppBar(
        title: 'Assignments',
        actions: [
          IconButton(
            tooltip: 'Assignment history',
            onPressed: () => setState(() => _view = _AssignmentView.history),
            icon: const Icon(LucideIcons.history),
          ),
          const SizedBox(width: 8),
        ],
      ),
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
          final visible = switch (_view) {
            _AssignmentView.todo =>
              sorted.where((item) => !item.isSubmitted).toList(),
            _AssignmentView.history =>
              sorted.where((item) => item.isSubmitted).toList(),
            _AssignmentView.all => sorted,
          };
          return RefreshIndicator(
            onRefresh: _reload,
            backgroundColor: p.card,
            color: p.brand,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                AppTheme.contentInset,
                8,
                AppTheme.contentInset,
                28 + MediaQuery.paddingOf(context).bottom,
              ),
              itemCount: visible.length + (visible.isEmpty ? 2 : 1),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _AssignmentViewPicker(
                      selected: _view,
                      onChanged: (value) => setState(() => _view = value),
                      counts: (
                        todo: sorted.where((item) => !item.isSubmitted).length,
                        history: sorted
                            .where((item) => item.isSubmitted)
                            .length,
                        all: sorted.length,
                      ),
                    ),
                  );
                }
                if (visible.isEmpty) {
                  return SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.45,
                    child: StateMessageView(
                      icon: _view == _AssignmentView.history
                          ? LucideIcons.history
                          : LucideIcons.clipboardList,
                      title: _view == _AssignmentView.history
                          ? 'No Assignment History Yet'
                          : 'No Assignments To Do',
                      message: _view == _AssignmentView.history
                          ? 'Submitted assignments will appear here.'
                          : 'You have no pending assignments right now.',
                    ),
                  );
                }
                final item = visible[index - 1];
                return StaggeredEntrance(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
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

class _AssignmentViewPicker extends StatelessWidget {
  const _AssignmentViewPicker({
    required this.selected,
    required this.onChanged,
    required this.counts,
  });

  final _AssignmentView selected;
  final ValueChanged<_AssignmentView> onChanged;
  final ({int todo, int history, int all}) counts;

  @override
  Widget build(BuildContext context) {
    final p = HomePalette.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip(context, p, _AssignmentView.todo, 'To do', counts.todo),
          const SizedBox(width: 8),
          _chip(context, p, _AssignmentView.history, 'History', counts.history),
          const SizedBox(width: 8),
          _chip(context, p, _AssignmentView.all, 'All', counts.all),
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context,
    HomePalette p,
    _AssignmentView value,
    String label,
    int count,
  ) {
    return ChoiceChip(
      selected: selected == value,
      label: Text('$label ($count)'),
      onSelected: (_) => onChanged(value),
      selectedColor: p.brandSoft,
      labelStyle: AppFonts.semiBold(
        color: selected == value ? p.brand : p.textMuted,
        fontSize: 12,
      ),
      side: BorderSide(color: p.cardBorder),
      backgroundColor: p.card,
      showCheckmark: false,
    );
  }
}
