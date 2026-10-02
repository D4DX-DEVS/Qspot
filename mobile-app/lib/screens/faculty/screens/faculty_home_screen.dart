import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../../../services/api_client.dart';
import '../provider/faculty_home_screen_provider.dart';
import 'package:qspot/themes/app_colors.dart';
import 'package:qspot/widgets/animation/pressable_scale.dart';
import 'package:qspot/widgets/animation/staggered_entrance.dart';
import 'package:qspot/widgets/common/app_snack_bar.dart';

class FacultyHomeScreen extends StatefulWidget {
  const FacultyHomeScreen({super.key});
  @override
  State<FacultyHomeScreen> createState() => _FacultyHomeScreenState();
}

class _FacultyHomeScreenState extends State<FacultyHomeScreen> {
  final FacultyHomeScreenProvider _f = FacultyHomeScreenProvider();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _f.dispose();
    super.dispose();
  }

  Future<void> _load() => _f.load();

  Future<void> _answer(Map<String, dynamic> question) async {
    final controller = TextEditingController(
      text: question['answer']?.toString() ?? '',
    );
    final answer = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Answer Student Question'),
        content: TextField(
          controller: controller,
          maxLines: 6,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Write a Clear Answer'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save Answer'),
          ),
        ],
      ),
    );
    if (answer == null || answer.isEmpty) return;
    try {
      await ApiClient.put(
        '/api/faculty/questions/${question['_id']}/answer',
        body: {'answer': answer},
      );
      await _load();
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context,
          message: e is ApiException
              ? e.message
              : 'We couldn\'t save your answer. Please try again.',
          color: AppColors.danger,
        );
      }
    }
  }

  Widget _questionsTab(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Text(
        'Questions Assigned to You',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 12),
      if (_f.questions.isEmpty)
        const Padding(
          padding: EdgeInsets.only(top: 50),
          child: Center(child: Text('No Questions Yet')),
        ),
      ..._f.questions.indexed.map((entry) {
        final (index, raw) = entry;
        final q = Map<String, dynamic>.from(raw as Map);
        final student = q['user'] is Map ? q['user']['name'] : 'Student';
        final answered =
            q['answer'] != null && q['answer'].toString().isNotEmpty;
        return StaggeredEntrance(
          index: index,
          child: PressableScale(
            pressedScale: 0.98,
            child: Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                isThreeLine: true,
                title: Text(q['description']?.toString() ?? ''),
                subtitle: Text(
                  '$student • ${q['subject'] ?? ''}\n${answered ? q['answer'] : 'Awaiting Your Answer'}',
                ),
                trailing: Icon(
                  answered ? LucideIcons.circleCheck : LucideIcons.reply,
                  color: answered
                      ? AppColors.success
                      : Theme.of(context).colorScheme.primary,
                ),
                onTap: () => _answer(q),
              ),
            ),
          ),
        );
      }),
    ],
  );

  Widget _contentTab(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Text('Your Lessons', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 12),
      if (_f.content.isEmpty) const Text('No lessons assigned yet.'),
      ..._f.content.indexed.map((entry) {
        final (index, raw) = entry;
        final item = Map<String, dynamic>.from(raw as Map);
        final subject = item['subject'] is Map ? item['subject']['name'] : '';
        final status = item['isPublished'] == true ? 'Published' : 'Draft';
        return StaggeredEntrance(
          index: index,
          child: Card(
            child: ListTile(
              leading: const Icon(LucideIcons.circlePlay),
              title: Text(item['title']?.toString() ?? 'Lesson'),
              subtitle: Text('$subject • $status'),
            ),
          ),
        );
      }),
    ],
  );

  Widget _assignmentsTab(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Text(
        'Assignments and Submissions',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 12),
      if (_f.assignments.isEmpty) const Text('No assignments assigned yet.'),
      ..._f.assignments.indexed.map((entry) {
        final (index, raw) = entry;
        final item = Map<String, dynamic>.from(raw as Map);
        return StaggeredEntrance(
          index: index,
          child: PressableScale(
            pressedScale: 0.98,
            child: Card(
              child: ListTile(
                leading: const Icon(LucideIcons.clipboardList),
                title: Text(item['title']?.toString() ?? 'Assignment'),
                subtitle: Text(
                  '${item['submissionCount'] ?? 0} Submissions • ${item['pendingSubmissions'] ?? 0} Awaiting Review',
                ),
                trailing: const Icon(LucideIcons.chevronRight),
                onTap: () => _showSubmissions(item),
              ),
            ),
          ),
        );
      }),
    ],
  );

  Future<void> _showSubmissions(Map<String, dynamic> assignment) async {
    try {
      final data = await ApiClient.get(
        '/api/faculty/assignments/${assignment['_id']}/submissions',
      );
      final submissions = data is Map && data['submissions'] is List
          ? data['submissions'] as List
          : const [];
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            shrinkWrap: true,
            children: [
              Text(
                assignment['title']?.toString() ?? 'Submissions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (submissions.isEmpty) const Text('No submissions yet.'),
              ...submissions.map((raw) {
                final s = Map<String, dynamic>.from(raw as Map);
                final student = s['userId'] is Map
                    ? s['userId']['name']
                    : 'Student';
                return ListTile(
                  title: Text(student.toString()),
                  subtitle: Text(
                    '${s['status'] ?? 'submitted'} • ${s['grade'] ?? 'Not Graded'}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(LucideIcons.messageSquareText),
                    onPressed: () => _gradeSubmission(s, assignment, context),
                  ),
                );
              }),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context,
          message: e is ApiException
              ? e.message
              : 'We couldn\'t load the submissions. Please try again.',
          color: AppColors.danger,
        );
      }
    }
  }

  Future<void> _gradeSubmission(
    Map<String, dynamic> submission,
    Map<String, dynamic> assignment,
    BuildContext sheetContext,
  ) async {
    final grade = TextEditingController(
      text: submission['grade']?.toString() ?? '',
    );
    final feedback = TextEditingController(
      text: submission['feedback']?.toString() ?? '',
    );
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Grade Submission'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: grade,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Grade (Max ${assignment['maxPoints'] ?? 100})',
              ),
            ),
            TextField(
              controller: feedback,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Feedback'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != true || grade.text.trim().isEmpty) return;
    try {
      await ApiClient.put(
        '/api/faculty/submissions/${submission['_id']}/grade',
        body: {
          'grade': double.tryParse(grade.text.trim()),
          'feedback': feedback.text.trim(),
        },
      );
      if (mounted) {
        Navigator.of(sheetContext).pop();
        _load();
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context,
          message: e is ApiException
              ? e.message
              : 'We couldn\'t save the grade. Please try again.',
          color: AppColors.danger,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider.value(
    value: _f,
    child: Consumer<FacultyHomeScreenProvider>(
      builder: (_, f, __) => _buildPage(f),
    ),
  );

  Widget _buildPage(FacultyHomeScreenProvider f) => DefaultTabController(
    length: 3,
    child: Scaffold(
      appBar: CommonAppBar(
        title: 'Faculty Workspace',
        actions: [
          IconButton(onPressed: _load, icon: const Icon(LucideIcons.refreshCw)),
        ],
        bottom: const TabBar(
          tabs: [
            Tab(text: 'Questions'),
            Tab(text: 'Lessons'),
            Tab(text: 'Assignments'),
          ],
        ),
      ),
      body: f.loading
          ? const Center(child: CircularProgressIndicator())
          : f.error != null
          ? Center(child: Text(f.error!))
          : RefreshIndicator(
              onRefresh: _load,
              child: TabBarView(
                children: [
                  _questionsTab(context),
                  _contentTab(context),
                  _assignmentsTab(context),
                ],
              ),
            ),
    ),
  );
}
