import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qspot/screens/auth/widgets/course_picker_card.dart';
import 'package:qspot/screens/auth/widgets/course_rows_placeholder.dart';
import 'package:qspot/services/course_service.dart';
import 'package:qspot/widgets/common/loading_skeleton.dart';

Future<void> _pump(
  WidgetTester tester, {
  required List<CourseModel> courses,
  required bool isLoading,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: CoursePickerCard(
            courses: courses,
            selectedIds: const {},
            onToggle: (_, _) {},
            isLoading: isLoading,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('loading shows the title and two placeholder rows', (
    tester,
  ) async {
    await _pump(tester, courses: const [], isLoading: true);
    expect(find.text('Choose Your Courses'), findsOneWidget);
    expect(find.byType(CourseRowsPlaceholder), findsOneWidget);
    expect(find.byType(LoadingSkeleton), findsNWidgets(2));
  });

  testWidgets('loaded shows the courses and no placeholders', (tester) async {
    await _pump(
      tester,
      courses: const [CourseModel(id: '1', title: 'Quran Basics')],
      isLoading: false,
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Quran Basics'), findsOneWidget);
    expect(find.byType(LoadingSkeleton), findsNothing);
  });

  testWidgets('no courses and not loading shows nothing', (tester) async {
    await _pump(tester, courses: const [], isLoading: false);
    expect(find.text('Choose Your Courses'), findsNothing);
    expect(find.byType(LoadingSkeleton), findsNothing);
  });
}
