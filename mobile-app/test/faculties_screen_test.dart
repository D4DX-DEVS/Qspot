import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:qspot/screens/speaker/model/speaker_model.dart';
import 'package:qspot/screens/speaker/provider/speaker_provider.dart';
import 'package:qspot/screens/speaker/screens/faculties_screen.dart';
import 'package:qspot/screens/video/model/video_model.dart';
import 'package:qspot/screens/video/provider/video_provider.dart';

SpeakerModel faculty({
  required String id,
  required String name,
  String designation = '',
}) {
  return SpeakerModel(id: id, name: name, designation: designation);
}

VideoModel episode({
  required String id,
  required String title,
  String? speakerId,
  String? speakerName,
}) {
  return VideoModel(
    id: id,
    caption: title,
    title: title,
    video: 'https://example.com/clip-$id',
    speakerId: speakerId,
    speakerName: speakerName,
  );
}

Future<void> pumpFaculties(
  WidgetTester tester, {
  required List<SpeakerModel> speakers,
  List<VideoModel> videos = const [],
}) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  // The test font is one em wide per glyph, so rows that fit on a device still
  // report overflow here.
  final previousOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exception.toString().contains('A RenderFlex overflowed')) {
      return;
    }
    previousOnError?.call(details);
  };
  addTearDown(() => FlutterError.onError = previousOnError);

  final speakerProvider = SpeakerProvider()..seedSpeakers(speakers);
  final videoProvider = VideoProvider()..seedVideos(videos);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: speakerProvider),
        ChangeNotifierProvider.value(value: videoProvider),
      ],
      child: const MaterialApp(home: FacultiesScreen()),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('shows one full profile per faculty', (tester) async {
    await pumpFaculties(
      tester,
      speakers: [
        faculty(
          id: 's1',
          name: 'Basheer Muhiyudheen',
          designation: 'Prominent Islamic scholar',
        ),
        faculty(id: 's2', name: 'Suhaib CT', designation: 'Al Jamia Dean'),
      ],
    );

    expect(find.text('Basheer Muhiyudheen'), findsOneWidget);
    expect(find.text('Prominent Islamic scholar'), findsOneWidget);
    expect(find.text('Suhaib CT'), findsOneWidget);
    expect(find.text('Al Jamia Dean'), findsOneWidget);
  });

  testWidgets('lists the episodes that belong to that faculty only', (
    tester,
  ) async {
    await pumpFaculties(
      tester,
      speakers: [
        faculty(id: 's1', name: 'Basheer Muhiyudheen'),
        faculty(id: 's2', name: 'Suhaib CT'),
      ],
      videos: [
        episode(id: 'v1', title: 'His episode', speakerId: 's1'),
        episode(id: 'v2', title: 'Someone else', speakerId: 's2'),
      ],
    );

    expect(find.text('His episode'), findsOneWidget);
    expect(find.text('Someone else'), findsOneWidget);
    expect(find.text('Watch All 1 Episode'), findsNWidgets(2));
  });

  testWidgets('says so when a faculty has no episodes yet', (tester) async {
    await pumpFaculties(
      tester,
      speakers: [faculty(id: 's1', name: 'New Faculty')],
    );

    expect(find.text('No episodes published yet.'), findsOneWidget);
  });

  testWidgets('search narrows the list', (tester) async {
    await pumpFaculties(
      tester,
      speakers: [
        faculty(id: 's1', name: 'Basheer Muhiyudheen'),
        faculty(id: 's2', name: 'Suhaib CT'),
      ],
    );

    await tester.tap(find.byIcon(LucideIcons.search));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'suhaib');
    await tester.pumpAndSettle();

    expect(find.text('Suhaib CT'), findsOneWidget);
    expect(find.text('Basheer Muhiyudheen'), findsNothing);
  });
}
