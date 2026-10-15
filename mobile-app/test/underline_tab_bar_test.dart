import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qspot/widgets/common/underline_tab_bar.dart';

enum _Tab { one, two, three }

Future<void> _pump(
  WidgetTester tester, {
  required _Tab selected,
  required ValueChanged<_Tab> onSelected,
  bool Function(_Tab)? isLocked,
  double width = 360,
}) async {
  tester.view.physicalSize = Size(width, 600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: UnderlineTabBar<_Tab>(
          options: _Tab.values,
          selected: selected,
          onSelected: onSelected,
          labelFor: (tab) => 'Tab ${tab.name}',
          isLocked: isLocked,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows every tab and reports the one tapped', (tester) async {
    _Tab? tapped;
    await _pump(tester, selected: _Tab.one, onSelected: (tab) => tapped = tab);

    for (final name in ['Tab one', 'Tab two', 'Tab three']) {
      expect(find.text(name), findsOneWidget);
    }

    await tester.tap(find.text('Tab two'));

    expect(tapped, _Tab.two);
  });

  testWidgets('tells screen readers which tab is chosen', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, selected: _Tab.two, onSelected: (_) {});

    expect(
      tester.getSemantics(find.bySemanticsLabel('Tab two')),
      matchesSemantics(
        label: 'Tab two',
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('a locked tab shows a lock and is announced as locked', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(
      tester,
      selected: _Tab.one,
      onSelected: (_) {},
      isLocked: (tab) => tab == _Tab.three,
    );

    expect(find.byIcon(LucideIcons.lock), findsOneWidget);
    expect(find.bySemanticsLabel('Tab three, locked'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('a locked tab can still be tapped, so it can say why', (
    tester,
  ) async {
    _Tab? tapped;
    await _pump(
      tester,
      selected: _Tab.one,
      onSelected: (tab) => tapped = tab,
      isLocked: (tab) => tab == _Tab.three,
    );

    await tester.tap(find.text('Tab three'));

    expect(tapped, _Tab.three);
  });

  testWidgets('tabs that do not fit scroll sideways without overflow', (
    tester,
  ) async {
    await _pump(tester, selected: _Tab.one, onSelected: (_) {}, width: 120);

    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Tab three'));
    await tester.pump();
    expect(find.text('Tab three'), findsOneWidget);
  });

  testWidgets('the line under the tabs runs the full width, even when the '
      'tabs are narrower', (tester) async {
    await _pump(tester, selected: _Tab.one, onSelected: (_) {}, width: 800);

    final line = tester.getRect(find.byType(Divider));
    final tabs = tester.getRect(find.text('Tab three'));

    expect(tabs.right, lessThan(800));
    expect(line.width, 800);
  });
}
