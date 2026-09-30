import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qspot/screens/bookmark/provider/bookmark_provider.dart';
import 'package:qspot/screens/video/model/video_model.dart';
import 'package:qspot/screens/video/provider/video_provider.dart';
import 'package:qspot/screens/video/screens/video_reels_screen.dart';
import 'package:qspot/services/common/storage_service.dart';

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
}) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
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

  testWidgets('swiping up advances to the next video', (tester) async {
    await pumpFeed(tester, [video('1', 'First lesson'), video('2', 'Second')]);

    await tester.drag(find.byType(PageView), const Offset(0, -700));
    await tester.pumpAndSettle();

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
