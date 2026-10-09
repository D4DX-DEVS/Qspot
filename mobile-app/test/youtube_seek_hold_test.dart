import 'package:flutter_test/flutter_test.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

void main() {
  late YoutubePlayerController controller;

  setUp(() {
    controller = YoutubePlayerController(initialVideoId: 'abcdefghijk');
    controller.updateValue(controller.value.copyWith(isReady: true));
  });

  tearDown(() => controller.dispose());

  test('accepts every reported time when nothing was seeked', () {
    expect(
      controller.acceptsReportedPosition(const Duration(seconds: 10)),
      isTrue,
    );
  });

  test('ignores the old spot after a seek until the new one is reported', () {
    controller.seekTo(const Duration(seconds: 60));

    expect(
      controller.acceptsReportedPosition(const Duration(seconds: 10)),
      isFalse,
    );
    expect(controller.value.position, const Duration(seconds: 60));
    expect(
      controller.acceptsReportedPosition(
        const Duration(seconds: 60, milliseconds: 200),
      ),
      isTrue,
    );
    // Landed: later reports are trusted again, wherever they are.
    expect(
      controller.acceptsReportedPosition(const Duration(seconds: 10)),
      isTrue,
    );
  });

  test('does not hold a seek made before the player was ready', () {
    controller.updateValue(controller.value.copyWith(isReady: false));
    controller.seekTo(const Duration(seconds: 60));

    expect(
      controller.acceptsReportedPosition(const Duration(seconds: 10)),
      isTrue,
    );
  });
}
