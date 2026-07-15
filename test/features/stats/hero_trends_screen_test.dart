import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/features/stats/presentation/hero_trends_screen.dart';

import 'stats_trends_fixture.dart';

void main() {
  testWidgets('renders metadata driven filters, views, groups, and columns', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          heroTrendTableProvider.overrideWith((ref, query) async {
            return sampleStatsTrendTable(
              dimension: query.dimension,
              view: query.view,
            );
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: HeroTrendsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hero'), findsWidgets);
    expect(find.text('Power'), findsOneWidget);
    expect(find.text('Player'), findsOneWidget);
    expect(find.text('Equipment'), findsOneWidget);
    expect(find.text('Tier'), findsOneWidget);
    expect(find.text('Base Stats'), findsOneWidget);
    expect(find.text('Preparation'), findsOneWidget);
    expect(find.text('All metrics'), findsOneWidget);
    expect(find.text('Core'), findsOneWidget);
    expect(find.text('KDA'), findsOneWidget);
    expect(find.text('Win Rate'), findsOneWidget);
    expect(find.text('56.10%'), findsOneWidget);
    expect(find.byKey(const ValueKey('trend-signal-hero-199')), findsOneWidget);
    expect(find.text('热'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_drop_up_rounded), findsWidgets);
  });

  testWidgets('changes dimension and sends the matching table query', (
    tester,
  ) async {
    final dimensions = <String>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          heroTrendTableProvider.overrideWith((ref, query) async {
            dimensions.add(query.dimension);
            return sampleStatsTrendTable(
              dimension: query.dimension,
              view: query.view,
            );
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: HeroTrendsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Power'));
    await tester.pumpAndSettle();

    expect(dimensions, contains('hero_rank'));
    expect(dimensions, contains('power_rank'));
  });

  testWidgets('opens the complete trend scope filters without asset errors', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          heroTrendTableProvider.overrideWith(
            (ref, query) async => sampleStatsTrendTable(),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: HeroTrendsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Top 1000'));
    await tester.pumpAndSettle();

    expect(find.text('Trend scope'), findsOneWidget);
    expect(find.text('Lane'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName.startsWith(
              'assets/lane-icons/',
            ),
      ),
      findsNWidgets(5),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens in-app hero detail sheet with multiple tabs', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          heroTrendTableProvider.overrideWith(
            (ref, query) async => sampleStatsTrendTable(),
          ),
          heroTrendDetailProvider.overrideWith(
            (ref, request) async => sampleStatsTrendDetail(),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: HeroTrendsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('trend-row-hero-199')));
    await tester.pumpAndSettle();

    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Power'), findsWidgets);
    expect(find.text('Playstyle'), findsOneWidget);
    expect(find.text('Equipment'), findsWidgets);
    expect(find.text('Core trend'), findsOneWidget);
  });
}
