import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../themes/app_theme.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/animation/staggered_entrance.dart';
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
        isDrawerNeeded: true,
        actions: [
          IconButton(
            tooltip: 'Practice History',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const QuizListScreen()),
            ),
            icon: const Icon(LucideIcons.history),
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
          StaggeredEntrance(
            child: GradientCard(
              minHeight: 156,
              artSize: const Size(150, 108),
              art: AuthArt(
                painter: (art) => MosqueSkylinePainter(art, showSkyline: false),
              ),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: const BannerHeadline(
                title: 'Ready to Level Up?',
                subtitle: 'Every try makes you sharper. Jump in!',
                titleSize: 22,
                trailingWidth: 90,
              ),
            ),
          ),
          const SizedBox(height: 18),
          StaggeredEntrance(
            index: 1,
            child: PracticeActionCard(
              icon: LucideIcons.clipboardList,
              tone: palette.amber,
              title: 'Assignments',
              body:
                  'See what is due, submit your work, and read teacher feedback.',
              action: 'Open Assignments',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AssignmentsScreen()),
              ),
            ),
          ),
          const SizedBox(height: 14),
          StaggeredEntrance(
            index: 2,
            child: PracticeActionCard(
              icon: LucideIcons.pencilLine,
              tone: palette.coral,
              title: 'Quizzes and Exams',
              body:
                  'Take a short knowledge quiz or show your skills in a practical exam.',
              action: 'Open Practice',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QuizListScreen()),
              ),
            ),
          ),
          const SizedBox(height: 18),
          StaggeredEntrance(
            index: 3,
            child: InfoNoteCard(
              icon: LucideIcons.lightbulb,
              tone: palette.amber,
              message:
                  'No pressure here. Try, miss, try again. That is how you level up.',
            ),
          ),
        ],
      ),
    );
  }
}
