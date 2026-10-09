import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qspot/screens/video/widgets/video_poster.dart';

Widget host(Widget child) =>
    MaterialApp(home: SizedBox(width: 300, height: 400, child: child));

void main() {
  testWidgets('without a thumbnail it is plain black and has no spinner', (
    tester,
  ) async {
    await tester.pumpWidget(host(const VideoPoster(thumbnailUrl: '')));

    final box = tester.widget<ColoredBox>(find.byType(ColoredBox).last);
    expect(box.color, Colors.black);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('hidden poster fades out and lets touches through', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      host(
        Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(onTap: () => taps++),
            const VideoPoster(thumbnailUrl: '', visible: false),
          ],
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
      0,
    );
    await tester.tapAt(const Offset(150, 200));
    expect(taps, 1);
  });

  testWidgets('visible poster blocks touches to the player underneath', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      host(
        Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(onTap: () => taps++),
            const VideoPoster(thumbnailUrl: ''),
          ],
        ),
      ),
    );

    await tester.tapAt(const Offset(150, 200));
    expect(taps, 0);
  });
}
