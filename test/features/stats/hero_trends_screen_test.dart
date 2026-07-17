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
    expect(find.text('Base Stats'), findsNothing);
    expect(find.text('Preparation'), findsNothing);
    expect(find.text('Trend Detail'), findsNothing);
    expect(find.text('All metrics'), findsNothing);
    expect(find.text('Core'), findsOneWidget);
    expect(find.text('KDA'), findsOneWidget);
    expect(find.text('Win Rate'), findsOneWidget);
    expect(find.text('56.10%'), findsOneWidget);
    expect(find.byKey(const ValueKey('trend-signal-hero-199')), findsOneWidget);
    expect(find.byKey(const ValueKey('trend-best-skill-199')), findsOneWidget);
    expect(find.byKey(const ValueKey('trend-best-equip-199')), findsOneWidget);
    expect(find.text('🔥'), findsNWidgets(2));
    expect(find.text('热'), findsNothing);
    expect(find.byIcon(Icons.arrow_drop_up_rounded), findsWidgets);
  });

  testWidgets('marks only the two largest seven-day rises and falls', (
    tester,
  ) async {
    final rows = <Object?>[
      _trendFixtureRow(1, [50, 51, 52, 54, 57, 59, 62]),
      _trendFixtureRow(2, [50, 51, 53, 55, 57, 58, 60]),
      _trendFixtureRow(3, [50, 50, 51, 51, 52, 52, 53]),
      _trendFixtureRow(4, [60, 58, 55, 53, 50, 47, 44]),
      _trendFixtureRow(5, [60, 59, 57, 55, 53, 51, 49]),
      _trendFixtureRow(6, [60, 60, 59, 59, 58, 58, 57]),
    ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          heroTrendTableProvider.overrideWith(
            (ref, query) async => sampleStatsTrendTable(rows: rows),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: HeroTrendsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('🔥'), findsNWidgets(2));
    expect(find.text('🧊'), findsNWidgets(2));
    expect(find.text('热'), findsNothing);
    final fireCenter = tester.getCenter(find.text('🔥').first);
    final trendCenter = tester.getCenter(
      find.byKey(const ValueKey('trend-signal-hero-1')),
    );
    expect((fireCenter.dy - trendCenter.dy).abs(), lessThan(10));
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

  testWidgets('avatar opens preparation details instead of trend details', (
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

    await tester.tap(find.byKey(const ValueKey('trend-avatar-hero-199')));
    await tester.pumpAndSettle();

    expect(find.text('Hero preparation'), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Power'), findsWidgets);
    expect(find.text('Single Equip'), findsOneWidget);
    expect(find.text('Builds'), findsOneWidget);
    await tester.tap(find.text('Single Equip'));
    await tester.pumpAndSettle();
    expect(find.text('Single equipment performance'), findsOneWidget);
    expect(find.text('Venomous Staff'), findsOneWidget);
    await tester.drag(
      find.byKey(const ValueKey('hero-preparation-tabs')),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('Pro Builds'), findsOneWidget);
    expect(find.text('Skill Flow'), findsOneWidget);
    expect(find.text('BP'), findsOneWidget);
    expect(find.text('Matchups'), findsNothing);
  });

  testWidgets('curve opens the separate trend details tabs', (tester) async {
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

    await tester.tap(find.byKey(const ValueKey('trend-curve-hero-199')));
    await tester.pumpAndSettle();

    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Power'), findsWidgets);
    expect(find.text('Playstyle'), findsOneWidget);
    expect(find.text('Equipment'), findsWidgets);
    await tester.drag(
      find.byKey(const ValueKey('trend-detail-tabs')),
      const Offset(-300, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('Matchups'), findsOneWidget);
    expect(find.text('Single Equip'), findsNothing);
    expect(find.text('Core trend'), findsOneWidget);
  });
}

Map<String, Object?> _trendFixtureRow(int id, List<num> trend) {
  return {
    'hero': {
      'id': id,
      'heroId': '$id',
      'name': 'Hero $id',
      'position': '${id % 5}',
    },
    'wr': trend.last,
    'pick_rate': 10 + id,
    'avg_kills': id,
    'trend_smoothed': trend,
  };
}
