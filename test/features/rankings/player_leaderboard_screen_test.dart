import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/features/rankings/domain/player_leaderboard_result.dart';
import 'package:hok_helper_mobile/src/features/rankings/domain/player_ranking_entry.dart';
import 'package:hok_helper_mobile/src/features/rankings/presentation/player_leaderboard_screen.dart';

void main() {
  testWidgets('renders ranked leaderboard and toggles peak mode', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerLeaderboardProvider.overrideWith((ref) async {
            return const PlayerLeaderboardResult(
              players: [
                PlayerRankingEntry(
                  playerId: 'p-100',
                  playerName: 'Top Mid',
                  avatarUrl: '',
                  peakScore: 2490,
                  rankStars: 112,
                  winRate: 0.684,
                  avgKda: 7.2,
                  playCount: 380,
                  grade: 15.3,
                  mvpCount: 98,
                  region: 44,
                  playerTypeLabel: 'Pro',
                  bestHeroes: [
                    PlayerBestHero(
                      heroId: 131,
                      heroName: 'Diaochan',
                      avatarUrl: 'https://example.test/diaochan.png',
                      playCount: 72,
                      score: 99.1,
                    ),
                  ],
                ),
              ],
              total: 1,
              regionId: 0,
              rankType: 'rank',
              regionOptions: [44, 62],
            );
          }),
        ],
        child: const MaterialApp(home: PlayerLeaderboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Player'), findsOneWidget);
    expect(find.text('Ranked'), findsAtLeastNWidgets(1));
    expect(find.text('Peak'), findsOneWidget);
    expect(find.text('Top Mid'), findsOneWidget);
    expect(find.text('112'), findsOneWidget);
    expect(find.text('68.40% win'), findsOneWidget);
    expect(find.text('Pro'), findsOneWidget);
    expect(find.text('Favorite Heroes'), findsOneWidget);
    expect(find.byTooltip('Diaochan · 99.1'), findsOneWidget);

    await tester.tap(find.text('Peak'));
    await tester.pumpAndSettle();

    expect(find.text('2490'), findsOneWidget);
  });

  testWidgets('opens with initial rank type and region filter', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerLeaderboardProvider.overrideWith((ref) async {
            return const PlayerLeaderboardResult(
              players: [],
              total: 0,
              regionId: 44,
              rankType: 'peak',
              regionOptions: [44, 62],
            );
          }),
        ],
        child: const MaterialApp(
          home: PlayerLeaderboardScreen(
            initialRankType: PlayerLeaderboardRankType.peak,
            initialRegionId: 44,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Peak'), findsAtLeastNWidgets(1));
    expect(find.text('BS (+44)'), findsAtLeastNWidgets(1));
  });
}
