import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qspot/screens/home/model/continue_lesson_info.dart';
import 'package:qspot/screens/home/widgets/continue_lesson_card.dart';
import 'package:qspot/screens/video/model/video_model.dart';
import 'package:qspot/services/video_progress_service.dart';
import 'package:qspot/themes/home_palette.dart';

VideoModel _video({int durationSeconds = 600}) => VideoModel(
  id: 'v1',
  caption: 'Lesson',
  video: 'x',
  durationSeconds: durationSeconds,
);

VideoProgressStatus _status({
  int position = 0,
  int duration = 600,
  bool completed = false,
}) => VideoProgressStatus(
  videoId: 'v1',
  positionSeconds: position,
  durationSeconds: duration,
  completed: completed,
  status: completed ? 'completed' : 'in-progress',
);

void main() {
  group('ContinueLessonInfo', () {
    test('just started below 25%', () {
      final info = ContinueLessonInfo.from(_video(), _status(position: 60));
      expect(info.label, 'Just Started');
      expect(info.timeLeft, '9 Min Left');
      expect(info.completed, isFalse);
    });

    test('keep going from 25% up to 75%', () {
      final info = ContinueLessonInfo.from(_video(), _status(position: 300));
      expect(info.label, 'Keep Going');
      expect(info.progress, 0.5);
      expect(info.timeLeft, '5 Min Left');
    });

    test('almost there from 75%, rounding the time left up', () {
      final info = ContinueLessonInfo.from(_video(), _status(position: 570));
      expect(info.label, 'Almost There');
      expect(info.timeLeft, '1 Min Left');
    });

    test('completed shows no time left and a full bar', () {
      final info = ContinueLessonInfo.from(
        _video(),
        _status(position: 100, completed: true),
      );
      expect(info.label, 'Nailed It');
      expect(info.completed, isTrue);
      expect(info.progress, 1);
      expect(info.timeLeft, isNull);
    });

    test('unknown length shows no time left', () {
      final info = ContinueLessonInfo.from(
        _video(durationSeconds: 0),
        _status(position: 30, duration: 0),
      );
      expect(info.timeLeft, isNull);
      expect(info.progress, 0);
    });

    test('falls back to the video length when progress has none', () {
      final info = ContinueLessonInfo.from(
        _video(durationSeconds: 300),
        _status(position: 0, duration: 0),
      );
      expect(info.timeLeft, '5 Min Left');
    });

    test('missing progress is treated as just started', () {
      final info = ContinueLessonInfo.from(_video(), null);
      expect(info.label, 'Just Started');
      expect(info.progress, 0);
    });
  });

  group('ContinueLessonCard', () {
    Future<void> pumpCard(
      WidgetTester tester, {
      required Brightness brightness,
      required double width,
      double textScale = 1,
      String title = 'A Very Long Lesson Title That Must Wrap To Two Lines',
      String subject = 'Environmental Science And Sustainability',
      VoidCallback? onTap,
    }) async {
      final palette = brightness == Brightness.dark
          ? HomePalette.dark
          : HomePalette.light;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: Scaffold(
              // Home scrolls vertically, so a card may grow as tall as its
              // full title needs.
              body: Center(
                child: SingleChildScrollView(
                  child: ContinueLessonCard(
                    title: title,
                    subject: subject,
                    thumbnailUrl: '',
                    info: ContinueLessonInfo.from(
                      _video(),
                      _status(position: 300),
                    ),
                    tone: palette.coral,
                    width: width,
                    onTap: onTap ?? () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    for (final brightness in Brightness.values) {
      for (final (width, scale) in [(230.0, 1.0), (280.0, 1.0), (230.0, 2.0)]) {
        testWidgets('lays out at $width wide, ${scale}x text, $brightness', (
          tester,
        ) async {
          await pumpCard(
            tester,
            brightness: brightness,
            width: width,
            textScale: scale,
          );
          expect(tester.takeException(), isNull);
          expect(find.text('⚡ Keep Going'), findsOneWidget);
          expect(find.text('5 Min Left'), findsOneWidget);
        });
      }
    }

    testWidgets('tap fires onTap', (tester) async {
      var taps = 0;
      await pumpCard(
        tester,
        brightness: Brightness.light,
        width: 260,
        title: 'Short',
        subject: 'Maths',
        onTap: () => taps++,
      );
      await tester.tap(find.byType(ContinueLessonCard));
      expect(taps, 1);
    });

    testWidgets('scrolling row (as on Home) gives every card one height', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final titles = [
        'Short',
        'A Very Long Lesson Title That Wraps',
        'Mid One',
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 700),
              textScaler: TextScaler.linear(1.5),
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final title in titles) ...[
                        ContinueLessonCard(
                          title: title,
                          subject: 'Maths',
                          thumbnailUrl: '',
                          info: ContinueLessonInfo.from(
                            _video(),
                            _status(position: 100),
                          ),
                          tone: HomePalette.light.teal,
                          width: 230,
                          onTap: () {},
                        ),
                        const SizedBox(width: 12),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final cards = find.byType(ContinueLessonCard);
      final first = tester.getSize(cards.first).height;
      for (var i = 1; i < titles.length; i++) {
        expect(tester.getSize(cards.at(i)).height, first);
      }
    });

    for (final scale in [1.0, 1.2, 1.3, 1.5, 2.0]) {
      testWidgets(
        'a long title grows the card instead of being cut at ${scale}x',
        (tester) async {
          const longTitle =
              'A Very Long Lesson Title That Must Wrap To Two Lines Or More';
          await pumpCard(
            tester,
            brightness: Brightness.light,
            width: 260,
            textScale: scale,
            title: 'Short',
          );
          final short = tester.getSize(find.byType(ContinueLessonCard)).height;
          await pumpCard(
            tester,
            brightness: Brightness.light,
            width: 260,
            textScale: scale,
            title: longTitle,
          );
          final long = tester.getSize(find.byType(ContinueLessonCard)).height;
          expect(long, greaterThan(short));
          final title = tester.widget<Text>(find.text(longTitle));
          expect(title.maxLines, isNull);
          expect(title.overflow, isNot(TextOverflow.ellipsis));
        },
      );
    }
  });
}
