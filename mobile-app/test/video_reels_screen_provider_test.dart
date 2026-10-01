import 'package:flutter_test/flutter_test.dart';
import 'package:qspot/screens/video/provider/video_reels_screen_provider.dart';

void main() {
  const hide = VideoReelsScreenProvider.controlsHideDelay;

  test('started is tracked per reel and only notifies on a change', () {
    final reels = VideoReelsScreenProvider(initialIndex: 0);
    var notifications = 0;
    reels.addListener(() => notifications++);

    expect(reels.isStarted(0), isFalse);

    reels.setStarted(0, true);
    reels.setStarted(0, true);
    expect(reels.isStarted(0), isTrue);
    expect(reels.isStarted(1), isFalse);
    expect(notifications, 1);

    reels.setStarted(0, false);
    reels.setStarted(0, false);
    expect(reels.isStarted(0), isFalse);
    expect(notifications, 2);
  });

  group('controls', () {
    testWidgets('a tap shows them, the next tap hides them', (tester) async {
      final reels = VideoReelsScreenProvider(initialIndex: 0);
      addTearDown(reels.dispose);

      reels.toggleControls(0);
      expect(reels.areControlsShown(0), isTrue);
      expect(reels.areControlsShown(1), isFalse);

      reels.toggleControls(0);
      expect(reels.areControlsShown(0), isFalse);
    });

    testWidgets('they hide themselves after the delay', (tester) async {
      final reels = VideoReelsScreenProvider(initialIndex: 0);
      addTearDown(reels.dispose);
      var notifications = 0;
      reels.addListener(() => notifications++);

      reels.showControls(0);
      await tester.pump(hide - const Duration(milliseconds: 1));
      expect(reels.areControlsShown(0), isTrue);

      await tester.pump(const Duration(milliseconds: 1));
      expect(reels.areControlsShown(0), isFalse);
      expect(notifications, 2, reason: 'one to show, one to hide');
    });

    testWidgets('showing again restarts the countdown', (tester) async {
      final reels = VideoReelsScreenProvider(initialIndex: 0);
      addTearDown(reels.dispose);

      reels.showControls(0);
      await tester.pump(const Duration(seconds: 2));
      reels.showControls(0);
      await tester.pump(const Duration(seconds: 2));
      expect(reels.areControlsShown(0), isTrue);

      await tester.pump(const Duration(seconds: 1));
      expect(reels.areControlsShown(0), isFalse);
    });

    testWidgets('they stay while the seek bar is being dragged', (
      tester,
    ) async {
      final reels = VideoReelsScreenProvider(initialIndex: 0);
      addTearDown(reels.dispose);
      var dragging = true;

      reels.showControls(0, canHide: () => !dragging);
      await tester.pump(hide);
      expect(reels.areControlsShown(0), isTrue, reason: 'still dragging');

      dragging = false;
      await tester.pump(hide);
      expect(reels.areControlsShown(0), isFalse);
    });

    testWidgets('disposing cancels any countdown still running', (
      tester,
    ) async {
      final reels = VideoReelsScreenProvider(initialIndex: 0);
      reels.showControls(0);
      reels.dispose();

      // A leftover timer would fail the test here, or call a disposed
      // notifier when it fires.
      await tester.pump(hide * 2);
    });
  });
}
