import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qspot/screens/video/model/video_model.dart';
import 'package:qspot/screens/video/widgets/learn_note_sheet.dart';

VideoModel episode({
  String learnText = '',
  List<String> learnPoints = const [],
}) {
  return VideoModel(
    id: '1',
    caption: 'caption',
    title: 'Episode 30',
    video: 'https://example.com/clip',
    learnText: learnText,
    learnPoints: learnPoints,
  );
}

Future<void> openSheet(WidgetTester tester, VideoModel video) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  // The test font renders every glyph one em wide, so a heading that fits on a
  // phone still reports overflow here.
  final previousOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exception.toString().contains('A RenderFlex overflowed')) {
      return;
    }
    previousOnError?.call(details);
  };
  addTearDown(() => FlutterError.onError = previousOnError);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => LearnNoteSheet.show(context, video),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the note and key points written for that video', (
    tester,
  ) async {
    await openSheet(
      tester,
      episode(
        learnText: 'A short note about this episode.',
        learnPoints: const ['First point', 'Second point'],
      ),
    );

    expect(find.text('Learn — Quick Note'), findsOneWidget);
    expect(find.text('A short note about this episode.'), findsOneWidget);
    expect(find.text('KEY POINTS'), findsOneWidget);
    expect(find.text('First point'), findsOneWidget);
    expect(find.text('Second point'), findsOneWidget);
    expect(find.text('Episode 30'), findsOneWidget);
  });

  testWidgets('content is per video, not shared', (tester) async {
    await openSheet(tester, episode(learnText: 'Only this episode says this.'));

    expect(find.text('Only this episode says this.'), findsOneWidget);
    expect(find.text('A short note about this episode.'), findsNothing);
  });

  testWidgets('explains itself when the episode has no note yet', (
    tester,
  ) async {
    await openSheet(tester, episode());

    expect(
      find.text('This episode\'s quick note isn\'t ready yet.'),
      findsOneWidget,
    );
    expect(find.text('KEY POINTS'), findsNothing);
  });

  testWidgets('Got it closes the popup', (tester) async {
    await openSheet(tester, episode(learnText: 'Something to read.'));
    expect(find.text('Learn — Quick Note'), findsOneWidget);

    await tester.tap(find.text('Got It'));
    await tester.pumpAndSettle();

    expect(find.text('Learn — Quick Note'), findsNothing);
  });
}
