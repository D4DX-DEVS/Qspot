import 'package:flutter/material.dart';
import 'package:qspot/screens/assignment/model/assignment_model.dart';
import 'package:qspot/screens/assignment/screens/assignment_detail_screen.dart';
import 'package:qspot/screens/assignment/service/assignment_service.dart';
import 'package:qspot/themes/app_theme.dart';

class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  late Future<List<AssignmentModel>> _assignments;

  @override
  void initState() {
    super.initState();
    _assignments = AssignmentService.fetchAll();
  }

  Future<void> _reload() async {
    final request = AssignmentService.fetchAll();
    setState(() => _assignments = request);
    await request;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assignments')),
      body: FutureBuilder<List<AssignmentModel>>(
        future: _assignments,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _MessageState(
              icon: Icons.wifi_off_outlined,
              title: 'Could not load assignments',
              body: 'Check your connection and try again.',
              action: _reload,
            );
          }
          final assignments = snapshot.data ?? const <AssignmentModel>[];
          if (assignments.isEmpty) {
            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  _MessageState(
                    icon: Icons.assignment_outlined,
                    title: 'You are all caught up',
                    body:
                        'New assignments from your teachers will show up here.',
                  ),
                ],
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
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              itemCount: sorted.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = sorted[index];
                return _AssignmentTile(
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
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _AssignmentTile extends StatelessWidget {
  const _AssignmentTile({required this.assignment, required this.onTap});
  final AssignmentModel assignment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final overdue = assignment.isOverdue;
    final submitted = assignment.isSubmitted;
    final color = submitted
        ? AppTheme.success
        : overdue
        ? AppTheme.danger
        : AppTheme.primary;
    final label = submitted
        ? assignment.status.toLowerCase() == 'graded'
              ? 'Reviewed'
              : 'Submitted'
        : overdue
        ? 'Past due'
        : 'To do';
    return Material(
      color: AppTheme.background,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  submitted
                      ? Icons.check_circle_outline
                      : Icons.assignment_outlined,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignment.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (assignment.subject.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        assignment.subject,
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 7),
                    Text(
                      _dueLabel(assignment),
                      style: TextStyle(
                        color: overdue ? AppTheme.danger : AppTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(
                    Icons.chevron_right,
                    color: AppTheme.textMuted,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _dueLabel(AssignmentModel item) {
    if (item.dueAt == null) return 'No due date';
    final date = item.dueAt!.toLocal();
    final day = '${date.day}/${date.month}/${date.year}';
    return item.isSubmitted ? 'Due $day' : 'Due $day';
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });
  final IconData icon;
  final String title;
  final String body;
  final Future<void> Function()? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 42, color: AppTheme.textMuted),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textMuted),
          ),
          if (action != null) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: action,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ],
      ),
    ),
  );
}
