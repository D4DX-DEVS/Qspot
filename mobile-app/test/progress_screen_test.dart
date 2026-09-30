import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:qspot/screens/progress/screens/progress_screen.dart';
import 'package:qspot/screens/video/provider/video_provider.dart';
import 'package:qspot/services/learning_progress_service.dart';

void main() {
  testWidgets('progress presents mastery and recent work', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => VideoProvider())],
        child: MaterialApp(
          home: ProgressScreen(
            loadData: () async => LearningProgressData(
              videosTotal: 4,
              videosCompleted: 3,
              videosInProgress: 1,
              courses: const [
                MasteryItem(
                  id: 'c1',
                  title: 'Foundation course',
                  total: 4,
                  completed: 3,
                ),
              ],
              subjects: const [
                MasteryItem(id: 's1', title: 'Tajweed', total: 2, completed: 2),
              ],
              activities: const [
                ProgressActivity(
                  kind: 'quiz',
                  title: 'Weekly checkpoint',
                  score: 4,
                  totalQuestions: 5,
                  percentage: 80,
                  createdAt: null,
                ),
              ],
              stats: const LearningStats(
                currentStreak: 5,
                longestStreak: 9,
                xp: 120,
                level: 2,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Lesson mastery'), findsOneWidget);
    expect(find.text('3 of 4 started lessons complete'), findsOneWidget);
    expect(find.text('Foundation course'), findsOneWidget);
    expect(find.text('Chapters'), findsOneWidget);
    expect(find.text('Recent activity'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Weekly checkpoint'), 200);
    expect(find.text('Weekly checkpoint'), findsOneWidget);
    expect(find.text('4/5 correct - 80%'), findsOneWidget);
  });
}
