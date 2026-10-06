import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qspot/screens/home/widgets/today_greeting.dart';
import 'package:qspot/screens/home/widgets/today_hero_card.dart';
import 'package:qspot/themes/home_theme.dart';

void main() {
  testWidgets('greeting and hero fit a narrow, enlarged-text viewport', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: HomeTheme.light,
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 900),
              textScaler: TextScaler.linear(1.3),
            ),
            child: const SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TodayGreeting(name: 'Test Learner'),
                  TodayHeroCard(
                    eyebrow: 'NEEDS YOUR ATTENTION',
                    title: 'Record Surah Al-Fatihah',
                    progressLabel: '3 items in your plan',
                    onAction: _noop,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Hey Test 👋'), findsOneWidget);
    expect(find.text('Record Surah Al-Fatihah'), findsOneWidget);
  });
}

void _noop() {}
