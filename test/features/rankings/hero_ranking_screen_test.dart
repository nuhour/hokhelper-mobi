import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/features/rankings/domain/equip_ranking_entry.dart';
import 'package:hok_helper_mobile/src/features/rankings/domain/hero_ranking_entry.dart';
import 'package:hok_helper_mobile/src/features/rankings/domain/player_ranking_entry.dart';
import 'package:hok_helper_mobile/src/features/rankings/domain/tier_list_entry.dart';
import 'package:hok_helper_mobile/src/features/rankings/presentation/hero_ranking_screen.dart';

void main() {
  testWidgets('renders hero ranking entries with metrics', (tester) async {
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
        ],
        child: const MaterialApp(home: Scaffold(body: HeroRankingScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hero Rankings'), findsOneWidget);
    expect(find.text('Lam'), findsOneWidget);
    expect(find.text('Assassin'), findsOneWidget);
    expect(find.text('54.3%'), findsOneWidget);
    expect(find.text('Pick 12.5%'), findsOneWidget);
    expect(find.text('Ban 3.2%'), findsOneWidget);
    expect(find.text('MVP 21.0%'), findsOneWidget);
    expect(find.text('Grade 13.1'), findsOneWidget);
  });

  testWidgets('renders player ranking entries from the player tab', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          heroRankingProvider.overrideWith((ref) async => const []),
          equipRankingProvider.overrideWith((ref) async => const []),
          tierRankingProvider.overrideWith((ref) async => const []),
          playerRankingProvider.overrideWith((ref) async {
            return const [
              PlayerRankingEntry(
                playerId: '1001',
                playerName: 'Top Mid',
                avatarUrl: '',
                peakScore: 2300.5,
                rankStars: 88,
                winRate: 0.612,
                avgKda: 6.8,
                playCount: 320,
                grade: 14.2,
                mvpCount: 90,
                region: 2,
                playerTypeLabel: 'Pro',
                bestHeroes: [
                  PlayerBestHero(heroId: 199, playCount: 80, score: 99.5),
                ],
              ),
            ];
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: HeroRankingScreen())),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Players'));
    await tester.pumpAndSettle();

    expect(find.text('Top Mid'), findsOneWidget);
    expect(find.text('Pro'), findsOneWidget);
    expect(find.text('2,300.5'), findsOneWidget);
    expect(find.text('Stars 88'), findsOneWidget);
    expect(find.text('Win 61.2%'), findsOneWidget);
    expect(find.text('KDA 6.8'), findsOneWidget);
    expect(find.text('Matches 320'), findsOneWidget);
  });

  testWidgets('renders equip ranking entries from the equips tab', (
    tester,
  ) async {
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
        child: const MaterialApp(home: Scaffold(body: HeroRankingScreen())),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Equips'));
    await tester.pumpAndSettle();

    expect(find.text('Doombringer'), findsOneWidget);
    expect(find.text('Pick 18.4%'), findsOneWidget);
    expect(find.text('Win 52.7%'), findsOneWidget);
  });

  testWidgets('renders grouped tier list without internal tabs', (
    tester,
  ) async {
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
        ],
        child: const MaterialApp(home: Scaffold(body: TierRankingScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lam'), findsOneWidget);
    expect(find.text('T0'), findsOneWidget);
    expect(find.text('1 heroes'), findsOneWidget);
    expect(find.text('Heroes'), findsNothing);
    expect(find.text('Players'), findsNothing);
    expect(find.text('Equips'), findsNothing);
  });
}
