import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qspot/screens/banner/model/banner_model.dart';
import 'package:qspot/screens/banner/widgets/banner_carousel.dart';

Future<void> _pump(
  WidgetTester tester,
  List<BannerModel> banners,
  Brightness brightness,
) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: brightness),
      home: Scaffold(body: BannerCarousel(banners: banners)),
    ),
  );
}

void main() {
  final banner = BannerModel(id: '1', image: 'https://example.invalid/a.png');

  testWidgets('no banners takes no room', (tester) async {
    await _pump(tester, const [], Brightness.light);
    expect(find.byType(CarouselSlider), findsNothing);
  });

  for (final brightness in Brightness.values) {
    testWidgets('a banner shows without errors in $brightness', (tester) async {
      await _pump(tester, [banner], brightness);
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      expect(find.byType(CarouselSlider), findsOneWidget);
    });
  }
}
