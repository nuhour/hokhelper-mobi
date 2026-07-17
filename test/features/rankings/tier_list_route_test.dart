import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/app/hok_helper_app.dart';
import 'package:hok_helper_mobile/src/app/router.dart';
import 'package:hok_helper_mobile/src/features/heroes/presentation/hero_detail_screen.dart';
import 'package:hok_helper_mobile/src/features/rankings/domain/equip_ranking_entry.dart';
import 'package:hok_helper_mobile/src/features/rankings/domain/hero_ranking_entry.dart';
import 'package:hok_helper_mobile/src/features/rankings/domain/tier_list_entry.dart';
import 'package:hok_helper_mobile/src/features/rankings/presentation/hero_ranking_screen.dart';

void main() {
  testWidgets('web tier list route opens the mobile tier tab', (tester) async {
    final router = createAppRouter();
    router.go('/tier-list');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          heroRankingProvider.overrideWith((ref) async => const []),
          playerRankingProvider.overrideWith((ref) async => const []),
          equipRankingProvider.overrideWith((ref) async => const []),
          tierRankingProvider.overrideWith((ref) async {
            return const [
              TierListEntry(
                heroId: 42,
                externalHeroId: '199',
                name: 'Lam',
                mainJob: '4',
                tier: 'T0',
                position: 1,
                score: 96.5,
                winRate: 0.55,
              ),
            ];
          }),
          tierHistoryProvider.overrideWith((ref, heroId) async {
            return [
              TierHistoryPoint(
                date: DateTime(2026, 7, 14),
                tier: 1,
                source: 'all',
              ),
              TierHistoryPoint(
                date: DateTime(2026, 7, 15),
                tier: 0,
                source: 'all',
              ),
            ];
          }),
        ],
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hero Tier List'), findsOneWidget);
    expect(find.text('Lam'), findsOneWidget);
    expect(find.text('T0'), findsOneWidget);
    expect(find.byTooltip('Compact'), findsOneWidget);
    expect(find.byTooltip('Spacious'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Lam tier history'));
    await tester.pumpAndSettle();

    expect(find.text('Historical tier changes'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
  });

  testWidgets('web rankings tab query opens the requested mobile tab', (
    tester,
  ) async {
    final router = createAppRouter();
    router.go('/rankings?tab=equips');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          heroRankingProvider.overrideWith((ref) async => const []),
          playerRankingProvider.overrideWith((ref) async => const []),
          tierRankingProvider.overrideWith((ref) async => const []),
          equipRankingProvider.overrideWith((ref) async {
            return const [
              EquipRankingEntry(
                equipId: 501,
                name: 'Doombringer',
                pickRate: 0.184,
                winRate: 0.527,
              ),
            ];
          }),
        ],
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/tools/rankings');
    expect(find.text('Doombringer'), findsOneWidget);
    expect(find.text('Pick 18.4%'), findsOneWidget);
  });

  testWidgets('ranking hero cards open mobile hero detail routes', (
    tester,
  ) async {
    final router = createAppRouter();
    router.go('/tools/rankings');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          heroRankingProvider.overrideWith((ref) async {
            return const [
              HeroRankingEntry(
                heroId: 42,
                externalHeroId: '199',
                name: 'Lam',
                mainJob: 'Assassin',
                winRate: 0.543,
                pickRate: 0.125,
                banRate: 0.032,
                mvpRate: 0.21,
                avgKills: 8.4,
                avgAssists: 5.6,
                avgGrade: 13.1,
              ),
            ];
          }),
          playerRankingProvider.overrideWith((ref) async => const []),
          equipRankingProvider.overrideWith((ref) async => const []),
          tierRankingProvider.overrideWith((ref) async => const []),
          selectedRegionHeroDetailProvider.overrideWith((ref, heroId) async {
            return {
              'hero': {'id': int.tryParse(heroId) ?? 199, 'name': 'Lam'},
            };
          }),
        ],
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lam'));
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/heroes/199');
  });

  testWidgets('tier hero cards open mobile hero detail routes', (tester) async {
    final router = createAppRouter();
    router.go('/tier-list');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          heroRankingProvider.overrideWith((ref) async => const []),
          playerRankingProvider.overrideWith((ref) async => const []),
          equipRankingProvider.overrideWith((ref) async => const []),
          tierRankingProvider.overrideWith((ref) async {
            return const [
              TierListEntry(
                heroId: 42,
                externalHeroId: '199',
                name: 'Lam',
                mainJob: '4',
                tier: 'T0',
                position: 1,
                score: 96.5,
                winRate: 0.55,
              ),
            ];
          }),
          selectedRegionHeroDetailProvider.overrideWith((ref, heroId) async {
            return {
              'hero': {'id': int.tryParse(heroId) ?? 199, 'name': 'Lam'},
            };
          }),
        ],
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lam'));
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/heroes/199');
  });
}
