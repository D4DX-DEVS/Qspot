import 'package:flutter/material.dart';

import 'quiz_list_screen.dart';

/// Backward-compatible entry point. The real implementation moved to
/// [QuizListScreen] (the live-quiz-list "Option B" flow) — this file stays
/// as a thin alias so existing `QuizScreen()` call sites (e.g.
/// `lib/screens/home/screens/home_screen.dart`) keep working without an
/// extra nested Scaffold/AppBar. New navigation should push
/// [QuizListScreen] directly.
class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const QuizListScreen();
  }
}
