import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/features/stats/domain/hero_trend_row.dart';
import 'package:hok_helper_mobile/src/features/stats/presentation/hero_trends_screen.dart';

void main() {
  testWidgets('renders hero trends and changes sorting metric', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          heroTrendsProvider.overrideWith((ref) async {
            return const [
              HeroTrendRow(
                id: 199,
                name: 'Lam',
                avatarUrl: '',
                winRate: 56.1,
                mvpScore: 13.8,
                mvpRate: 22.5,
                dmgShare: 31.4,
                takeDmgShare: 28.7,
                ecoShare: 24.1,
              ),
              HeroTrendRow(
                id: 166,
                name: 'Yaria',
                avatarUrl: '',
                winRate: 60.2,
                mvpScore: 9.2,
                mvpRate: 11.4,
                dmgShare: 12.1,
                takeDmgShare: 18.2,
                ecoShare: 17.7,
              ),
            ];
          }),
        ],
        child: const MaterialApp(home: HeroTrendsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hero Trends'), findsOneWidget);
    expect(find.text('Lam'), findsOneWidget);
    expect(find.text('Score 13.80'), findsOneWidget);
    expect(find.text('56.10% win'), findsOneWidget);
    expect(find.text('31.40% damage'), findsOneWidget);

    await tester.tap(find.text('Win Rate'));
    await tester.pumpAndSettle();

    final yariaTopLeft = tester.getTopLeft(find.text('Yaria'));
    final lamTopLeft = tester.getTopLeft(find.text('Lam'));
    expect(yariaTopLeft.dy, lessThan(lamTopLeft.dy));
  });

  testWidgets('initial hero id pins and labels the focused hero', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          heroTrendsProvider.overrideWith((ref) async {
            return const [
              HeroTrendRow(
                id: 199,
                name: 'Lam',
                avatarUrl: '',
                winRate: 56.1,
                mvpScore: 13.8,
                mvpRate: 22.5,
                dmgShare: 31.4,
                takeDmgShare: 28.7,
                ecoShare: 24.1,
              ),
              HeroTrendRow(
                id: 166,
                name: 'Yaria',
                avatarUrl: '',
                winRate: 60.2,
                mvpScore: 9.2,
                mvpRate: 11.4,
                dmgShare: 12.1,
                takeDmgShare: 18.2,
                ecoShare: 17.7,
              ),
            ];
          }),
        ],
        child: const MaterialApp(home: HeroTrendsScreen(initialHeroId: 166)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Focused hero'), findsOneWidget);
    final yariaTopLeft = tester.getTopLeft(find.text('Yaria'));
    final lamTopLeft = tester.getTopLeft(find.text('Lam'));
    expect(yariaTopLeft.dy, lessThan(lamTopLeft.dy));
  });
}
