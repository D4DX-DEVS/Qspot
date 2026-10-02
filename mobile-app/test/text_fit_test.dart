import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:qspot/screens/assignment/model/assignment_model.dart';
import 'package:qspot/screens/assignment/widgets/assignment_tile.dart';
import 'package:qspot/screens/bookmark/provider/bookmark_provider.dart';
import 'package:qspot/screens/progress/widgets/activity_tile.dart';
import 'package:qspot/screens/progress/widgets/mastery_progress_row.dart';
import 'package:qspot/screens/quiz/model/quiz_model.dart';
import 'package:qspot/screens/quiz/widgets/quiz_list_card.dart';
import 'package:qspot/screens/subject/model/subject_model.dart';
import 'package:qspot/screens/subject/widgets/subject_card.dart';
import 'package:qspot/screens/video/model/video_model.dart';
import 'package:qspot/screens/video/widgets/video_card.dart';
import 'package:qspot/screens/video/widgets/video_grid.dart';
import 'package:qspot/themes/home_palette.dart';
import 'package:qspot/widgets/common/app_bar_title.dart';
import 'package:qspot/widgets/common/app_drawer_header.dart';
import 'package:qspot/widgets/common/banner_headline.dart';
import 'package:qspot/widgets/common/common_app_bar.dart';
import 'package:qspot/widgets/common/fit_text.dart';
import 'package:qspot/widgets/common/floating_nav_bar.dart';
import 'package:qspot/widgets/common/floating_nav_bar_item.dart';
import 'package:qspot/widgets/common/gold_pill_button.dart';
import 'package:qspot/widgets/common/nav_list_card.dart';
import 'package:qspot/widgets/common/stat_tile.dart';

/// Long text must wrap or shrink, never be cut with "..." or overflow.
const _long =
    'A Remarkably Long Title About The Laws Of Motion, Gravitation And '
    'Everything Else In The Chapter That Keeps Going On And On';

/// A long but realistic subject name for a small poster-style tile.
const _subjectName = 'Environmental Science And Sustainability';

/// Smallest phone width, with the largest text size the app allows.
const _width = 320.0;
const _scale = 1.3;

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.light,
  PreferredSizeWidget? appBar,
}) async {
  tester.view.physicalSize = const Size(_width, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: brightness),
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(_scale)),
        child: app!,
      ),
      home: Scaffold(
        appBar: appBar,
        body: SingleChildScrollView(child: child),
      ),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
}

/// Nothing in the tree may use an ellipsis or a line cap to hide text.
void _expectNoTruncation(WidgetTester tester) {
  for (final text in tester.widgetList<Text>(find.byType(Text))) {
    expect(text.overflow, isNot(TextOverflow.ellipsis), reason: '${text.data}');
    expect(text.maxLines, isNull, reason: '${text.data}');
  }
}

void main() {
  for (final brightness in Brightness.values) {
    group('text fits ($brightness)', () {
      testWidgets('stat tiles with wrapping labels share one height', (
        tester,
      ) async {
        await _pump(
          tester,
          brightness: brightness,
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                Expanded(
                  child: StatTile(
                    icon: LucideIcons.flame,
                    color: Colors.orange,
                    value: '12/40',
                    label: 'Lessons Completed So Far',
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: StatTile(
                    icon: LucideIcons.zap,
                    color: Colors.amber,
                    value: '5',
                    label: 'XP',
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: StatTile(
                    icon: LucideIcons.medal,
                    color: Colors.pink,
                    value: '3',
                    label: 'Level',
                  ),
                ),
              ],
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Lessons Completed So Far'), findsOneWidget);
        _expectNoTruncation(tester);
        final heights = tester
            .widgetList(find.byType(StatTile))
            .map((w) => tester.getSize(find.byWidget(w)).height)
            .toSet();
        expect(heights.length, 1);
      });

      testWidgets('nav list card wraps title and subtitle', (tester) async {
        await _pump(
          tester,
          brightness: brightness,
          NavListCard(
            icon: LucideIcons.bookOpen,
            tone: HomePalette.light.teal,
            title: _long,
            subtitle: _long,
            onTap: () {},
          ),
        );
        expect(tester.takeException(), isNull);
        _expectNoTruncation(tester);
      });

      testWidgets('floating nav bar shrinks labels instead of overflowing', (
        tester,
      ) async {
        await _pump(
          tester,
          brightness: brightness,
          FloatingNavBar(
            currentIndex: 2,
            onTap: (_) {},
            items: const [
              FloatingNavBarItem(
                icon: LucideIcons.house,
                activeIcon: LucideIcons.house,
                label: 'Today',
              ),
              FloatingNavBarItem(
                icon: LucideIcons.bookOpen,
                activeIcon: LucideIcons.bookOpen,
                label: 'Learn',
              ),
              FloatingNavBarItem(
                icon: LucideIcons.pencil,
                activeIcon: LucideIcons.pencil,
                label: 'Practice',
              ),
              FloatingNavBarItem(
                icon: LucideIcons.chartNoAxesColumn,
                activeIcon: LucideIcons.chartNoAxesColumn,
                label: 'Progress',
              ),
              FloatingNavBarItem(
                icon: LucideIcons.user,
                activeIcon: LucideIcons.user,
                label: 'Me',
              ),
            ],
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Progress'), findsOneWidget);
      });

      testWidgets('app bar shows a very long title in full', (tester) async {
        await _pump(
          tester,
          brightness: brightness,
          const SizedBox.shrink(),
          appBar: const CommonAppBar(title: _long),
        );
        expect(tester.takeException(), isNull);
        expect(find.text(_long), findsOneWidget);
        // It is laid out inside the bar and never taller than it.
        expect(
          tester.getSize(find.byType(AppBarTitle)).height,
          lessThanOrEqualTo(kToolbarHeight),
        );
        final title = tester.getRect(find.text(_long));
        expect(title.left, greaterThanOrEqualTo(0));
        expect(title.right, lessThanOrEqualTo(_width));
      });

      testWidgets('app bar keeps a short title at full size', (tester) async {
        await _pump(
          tester,
          brightness: brightness,
          const SizedBox.shrink(),
          appBar: const CommonAppBar(title: 'Quiz'),
        );
        expect(tester.takeException(), isNull);
        final style = tester.widget<Text>(find.text('Quiz')).style;
        // Material 3's default bar title size; not shrunk.
        expect(style?.fontSize, greaterThanOrEqualTo(20));
      });

      testWidgets('fit text shrinks until a long word is not split', (
        tester,
      ) async {
        await _pump(
          tester,
          brightness: brightness,
          const SizedBox(
            width: 200,
            child: FitText(
              'Environmental',
              maxHeight: 60,
              style: TextStyle(fontSize: 20),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        final size = tester.getSize(find.text('Environmental'));
        // One line only: the word was not broken across lines.
        expect(size.height, lessThan(30));
        expect(size.width, lessThanOrEqualTo(200));
      });

      testWidgets('fit text keeps its size when there is room', (tester) async {
        await _pump(
          tester,
          brightness: brightness,
          const SizedBox(
            width: 200,
            child: FitText(
              'Short',
              maxHeight: 60,
              style: TextStyle(fontSize: 20),
            ),
          ),
        );
        final style = tester.widget<Text>(find.text('Short')).style;
        expect(style?.fontSize, 20);
      });

      testWidgets('banner and gold button wrap long text', (tester) async {
        await _pump(
          tester,
          brightness: brightness,
          Column(
            children: [
              const BannerHeadline(title: _long, subtitle: _long),
              GoldPillButton(label: _long, onPressed: () {}),
            ],
          ),
        );
        expect(tester.takeException(), isNull);
        _expectNoTruncation(tester);
      });

      testWidgets('drawer header wraps a long name and subtitle', (
        tester,
      ) async {
        await _pump(
          tester,
          brightness: brightness,
          AppDrawerHeader(name: _long, subtitle: _long, onClose: () {}),
        );
        expect(tester.takeException(), isNull);
        _expectNoTruncation(tester);
      });

      testWidgets('progress, assignment and quiz rows wrap long text', (
        tester,
      ) async {
        await _pump(
          tester,
          brightness: brightness,
          Column(
            children: [
              ActivityTile(
                icon: LucideIcons.play,
                tone: HomePalette.light.teal,
                kind: 'Video',
                title: _long,
                detail: _long,
                dateLabel: '2 Oct',
              ),
              const MasteryProgressRow(
                title: _long,
                completed: 3,
                total: 9,
                percent: 0.33,
              ),
              AssignmentTile(
                assignment: AssignmentModel(
                  id: 'a',
                  title: _long,
                  subject: _long,
                ),
                onTap: () {},
              ),
              QuizListCard(
                quiz: QuizListItem(
                  id: 'q',
                  title: _long,
                  assessmentType: 'knowledge',
                  startDate: null,
                  endDate: null,
                  numberOfQuestions: 5,
                  questionsRandomization: false,
                  overallTimeLimit: null,
                  perQuestionTimeLimit: null,
                  timerMode: 'none',
                  optionsCount: 4,
                  status: 'live',
                  questionCount: 5,
                  myAttempt: null,
                ),
                onTap: () {},
              ),
            ],
          ),
        );
        expect(tester.takeException(), isNull);
        _expectNoTruncation(tester);
      });

      testWidgets('subject card shows a long name over its picture', (
        tester,
      ) async {
        await _pump(
          tester,
          brightness: brightness,
          SizedBox(
            width: 148,
            height: 197,
            child: SubjectCard(
              subject: SubjectModel(id: 's', subject: _subjectName),
              onTap: () {},
              width: null,
              height: null,
              completedLessons: 2,
              totalLessons: 8,
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        _expectNoTruncation(tester);
        // The whole name sits inside the card.
        final card = tester.getRect(find.byType(SubjectCard));
        final name = tester.getRect(find.text(_subjectName));
        expect(name.top, greaterThanOrEqualTo(card.top));
        expect(name.bottom, lessThanOrEqualTo(card.bottom));
      });

      testWidgets('video grid rows grow to fit long titles', (tester) async {
        VideoModel video(String id, String title) =>
            VideoModel(id: id, caption: 'c', video: 'x', title: title);
        final videos = [
          video('1', 'Short'),
          video('2', _long),
          video('3', _long),
        ];
        tester.view.physicalSize = const Size(_width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          ChangeNotifierProvider(
            create: (_) => BookmarkProvider(fetchAll: () async => []),
            child: MaterialApp(
              theme: ThemeData(brightness: brightness),
              builder: (context, app) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(_scale)),
                child: app!,
              ),
              home: Scaffold(
                body: VideoGrid(
                  padding: const EdgeInsets.all(16),
                  itemCount: videos.length,
                  itemBuilder: (_, i) =>
                      VideoCard(video: videos[i], onTap: () {}),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull);
        _expectNoTruncation(tester);
        expect(find.text(_long), findsNWidgets(2));
        // Short card sits beside a tall one: both cards in a row match.
        final first = tester.getSize(find.byType(VideoCard).at(0)).height;
        final second = tester.getSize(find.byType(VideoCard).at(1)).height;
        expect(first, second);
      });
    });
  }
}
