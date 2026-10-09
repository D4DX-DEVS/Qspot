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

  test('back target is Today, or the first tab when Today is missing', () {
    final provider = MainNavigationProvider(
      tabCount: 3,
      initialIndex: 2,
      tabKeys: const ['learn', 'today', 'me'],
    );
    expect(provider.homeIndex, 1);
    expect(provider.isOnHome, isFalse);

    provider.goHome();
    expect(provider.currentIndex, 1);
    expect(provider.isOnHome, isTrue);

    provider.setTabConfiguration(tabCount: 2, tabKeys: const ['learn', 'me']);
    provider.setIndex(1);
    expect(provider.homeIndex, 0);
    provider.goHome();
    expect(provider.currentIndex, 0);
  });
}
