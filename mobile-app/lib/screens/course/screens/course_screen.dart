import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../services/course_service.dart';
import '../../../themes/app_colors.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/common/app_snack_bar.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../../../widgets/common/state_message_view.dart';
import '../../assignment/model/assignment_model.dart';
import '../../assignment/screens/assignment_detail_screen.dart';
import '../../progress/widgets/mastery_ring_card.dart';
import '../../subject/provider/subject_provider.dart';
import '../../video/provider/video_provider.dart';
import '../../common/widgets/home_theme_scope.dart';
import '../../lesson/screens/lesson_screen.dart';
import '../model/course_tab.dart';
import '../model/syllabus_lesson.dart';
import '../provider/course_screen_provider.dart';
import '../widgets/course_about_view.dart';
import '../widgets/course_assignments_section.dart';
import '../widgets/course_continue_bar.dart';
import '../widgets/course_grades_view.dart';
import '../widgets/course_tab_bar.dart';
import '../widgets/syllabus_chapter_card.dart';

/// One course: how far the learner is, then tabs for the syllabus (chapter by
/// chapter), the course's assignments, its grades
/// and what the course is about.
class CourseScreen extends StatelessWidget {
  const CourseScreen({super.key, required this.course});

  final CourseModel course;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CourseScreenProvider.forApp(
        course: course,
        videos: context.read<VideoProvider>(),
        subjects: context.read<SubjectProvider>(),
      )..load(),
      child: Consumer<CourseScreenProvider>(
        builder: (context, state, _) => _buildPage(context, state),
      ),
    );
  }

  Widget _buildPage(BuildContext context, CourseScreenProvider state) {
    final label = state.continueLabel;
    return Scaffold(
      appBar: CommonAppBar(title: course.title),
      body: RefreshIndicator(
        onRefresh: () => Future.wait([state.refreshProgress(), state.load()]),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            28 + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            MasteryRingCard(
              percent: state.syllabus.summary.lessons.fraction,
              title: state.summaryTitle,
              detail: state.summaryDetail,
              highlight: state.gradeAverageLabel,
              highlightColor: HomePalette.of(context).brand,
            ),
            const SizedBox(height: 14),
            CourseTabBar(selected: state.tab, onSelected: state.selectTab),
            const SizedBox(height: 14),
            ...switch (state.tab) {
              CourseTab.syllabus => _syllabus(context, state),
              CourseTab.assignments => [
                CourseAssignmentsSection(
                  assignments: state.assignments,
                  loading: state.isLoadingAssignments,
                  onTap: (assignment) =>
                      _openAssignment(context, state, assignment),
                ),
              ],
              CourseTab.grades => [
                CourseGradesView(
                  entries: state.grades,
                  loading: state.isLoadingAssignments,
                ),
              ],
              CourseTab.about => [CourseAboutView(course: course)],
            },
          ],
        ),
      ),
      bottomNavigationBar: label == null
          ? null
          : CourseContinueBar(
              label: label,
              onPressed: () => _openLesson(context, state, state.nextLesson!),
            ),
    );
  }

  List<Widget> _syllabus(BuildContext context, CourseScreenProvider state) {
    if (state.syllabus.isEmpty) {
      return const [
        SizedBox(
          height: 260,
          child: StateMessageView(
            icon: LucideIcons.bookOpen,
            title: 'No Lessons Yet',
            message: 'Lessons for this course will appear here.',
          ),
        ),
      ];
    }
    return [
      for (final chapter in state.syllabus.chapters)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SyllabusChapterCard(
            chapter: chapter,
            expanded: state.isExpanded(chapter.id),
            onToggle: () => state.toggleChapter(chapter.id),
            onLessonTap: (lesson) => _openLesson(context, state, lesson),
          ),
        ),
    ];
  }

  Future<void> _openLesson(
    BuildContext context,
    CourseScreenProvider state,
    SyllabusLesson lesson,
  ) async {
    final blocked = lesson.blockedMessage;
    if (blocked != null) {
      AppSnackBar.show(
        context,
        message: blocked,
        color: AppColors.warningOrange,
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            HomeThemeScope(child: LessonScreen(video: lesson.video)),
      ),
    );
    // A lesson finished meanwhile shows as done.
    await state.refreshProgress();
  }

  Future<void> _openAssignment(
    BuildContext context,
    CourseScreenProvider state,
    AssignmentModel assignment,
  ) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AssignmentDetailScreen(assignment: assignment),
      ),
    );
    if (changed == true) await state.load();
  }
}
