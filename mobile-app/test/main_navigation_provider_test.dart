import 'package:flutter_test/flutter_test.dart';
import 'package:qspot/screens/common/provider/main_navigation_provider.dart';

void main() {
  test('clamps negative and out-of-range navigation indexes', () {
    final provider = MainNavigationProvider(tabCount: 5, initialIndex: -1);
    expect(provider.currentIndex, 0);

    provider.setIndex(-4);
    expect(provider.currentIndex, 0);

    provider.setIndex(99);
    expect(provider.currentIndex, 0);

    provider.setIndex(3);
    expect(provider.currentIndex, 3);
  });
}
