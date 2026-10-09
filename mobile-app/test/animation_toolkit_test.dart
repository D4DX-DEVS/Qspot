import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qspot/widgets/animation/animated_progress_bar.dart';
import 'package:qspot/widgets/animation/count_up_text.dart';
import 'package:qspot/widgets/animation/idle_attention.dart';
import 'package:qspot/widgets/animation/pop_on_change.dart';
import 'package:qspot/widgets/animation/pressable_scale.dart';
import 'package:qspot/widgets/animation/shake_on_change.dart';
import 'package:qspot/widgets/animation/staggered_entrance.dart';

Widget _host(Widget child, {bool disableAnimations = false}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Scaffold(body: Center(child: child)),
    ),
  );
}

const _target = Key('target');

double _scaleOf(WidgetTester tester) =>
    tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;

void main() {
  group('PressableScale', () {
    testWidgets('shrinks while pressed, restores on release, tap still fires', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          PressableScale(
            child: ElevatedButton(
              onPressed: () => taps++,
              child: const Text('go'),
            ),
          ),
        ),
      );
      expect(_scaleOf(tester), 1);

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('go')),
      );
      await tester.pump();
      expect(_scaleOf(tester), lessThan(1));

      await gesture.up();
      await tester.pumpAndSettle();
      expect(_scaleOf(tester), 1);
      expect(taps, 1);
    });

    testWidgets('dragging far away counts as scrolling and restores', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const PressableScale(
            child: ColoredBox(
              key: _target,
              color: Colors.red,
              child: SizedBox(width: 80, height: 80),
            ),
          ),
        ),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(_target)),
      );
      await tester.pump();
      expect(_scaleOf(tester), lessThan(1));

      await gesture.moveBy(const Offset(0, 60));
      await tester.pump();
      expect(_scaleOf(tester), 1);
      await gesture.up();
    });

    testWidgets('stays still when animations are turned off', (tester) async {
      await tester.pumpWidget(
        _host(
          const PressableScale(
            child: ColoredBox(
              key: _target,
              color: Colors.red,
              child: SizedBox(width: 80, height: 80),
            ),
          ),
          disableAnimations: true,
        ),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(_target)),
      );
      await tester.pump();
      expect(_scaleOf(tester), 1);
      await gesture.up();
    });

    testWidgets('disabled ignores presses', (tester) async {
      await tester.pumpWidget(
        _host(
          const PressableScale(
            enabled: false,
            child: ColoredBox(
              key: _target,
              color: Colors.red,
              child: SizedBox(width: 80, height: 80),
            ),
          ),
        ),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(_target)),
      );
      await tester.pump();
      expect(_scaleOf(tester), 1);
      await gesture.up();
    });
  });

  group('IdleAttention', () {
    testWidgets('adds a quiet pulse when motion is available', (tester) async {
      await tester.pumpWidget(
        _host(const IdleAttention(child: SizedBox(key: _target))),
      );
      await tester.pump(const Duration(milliseconds: 700));
      final scale = tester
          .widget<Transform>(
            find.ancestor(
              of: find.byKey(_target),
              matching: find.byType(Transform),
            ),
          )
          .transform
          .getMaxScaleOnAxis();
      expect(scale, greaterThan(1));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('stays still when animations are turned off', (tester) async {
      await tester.pumpWidget(
        _host(
          const IdleAttention(child: SizedBox(key: _target)),
          disableAnimations: true,
        ),
      );
      await tester.pump(const Duration(milliseconds: 700));
      expect(
        find.ancestor(
          of: find.byKey(_target),
          matching: find.byType(Transform),
        ),
        findsNothing,
      );
    });
  });

  group('StaggeredEntrance', () {
    testWidgets('starts hidden, ends fully visible', (tester) async {
      await tester.pumpWidget(
        _host(const StaggeredEntrance(index: 2, child: Text('hi'))),
      );
      double opacity() => tester
          .widget<Opacity>(
            find.ancestor(of: find.text('hi'), matching: find.byType(Opacity)),
          )
          .opacity;
      expect(opacity(), 0);

      await tester.pumpAndSettle();
      expect(opacity(), 1);
    });

    testWidgets('later items wait longer than earlier ones', (tester) async {
      await tester.pumpWidget(
        _host(
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StaggeredEntrance(index: 0, child: Text('first')),
              StaggeredEntrance(index: 5, child: Text('sixth')),
            ],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      double opacityOf(String label) => tester
          .widget<Opacity>(
            find.ancestor(of: find.text(label), matching: find.byType(Opacity)),
          )
          .opacity;
      expect(opacityOf('first'), greaterThan(opacityOf('sixth')));
      await tester.pumpAndSettle();
    });

    testWidgets('is instantly visible when animations are turned off', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const StaggeredEntrance(index: 3, child: Text('hi')),
          disableAnimations: true,
        ),
      );
      await tester.pump();
      final opacity = tester
          .widget<Opacity>(
            find.ancestor(of: find.text('hi'), matching: find.byType(Opacity)),
          )
          .opacity;
      expect(opacity, 1);
    });
  });

  group('CountUpText', () {
    testWidgets('counts up to the number and keeps prefix and suffix', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const CountUpText('~12 days')));
      expect(find.text('~0 days'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('~12 days'), findsOneWidget);
    });

    testWidgets('shows plain text when there is no whole number', (
      tester,
    ) async {
      for (final text in ['Done', '4.5', '1,200', '10:30']) {
        await tester.pumpWidget(_host(CountUpText(text)));
        expect(find.text(text), findsOneWidget, reason: text);
      }
    });

    testWidgets('shows the final value straight away when animations are off', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const CountUpText('85%'), disableAnimations: true),
      );
      expect(find.text('85%'), findsOneWidget);
    });
  });

  group('AnimatedProgressBar', () {
    testWidgets('fills from empty up to the value', (tester) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(width: 200, child: AnimatedProgressBar(value: .6)),
        ),
      );
      double? shown() => tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value;
      expect(shown(), 0);
      await tester.pumpAndSettle();
      expect(shown(), closeTo(.6, 1e-6));
    });

    testWidgets('clamps out of range values', (tester) async {
      await tester.pumpWidget(
        _host(const SizedBox(width: 200, child: AnimatedProgressBar(value: 3))),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        1,
      );
    });
  });

  group('PopOnChange', () {
    testWidgets('bounces when turned on, not when turned off', (tester) async {
      Widget build(bool active) =>
          _host(PopOnChange(active: active, child: const Text('x')));
      double scale() => tester
          .widget<ScaleTransition>(
            find.ancestor(
              of: find.text('x'),
              matching: find.byType(ScaleTransition),
            ),
          )
          .scale
          .value;

      await tester.pumpWidget(build(false));
      expect(scale(), 1);

      await tester.pumpWidget(build(true));
      await tester.pump(const Duration(milliseconds: 100));
      expect(scale(), greaterThan(1));
      await tester.pumpAndSettle();
      expect(scale(), closeTo(1, 1e-6));

      await tester.pumpWidget(build(false));
      await tester.pump(const Duration(milliseconds: 100));
      expect(scale(), 1);
    });
  });

  group('ShakeOnChange', () {
    testWidgets('moves sideways when trigger changes, rests afterwards', (
      tester,
    ) async {
      Widget build(int n) =>
          _host(ShakeOnChange(trigger: n, child: const Text('x')));
      double dx() => tester.getCenter(find.text('x')).dx;

      await tester.pumpWidget(build(0));
      final rest = dx();

      await tester.pumpWidget(build(1));
      await tester.pump(const Duration(milliseconds: 40));
      expect(dx(), isNot(closeTo(rest, 0.01)));

      await tester.pumpAndSettle();
      expect(dx(), closeTo(rest, 0.01));
    });

    testWidgets('does not move on first build', (tester) async {
      await tester.pumpWidget(
        _host(ShakeOnChange(trigger: 0, child: const Text('x'))),
      );
      final rest = tester.getCenter(find.text('x')).dx;
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.getCenter(find.text('x')).dx, rest);
    });
  });
}
