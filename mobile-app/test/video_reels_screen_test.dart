import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qspot/screens/bookmark/provider/bookmark_provider.dart';
import 'package:qspot/screens/video/model/video_model.dart';
import 'package:qspot/screens/video/provider/video_provider.dart';
import 'package:qspot/screens/video/screens/video_reels_screen.dart';
import 'package:qspot/services/common/storage_service.dart';
import 'package:qspot/themes/app_colors.dart';

VideoModel video(String id, String title) => VideoModel(
  id: id,
  caption: title,
  title: title,
  // Not a YouTube URL, so the test never touches a platform video view.
  video: 'https://example.com/clip-$id',
);

Future<void> pumpFeed(
  WidgetTester tester,
  List<VideoModel> videos, {
  int initialIndex = 0,
  Size logicalSize = const Size(390, 844),
}) async {
  tester.view.physicalSize = logicalSize * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  // The test font renders every glyph one em wide, so rows that fit on a phone
  // still report overflow here. Layout itself is checked on the device build.
  final previousOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exception.toString().contains('A RenderFlex overflowed')) {
      return;
    }
    previousOnError?.call(details);
  };
  addTearDown(() => FlutterError.onError = previousOnError);

  SharedPreferences.setMockInitialValues({});
  await StorageService.init();

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VideoProvider()),
        ChangeNotifierProvider(create: (_) => BookmarkProvider()),
      ],
      child: MaterialApp(
        home: VideoReelsScreen(videos: videos, initialIndex: initialIndex),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('feed is a vertical pager showing one video at a time', (
    tester,
  ) async {
    await pumpFeed(tester, [video('1', 'First lesson'), video('2', 'Second')]);

    final pageView = tester.widget<PageView>(find.byType(PageView));
    expect(pageView.scrollDirection, Axis.vertical);
    expect(find.text('First lesson'), findsOneWidget);
    expect(find.text('Second'), findsNothing);
  });

  testWidgets('back button sits at the top of the screen', (tester) async {
    await pumpFeed(tester, [video('1', 'First lesson')]);

    // The screen is 844 logical px tall; the button must not drift to the
    // middle where the video is.
    final top = tester.getTopLeft(find.byIcon(LucideIcons.arrowLeft)).dy;
    expect(top, lessThan(120));
  });

  testWidgets('portrait: Save above Details in one column beside the title, '
      'no Full', (tester) async {
    await pumpFeed(tester, [video('1', 'First lesson')]);

    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Details'), findsOneWidget);
    expect(find.text('Full'), findsNothing);
    expect(find.byIcon(LucideIcons.maximize), findsNothing);

    final title = tester.getRect(find.text('First lesson'));
    final save = tester.getRect(find.byIcon(LucideIcons.bookmark));
    final details = tester.getRect(find.byIcon(LucideIcons.info));

    // One column: same horizontal centre, Save above Details.
    expect((save.center.dx - details.center.dx).abs(), lessThan(1));
    expect(details.top, greaterThan(save.bottom));
    // Beside the title, to its right, with the column's bottom level with it.
    expect(save.left, greaterThan(title.right));
    expect((details.center.dy - title.center.dy).abs(), lessThan(60));
    // Down in the title block, not floating up the screen where the old side
    // rail sat (its Save icon was around y=590).
    expect(save.top, greaterThan(680));
  });

  testWidgets('landscape moves Save and Details into the top bar', (
    tester,
  ) async {
    await pumpFeed(tester, [
      video('1', 'First lesson'),
    ], logicalSize: const Size(844, 390));

    // The labelled side rail is portrait-only.
    expect(find.text('Save'), findsNothing);
    expect(find.text('Details'), findsNothing);

    final title = tester.getTopLeft(find.text('First lesson'));
    for (final icon in [LucideIcons.bookmark, LucideIcons.info]) {
      expect(find.byIcon(icon), findsOneWidget);
      final position = tester.getTopLeft(find.byIcon(icon));
      expect(position.dy, lessThan(100));
      expect(position.dx, greaterThan(title.dx));
    }
  });

  testWidgets('portrait keeps the title at the bottom', (tester) async {
    await pumpFeed(tester, [video('1', 'First lesson')]);

    final title = tester.getTopLeft(find.text('First lesson')).dy;
    expect(title, greaterThan(844 / 2));
  });

  testWidgets('landscape moves the title to the top, beside the back button', (
    tester,
  ) async {
    await pumpFeed(tester, [
      video('1', 'First lesson'),
    ], logicalSize: const Size(844, 390));

    final title = tester.getTopLeft(find.text('First lesson'));
    final back = tester.getBottomRight(find.byIcon(LucideIcons.arrowLeft));
    expect(find.text('First lesson'), findsOneWidget);
    expect(title.dy, lessThan(100));
    expect(title.dx, greaterThan(back.dx));
  });

  testWidgets('chips show in portrait and are hidden in landscape', (
    tester,
  ) async {
    await pumpFeed(tester, [video('1', 'First lesson')]);
    for (final chip in ['Learn', 'Downloads', 'Practice']) {
      expect(find.text(chip), findsOneWidget);
    }

    await pumpFeed(tester, [
      video('1', 'First lesson'),
    ], logicalSize: const Size(844, 390));
    for (final chip in ['Learn', 'Downloads', 'Practice']) {
      expect(find.text(chip), findsNothing);
    }
  });

  testWidgets('bottom fade covers the video in portrait only', (tester) async {
    // The fade is drawn above the player, so in landscape it would dim the
    // player's own seek bar and buttons.
    final bottomFade = find.byWidgetPredicate((widget) {
      if (widget is! Container) return false;
      final decoration = widget.decoration;
      if (decoration is! BoxDecoration) return false;
      final gradient = decoration.gradient;
      return gradient is LinearGradient &&
          gradient.colors.last == AppColors.scrimStrong;
    });

    await pumpFeed(tester, [video('1', 'First lesson')]);
    expect(bottomFade, findsOneWidget);

    await pumpFeed(tester, [
      video('1', 'First lesson'),
    ], logicalSize: const Size(844, 390));
    expect(bottomFade, findsNothing);
  });

  testWidgets('swiping up advances to the next video', (tester) async {
    await pumpFeed(tester, [video('1', 'First lesson'), video('2', 'Second')]);

    await tester.drag(find.byType(PageView), const Offset(0, -700));
    // The loading spinner animates for as long as the (fake) video is loading,
    // so let the page swipe finish by time instead of pumpAndSettle.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Second'), findsOneWidget);
    expect(find.text('First lesson'), findsNothing);
  });

  testWidgets('opens at the tapped video, not the first one', (tester) async {
    await pumpFeed(tester, [
      video('1', 'First lesson'),
      video('2', 'Second'),
      video('3', 'Third'),
    ], initialIndex: 2);

    expect(find.text('Third'), findsOneWidget);
    expect(find.text('First lesson'), findsNothing);
  });
}
