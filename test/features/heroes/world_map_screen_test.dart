import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/features/heroes/domain/hero_summary.dart';
import 'package:hok_helper_mobile/src/features/heroes/presentation/world_map_screen.dart';

void main() {
  testWidgets('renders world regions and opens region detail', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          worldMapHeroesProvider.overrideWith((ref) async {
            return const [
              HeroSummary(
                id: '1',
                heroId: '166',
                name: 'Yaria',
                avatar: '',
                title: 'Forest Child',
              ),
              HeroSummary(
                id: '2',
                heroId: '199',
                name: 'Lam',
                avatar: '',
                title: 'Shark Blade',
              ),
            ];
          }),
        ],
        child: const MaterialApp(home: WorldMapScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byTooltip('Exit world map'), findsOneWidget);
    expect(find.text('Sunset Sea'), findsOneWidget);
    expect(find.text('Great River Basin'), findsOneWidget);

    await tester.tap(find.text('Great River Basin'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Domain Records'), findsOneWidget);
    expect(find.text('Representative Heroes'), findsOneWidget);
    expect(find.text('Shark Blade'), findsOneWidget);
  });

  testWidgets('opens focused region from initial hero id', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          worldMapHeroesProvider.overrideWith((ref) async {
            return const [
              HeroSummary(
                id: '2',
                heroId: '199',
                name: 'Lam',
                avatar: '',
                title: 'Shark Blade',
              ),
            ];
          }),
        ],
        child: const MaterialApp(home: WorldMapScreen(initialHeroId: '199')),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Domain Records'), findsOneWidget);
    expect(find.text('Great River Basin'), findsWidgets);
    expect(find.text('Lam'), findsOneWidget);
    expect(find.text('Shark Blade'), findsOneWidget);
  });
}
