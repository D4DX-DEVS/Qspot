import 'package:flutter/material.dart';

import '../../../themes/app_theme.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/common/banner_headline.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../../../widgets/common/gradient_card.dart';
import '../../../widgets/common/info_note_card.dart';
import '../../assignment/screens/assignments_screen.dart';
import '../../auth/widgets/art/auth_art.dart';
import '../../auth/widgets/art/mosque_skyline_painter.dart';
import '../../quiz/screens/quiz_list_screen.dart';
import '../widgets/practice_action_card.dart';

/// A single home for every assessed learning action.
class PracticeHubScreen extends StatelessWidget {
  const PracticeHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    return Scaffold(
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
          const SizedBox(width: 8),
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
          GradientCard(
            minHeight: 156,
            artSize: const Size(150, 108),
            art: AuthArt(
              painter: (art) => MosqueSkylinePainter(art, showSkyline: false),
            ),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: const BannerHeadline(
              title: 'A calm place to try',
              subtitle: 'Build confidence one small attempt at a time.',
              titleSize: 22,
              trailingWidth: 90,
            ),
          ),
          const SizedBox(height: 18),
          PracticeActionCard(
            icon: Icons.assignment_outlined,
            tone: palette.amber,
            title: 'Assignments',
            body:
                'See what is due, submit your work, and read teacher feedback.',
            action: 'Open assignments',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AssignmentsScreen()),
            ),
          ),
          const SizedBox(height: 14),
          PracticeActionCard(
            icon: Icons.edit_note_rounded,
            tone: palette.coral,
            title: 'Quizzes and exams',
            body:
                'Take a short knowledge quiz or show your skills in a practical exam.',
            action: 'Open practice',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const QuizListScreen()),
            ),
          ),
          const SizedBox(height: 18),
          InfoNoteCard(
            icon: Icons.lightbulb_outline_rounded,
            tone: palette.amber,
            message:
                'Practice is not a score board. It is a safe place to notice what you know next.',
          ),
        ],
      ),
    );
  }
}
