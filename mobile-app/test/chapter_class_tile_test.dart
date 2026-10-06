import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qspot/screens/subject/model/chapter_progress.dart';
import 'package:qspot/screens/subject/widgets/chapter_class_tile.dart';
import 'package:qspot/screens/subject/widgets/chapter_thumbnail.dart';
import 'package:qspot/screens/video/model/video_model.dart';
import 'package:qspot/screens/video/provider/video_provider.dart';
import 'package:qspot/services/video_progress_service.dart';
import 'package:qspot/themes/home_theme.dart';
import 'package:qspot/widgets/common/adaptive_card_columns.dart';

const _longTitle = 'Environmental Science And Sustainability For Tomorrow';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.light,
  double width = 360,
  double scale = 1,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: HomeTheme.of(brightness),
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: app!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
}

ChapterClassTile _tile({
  String title = 'Stories',
  ChapterProgress progress = const ChapterProgress(total: 4, completed: 1),
  VoidCallback? onTap,
  String? imageUrl,
  int number = 2,
}) => ChapterClassTile(
  number: number,
  title: title,
  imageUrl: imageUrl,
  progress: progress,
  onTap: onTap ?? () {},
);

VideoModel _video(String id, String subject, {bool upcoming = false}) =>
    VideoModel(
      id: id,
      caption: 'c',
      video: 'x',
      subjectId: subject,
      isUpcoming: upcoming,
    );

void main() {
  group('ChapterProgress', () {
    test('no lessons is empty, with nothing to fill', () {
      expect(ChapterProgress.none.status, ChapterStatus.empty);
      expect(ChapterProgress.none.fraction, 0);
    });

    test('nothing watched yet is not started', () {
      const progress = ChapterProgress(total: 4);
      expect(progress.status, ChapterStatus.notStarted);
    });

    test('a finished or a half-watched lesson makes it in progress', () {
      expect(
        const ChapterProgress(total: 4, completed: 1).status,
        ChapterStatus.inProgress,
      );
      expect(
        const ChapterProgress(total: 4, started: 1).status,
        ChapterStatus.inProgress,
      );
    });

    test(
      'every lesson finished is completed, and fraction stays within 0-1',
      () {
        const progress = ChapterProgress(total: 4, completed: 4);
        expect(progress.status, ChapterStatus.completed);
        expect(progress.fraction, 1);
        expect(const ChapterProgress(total: 2, completed: 5).fraction, 1);
        expect(const ChapterProgress(total: 4, completed: 1).fraction, 0.25);
      },
    );
  });

  group('VideoProvider.chapterProgressFor', () {
    test('counts only that subject, and skips upcoming episodes', () {
      final provider = VideoProvider()
        ..seedVideos([
          _video('a', 's1'),
          _video('b', 's1'),
          _video('c', 's1'),
          _video('d', 's1', upcoming: true),
          _video('e', 's2'),
        ])
        ..applyProgress(
          const VideoProgressStatus(
            videoId: 'a',
            completed: true,
            positionSeconds: 90,
          ),
        )
        ..applyProgress(
          const VideoProgressStatus(videoId: 'b', positionSeconds: 30),
        )
        ..applyProgress(
          const VideoProgressStatus(videoId: 'e', completed: true),
        );

      final progress = provider.chapterProgressFor('s1');
      expect(progress.total, 3);
      expect(progress.completed, 1);
      expect(progress.started, 1);
      expect(progress.status, ChapterStatus.inProgress);
    });

    test('a subject with no videos is empty', () {
      expect(
        VideoProvider().chapterProgressFor('none').status,
        ChapterStatus.empty,
      );
    });

    test('a lesson opened at zero seconds is not counted as started', () {
      final provider = VideoProvider()
        ..seedVideos([_video('a', 's1')])
        ..applyProgress(const VideoProgressStatus(videoId: 'a'));
      expect(
        provider.chapterProgressFor('s1').status,
        ChapterStatus.notStarted,
      );
    });
  });

  for (final brightness in Brightness.values) {
    group('ChapterClassTile ($brightness)', () {
      testWidgets('shows the chapter number, name, progress and status', (
        tester,
      ) async {
        await _pump(tester, brightness: brightness, _tile());
        expect(find.text('Chapter 2'), findsOneWidget);
        expect(find.text('Stories'), findsOneWidget);
        expect(find.text('1/4 Lessons'), findsOneWidget);
        expect(find.text('Continue'), findsOneWidget);
      });

      testWidgets('the status pill follows the progress', (tester) async {
        Future<void> expectChip(ChapterProgress progress, String? label) async {
          await _pump(
            tester,
            brightness: brightness,
            _tile(progress: progress),
          );
          for (final other in ['Start', 'Continue', 'Done']) {
            expect(
              find.text(other),
              other == label ? findsOneWidget : findsNothing,
              reason: '$progress -> $label',
            );
          }
        }

        await expectChip(const ChapterProgress(total: 3), 'Start');
        await expectChip(
          const ChapterProgress(total: 3, completed: 1),
          'Continue',
        );
        await expectChip(const ChapterProgress(total: 3, completed: 3), 'Done');
        await expectChip(ChapterProgress.none, null);
      });

      testWidgets('a chapter with no lessons says so instead of a bar', (
        tester,
      ) async {
        await _pump(
          tester,
          brightness: brightness,
          _tile(progress: ChapterProgress.none),
        );
        expect(find.text('No Lessons Yet'), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsNothing);
      });

      testWidgets('tapping the tile opens the chapter', (tester) async {
        var taps = 0;
        await _pump(tester, brightness: brightness, _tile(onTap: () => taps++));
        await tester.tap(find.byType(ChapterClassTile));
        expect(taps, 1);
      });

      testWidgets('chapter artwork keeps its full source width', (
        tester,
      ) async {
        await _pump(
          tester,
          brightness: brightness,
          width: 400,
          _tile(imageUrl: 'https://example.invalid/quran-recitation.png'),
        );

        final thumbnail = find.descendant(
          of: find.byType(ChapterThumbnail),
          matching: find.byType(AspectRatio),
        );
        expect(tester.getSize(thumbnail), const Size(96, 60));
      });

      testWidgets('a long name on a small phone with big text is shown whole', (
        tester,
      ) async {
        await _pump(
          tester,
          brightness: brightness,
          width: 320,
          scale: 1.3,
          _tile(
            title: _longTitle,
            imageUrl: 'https://example.invalid/art.png',
            progress: const ChapterProgress(total: 12, completed: 5),
          ),
        );
        expect(tester.takeException(), isNull);
        for (final text in tester.widgetList<Text>(find.byType(Text))) {
          expect(text.overflow, isNot(TextOverflow.ellipsis));
          expect(text.maxLines, isNull);
        }
        final tile = tester.getRect(find.byType(ChapterClassTile));
        final title = tester.getRect(find.text(_longTitle));
        expect(title.left, greaterThanOrEqualTo(tile.left));
        expect(title.right, lessThanOrEqualTo(tile.right));
        expect(title.bottom, lessThanOrEqualTo(tile.bottom));
      });
    });
  }

  group('AdaptiveCardColumns', () {
    Widget cards() => AdaptiveCardColumns(
      children: [
        for (var i = 0; i < 3; i++)
          _tile(title: i == 0 ? _longTitle : 'Short $i', number: i + 1),
      ],
    );

    testWidgets('stacks the cards in one column on a phone', (tester) async {
      await _pump(tester, width: 360, cards());
      final first = tester.getRect(find.byType(ChapterClassTile).at(0));
      final second = tester.getRect(find.byType(ChapterClassTile).at(1));
      expect(second.left, first.left);
      expect(second.top, greaterThan(first.bottom));
    });

    testWidgets('fills two columns on a tablet, a row sharing one height', (
      tester,
    ) async {
      await _pump(tester, width: 800, cards());
      final first = tester.getRect(find.byType(ChapterClassTile).at(0));
      final second = tester.getRect(find.byType(ChapterClassTile).at(1));
      final third = tester.getRect(find.byType(ChapterClassTile).at(2));
      expect(second.top, first.top);
      expect(second.left, greaterThan(first.right));
      expect(second.height, first.height);
      expect(third.top, greaterThan(first.bottom));
      expect(third.left, first.left);
    });

    testWidgets('a single card keeps the full width on a tablet', (
      tester,
    ) async {
      await _pump(tester, width: 800, AdaptiveCardColumns(children: [_tile()]));
      final card = tester.getRect(find.byType(ChapterClassTile));
      expect(card.width, 800 - 32);
    });

    testWidgets('no cards draws nothing and does not throw', (tester) async {
      await _pump(tester, const AdaptiveCardColumns(children: []));
      expect(tester.takeException(), isNull);
    });
  });
}
