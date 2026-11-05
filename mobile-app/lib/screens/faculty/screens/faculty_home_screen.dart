import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../../../services/api_client.dart';
import '../provider/faculty_home_screen_provider.dart';
import 'package:qspot/themes/app_colors.dart';
import 'package:qspot/widgets/common/app_snack_bar.dart';
import 'package:qspot/widgets/common/home_sheet_shell.dart';
import 'package:qspot/widgets/common/home_tab_bar.dart';
import 'package:qspot/widgets/common/state_message_view.dart';
import '../../assignment/model/rubric_score.dart';
import '../../common/widgets/home_theme_scope.dart';
import '../model/rubric_spec.dart';
import '../widgets/faculty_answer_dialog.dart';
import '../widgets/faculty_assignment_tile.dart';
import '../widgets/faculty_grade_dialog.dart';
import '../widgets/faculty_lesson_tile.dart';
import '../widgets/faculty_question_card.dart';
import '../widgets/faculty_submission_tile.dart';
import '../widgets/faculty_submissions_sheet.dart';
import '../widgets/faculty_tab_list.dart';
import '../widgets/rubric_grade_dialog.dart';

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

  static Map<String, dynamic> _map(dynamic raw) =>
      raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};

  static String _ref(dynamic ref, String key) =>
      ref is Map ? ref[key]?.toString() ?? '' : '';

  static DateTime? _date(dynamic value) =>
      value == null ? null : DateTime.tryParse(value.toString());

  static int _count(dynamic value) => value is num ? value.toInt() : 0;

  Future<void> _answer(Map<String, dynamic> question) async {
    final answer = await FacultyAnswerDialog.show(
      context,
      question: question['description']?.toString() ?? '',
      initialAnswer: question['answer']?.toString() ?? '',
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

  Widget _questionsTab(FacultyHomeScreenProvider f) {
    final pending = f.pendingQuestions;
    return FacultyTabList(
      title: 'Questions Assigned to You',
      subtitle: f.questions.isEmpty
          ? null
          : pending == 0
          ? 'All questions answered'
          : '$pending waiting for your answer',
      itemCount: f.questions.length,
      emptyIcon: LucideIcons.messagesSquare,
      emptyTitle: 'No Questions Yet',
      emptyMessage: 'Questions students send to you will show up here.',
      onRefresh: _load,
      itemBuilder: (context, index) {
        final q = _map(f.questions[index]);
        final student = _ref(q['user'], 'name');
        return FacultyQuestionCard(
          question: q['description']?.toString() ?? '',
          studentName: student.isEmpty ? 'Student' : student,
          studentClass: _ref(q['user'], 'class'),
          subject: q['subject']?.toString() ?? '',
          answer: q['answer']?.toString(),
          askedAt: _date(q['createdAt']),
          onTap: () => _answer(q),
        );
      },
    );
  }

  Widget _contentTab(FacultyHomeScreenProvider f) => FacultyTabList(
    title: 'Your Lessons',
    subtitle: f.content.isEmpty
        ? null
        : f.content.length == 1
        ? '1 lesson linked to your profile'
        : '${f.content.length} lessons linked to your profile',
    itemCount: f.content.length,
    emptyIcon: LucideIcons.circlePlay,
    emptyTitle: 'No Lessons Yet',
    emptyMessage: 'Lessons linked to your profile will show up here.',
    onRefresh: _load,
    itemBuilder: (context, index) {
      final item = _map(f.content[index]);
      return FacultyLessonTile(
        title: item['title']?.toString() ?? 'Lesson',
        subject: _ref(item['subject'], 'name'),
        isPublished: item['isPublished'] == true,
        durationSeconds: _count(item['durationSeconds']),
      );
    },
  );

  Widget _assignmentsTab(FacultyHomeScreenProvider f) {
    final pending = f.pendingSubmissions;
    return FacultyTabList(
      title: 'Assignments and Submissions',
      subtitle: f.assignments.isEmpty
          ? null
          : pending == 0
          ? 'Nothing waiting for a mark'
          : pending == 1
          ? '1 submission to review'
          : '$pending submissions to review',
      itemCount: f.assignments.length,
      emptyIcon: LucideIcons.clipboardList,
      emptyTitle: 'No Assignments Yet',
      emptyMessage: 'Assignments for your lessons will show up here.',
      onRefresh: _load,
      itemBuilder: (context, index) {
        final item = _map(f.assignments[index]);
        final subject = _ref(item['subjectId'], 'name');
        return FacultyAssignmentTile(
          title: item['title']?.toString() ?? 'Assignment',
          subject: subject.isNotEmpty
              ? subject
              : _ref(item['videoId'], 'title'),
          dueAt: _date(item['dueAt']),
          submissionCount: _count(item['submissionCount']),
          pendingCount: _count(item['pendingSubmissions']),
          onTap: () => _showSubmissions(item),
        );
      },
    );
  }

  Future<void> _showSubmissions(Map<String, dynamic> assignment) async {
    try {
      final data = await ApiClient.get(
        '/api/faculty/assignments/${assignment['_id']}/submissions',
      );
      final submissions = data is Map && data['submissions'] is List
          ? data['submissions'] as List
          : const [];
      if (!mounted) return;
      final maxPoints = num.tryParse(assignment['maxPoints']?.toString() ?? '');
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => HomeSheetShell(
          child: FacultySubmissionsSheet(
            title: assignment['title']?.toString() ?? 'Submissions',
            itemCount: submissions.length,
            itemBuilder: (context, index) {
              final s = _map(submissions[index]);
              final student = _ref(s['userId'], 'name');
              return FacultySubmissionTile(
                studentName: student.isEmpty ? 'Student' : student,
                studentClass: _ref(s['userId'], 'class'),
                status: s['status']?.toString() ?? 'submitted',
                grade: num.tryParse(s['grade']?.toString() ?? ''),
                maxPoints: maxPoints,
                submittedAt: _date(s['submittedAt']),
                onMark: () => _gradeSubmission(s, assignment, sheetContext),
              );
            },
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
    // Marked by parts: a score for each part instead of one number.
    final rubric = RubricSpec.fromJson(assignment['rubric']);
    if (rubric.isOn) {
      final marked = await RubricGradeDialog.show(
        context,
        rubric: rubric,
        initialScores: RubricScore.listFrom(submission['rubricScores']),
        feedback: submission['feedback']?.toString() ?? '',
      );
      if (marked == null || !sheetContext.mounted) return;
      await _saveGrade(submission, sheetContext, {
        'rubricScores': marked.points,
        'feedback': marked.feedback,
      });
      return;
    }
    final grade = TextEditingController(
      text: submission['grade']?.toString() ?? '',
    );
    final feedback = TextEditingController(
      text: submission['feedback']?.toString() ?? '',
    );
    final formKey = GlobalKey<FormState>();
    final parsedMaxPoints = double.tryParse(
      assignment['maxPoints']?.toString() ?? '',
    );
    final maxPoints =
        parsedMaxPoints != null &&
            parsedMaxPoints.isFinite &&
            parsedMaxPoints > 0
        ? parsedMaxPoints
        : 100.0;
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => HomeThemeScope(
        child: FacultyGradeDialog(
          formKey: formKey,
          grade: grade,
          feedback: feedback,
          maxPointsLabel: '${assignment['maxPoints'] ?? 100}',
          gradeValidator: (value) {
            final raw = value?.trim() ?? '';
            final parsed = double.tryParse(raw);
            if (raw.isEmpty) return 'Grade is required';
            if (parsed == null || !parsed.isFinite) {
              return 'Enter a valid number';
            }
            if (parsed < 0) return 'Grade cannot be negative';
            if (parsed > maxPoints) {
              return 'Grade cannot exceed $maxPoints';
            }
            return null;
          },
        ),
      ),
    );
    if (result != true) {
      grade.dispose();
      feedback.dispose();
      return;
    }
    final gradeValue = double.parse(grade.text.trim());
    final feedbackValue = feedback.text.trim();
    grade.dispose();
    feedback.dispose();
    if (!sheetContext.mounted) return;
    await _saveGrade(submission, sheetContext, {
      'grade': gradeValue,
      'feedback': feedbackValue,
    });
  }

  Future<void> _saveGrade(
    Map<String, dynamic> submission,
    BuildContext sheetContext,
    Map<String, dynamic> body,
  ) async {
    try {
      await ApiClient.put(
        '/api/faculty/submissions/${submission['_id']}/grade',
        body: body,
      );
      if (mounted && sheetContext.mounted) {
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
  Widget build(BuildContext context) => HomeThemeScope(
    child: ChangeNotifierProvider.value(
      value: _f,
      child: Consumer<FacultyHomeScreenProvider>(
        builder: (_, f, _) => _buildPage(f),
      ),
    ),
  );

  Widget _buildPage(FacultyHomeScreenProvider f) => DefaultTabController(
    length: 3,
    child: Scaffold(
      appBar: CommonAppBar(
        title: 'Faculty Workspace',
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _load,
            icon: const Icon(LucideIcons.refreshCw),
          ),
          const SizedBox(width: 4),
        ],
        bottom: const HomeTabBar(
          labels: ['Questions', 'Lessons', 'Assignments'],
        ),
      ),
      body: f.loading
          ? const Center(child: CircularProgressIndicator())
          : f.error != null
          ? StateMessageView(
              icon: LucideIcons.cloudOff,
              title: 'Could Not Load Your Workspace',
              message: f.error,
              onRetry: _load,
            )
          : TabBarView(
              children: [_questionsTab(f), _contentTab(f), _assignmentsTab(f)],
            ),
    ),
  );
}
