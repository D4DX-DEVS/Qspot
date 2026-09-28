import 'package:flutter/material.dart';

import '../../../themes/app_theme.dart';
import '../../../themes/app_fonts.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../../assignment/screens/assignments_screen.dart';
import '../../quiz/screens/quiz_list_screen.dart';

/// A single home for every assessed learning action.
class PracticeHubScreen extends StatelessWidget {
  const PracticeHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: CommonAppBar(
        title: 'Practice',
        actions: [
          IconButton(
            tooltip: 'Practice history',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const QuizListScreen()),
            ),
            icon: const Icon(Icons.history_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppTheme.contentInset,
          8,
          AppTheme.contentInset,
          32 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          const _PracticeIntro(),
          const SizedBox(height: 18),
          _PracticeCard(
            icon: Icons.assignment_outlined,
            color: AppTheme.warning,
            title: 'Assignments',
            body:
                'See what is due, submit your work, and read teacher feedback.',
            action: 'Open assignments',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AssignmentsScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _PracticeCard(
            icon: Icons.edit_note_outlined,
            color: AppTheme.accent,
            title: 'Quizzes and exams',
            body:
                'Take a short knowledge quiz or show your skills in a practical exam.',
            action: 'Open practice',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const QuizListScreen()),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline_rounded, color: AppTheme.primary),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Practice is not a score board. It is a safe place to notice what you know next.',
                    style: AppFonts.regular(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PracticeIntro extends StatelessWidget {
  const _PracticeIntro();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('A calm place to try', style: AppTheme.sectionTitle),
        const SizedBox(height: 5),
        Text(
          'Build confidence one small attempt at a time.',
          style: AppTheme.sectionIntro,
        ),
      ],
    );
  }
}

class _PracticeCard extends StatelessWidget {
  const _PracticeCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    required this.action,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.border),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppFonts.extraBold(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      body,
                      style: AppFonts.regular(
                        color: AppTheme.textMuted,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      action,
                      style: AppFonts.extraBold(color: color, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: AppTheme.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
