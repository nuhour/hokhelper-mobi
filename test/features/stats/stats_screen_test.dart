import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/app/hok_helper_app.dart';
import 'package:hok_helper_mobile/src/app/router.dart';
import 'package:hok_helper_mobile/src/features/stats/domain/stats_dashboard.dart';
import 'package:hok_helper_mobile/src/features/stats/presentation/stats_screen.dart';

void main() {
  testWidgets('renders stats dashboard sections', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          statsDashboardProvider.overrideWith((ref, entry) async {
            return const StatsDashboard(
              heroes: [
                StatsHeroRow(
                  id: '199',
                  name: 'Lam',
                  avatarUrl: '',
                  winRate: 0.561,
                  pickRate: 0.18,
                  banRate: 0.07,
                  score: 91.4,
                ),
              ],
              equips: [
                StatsEquipRow(
                  id: '88',
                  name: 'Doomsday',
                  iconUrl: '',
                  pickRate: 0.22,
                  winRate: 0.53,
                ),
              ],
              combos: [
                StatsComboRow(
                  heroAName: 'Lam',
                  heroBName: 'Yaria',
                  matches: 1200,
                  winRate: 0.59,
                  score: 88.5,
                ),
              ],
            );
          }),
          statsEquipDetailProvider('88').overrideWith((ref) async {
            return const StatsEquipDetail(
              equipId: '88',
              equipName: 'Doomsday',
              equipIconUrl: '',
              heroes: [],
            );
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: StatsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Stats Dashboard'), findsOneWidget);
    expect(find.text('Hero Trends'), findsOneWidget);
    expect(find.text('Lam'), findsWidgets);
    expect(find.text('56.1% WR'), findsOneWidget);
    expect(find.text('Equipment Trends'), findsOneWidget);
    expect(find.text('Doomsday'), findsOneWidget);
    expect(find.text('22.0% pick'), findsOneWidget);
    expect(find.text('Hero Combos'), findsOneWidget);
    expect(find.text('Lam + Yaria'), findsOneWidget);
    expect(find.text('1200 matches'), findsOneWidget);
  });

  testWidgets('equip rank entry pins equipment trends and focused equip', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          statsDashboardProvider.overrideWith((ref, entry) async {
            return const StatsDashboard(
              heroes: [
                StatsHeroRow(
                  id: '199',
                  name: 'Lam',
                  avatarUrl: '',
                  winRate: 0.561,
                  pickRate: 0.18,
                  banRate: 0.07,
                  score: 91.4,
                ),
              ],
              equips: [
                StatsEquipRow(
                  id: '88',
                  name: 'Doomsday',
                  iconUrl: '',
                  pickRate: 0.22,
                  winRate: 0.53,
                ),
              ],
              combos: [
                StatsComboRow(
                  heroAName: 'Lam',
                  heroBName: 'Yaria',
                  matches: 1200,
                  winRate: 0.59,
                  score: 88.5,
                ),
              ],
            );
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: StatsScreen(
              initialEntry: StatsEntry.equipRank,
              initialEquipId: '88',
            ),
          ),
        ),
      ),
    );
    for (
      var i = 0;
      i < 10 && find.text('Focused equipment').evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Focused equipment'), findsOneWidget);
    final equipTopLeft = tester.getTopLeft(find.text('Equipment Trends'));
    final heroTopLeft = tester.getTopLeft(find.text('Hero Trends'));
    expect(equipTopLeft.dy, lessThan(heroTopLeft.dy));
  });

  testWidgets('focused equipment entry renders hero usage detail', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          statsDashboardProvider.overrideWith((ref, entry) async {
            return const StatsDashboard(
              equips: [
                StatsEquipRow(
                  id: '88',
                  name: 'Doomsday',
                  iconUrl: '',
                  pickRate: 0.22,
                  winRate: 0.53,
                ),
              ],
            );
          }),
          statsEquipDetailProvider('88').overrideWith((ref) async {
            return const StatsEquipDetail(
              equipId: '88',
              equipName: 'Doomsday',
              equipIconUrl: '',
              heroes: [
                StatsEquipHeroRow(
                  id: '199',
                  name: 'Lam',
                  avatarUrl: '',
                  pickRate: 0.42,
                  winRate: 0.57,
                  matches: 8900,
                ),
              ],
            );
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: StatsScreen(
              initialEntry: StatsEntry.equipRank,
              initialEquipId: '88',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Equipment Hero Usage'), findsOneWidget);
    expect(find.text('Doomsday'), findsWidgets);
    expect(find.text('Lam'), findsOneWidget);
    expect(find.text('42.0% pick'), findsOneWidget);
    expect(find.text('8900 matches'), findsOneWidget);
  });

  testWidgets('focused hero entry renders equipment usage detail', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          statsDashboardProvider.overrideWith((ref, entry) async {
            return const StatsDashboard(
              heroes: [
                StatsHeroRow(
                  id: '199',
                  name: 'Lam',
                  avatarUrl: '',
                  winRate: 0.561,
                  pickRate: 0.18,
                  banRate: 0.07,
                  score: 91.4,
                ),
              ],
            );
          }),
          statsHeroDetailProvider('199').overrideWith((ref) async {
            return const StatsHeroDetail(
              heroId: '199',
              heroName: 'Lam',
              heroAvatarUrl: '',
              equips: [
                StatsHeroEquipRow(
                  id: '88',
                  name: 'Doomsday',
                  iconUrl: '',
                  pickRate: 0.42,
                  winRate: 0.57,
                  matches: 8900,
                ),
              ],
            );
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: StatsScreen(
              initialEntry: StatsEntry.tierRank,
              initialHeroId: '199',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hero Build Usage'), findsOneWidget);
    expect(find.text('Lam'), findsWidgets);
    expect(find.text('Doomsday'), findsOneWidget);
    expect(find.text('42.0% pick'), findsOneWidget);
    expect(find.text('8900 matches'), findsOneWidget);
  });

  testWidgets('home core entry highlights overview stats', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          statsDashboardProvider.overrideWith((ref, entry) async {
            return const StatsDashboard(
              heroes: [
                StatsHeroRow(
                  id: '199',
                  name: 'Lam',
                  avatarUrl: '',
                  winRate: 0.561,
                  pickRate: 0.18,
                  banRate: 0.07,
                  score: 91.4,
                ),
              ],
              equips: [
                StatsEquipRow(
                  id: '88',
                  name: 'Doomsday',
                  iconUrl: '',
                  pickRate: 0.22,
                  winRate: 0.53,
                ),
              ],
              combos: [
                StatsComboRow(
                  heroAName: 'Lam',
                  heroBName: 'Yaria',
                  matches: 1200,
                  winRate: 0.59,
                  score: 88.5,
                ),
              ],
            );
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(body: StatsScreen(initialEntry: StatsEntry.homeCore)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Focused home core stats'), findsOneWidget);
  });

  testWidgets('stats hero cards open focused hero usage detail route', (
    tester,
  ) async {
    final router = createAppRouter();
    router.go('/tools/stats');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          statsDashboardProvider.overrideWith((ref, entry) async {
            return const StatsDashboard(
              heroes: [
                StatsHeroRow(
                  id: '199',
                  name: 'Lam',
                  avatarUrl: '',
                  winRate: 0.561,
                  pickRate: 0.18,
                  banRate: 0.07,
                  score: 91.4,
                ),
              ],
              equips: [],
              combos: [],
            );
          }),
          statsHeroDetailProvider('199').overrideWith((ref) async {
            return const StatsHeroDetail(
              heroId: '199',
              heroName: 'Lam',
              heroAvatarUrl: '',
              equips: [
                StatsHeroEquipRow(
                  id: '88',
                  name: 'Doomsday',
                  iconUrl: '',
                  pickRate: 0.42,
                  winRate: 0.57,
                  matches: 8900,
                ),
              ],
            );
          }),
        ],
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lam'));
    await tester.pumpAndSettle();

    final uri = router.routeInformationProvider.value.uri;
    expect(uri.path, '/tools/stats');
    expect(uri.queryParameters['entry'], 'tier_rank');
    expect(uri.queryParameters['hero_id'], '199');
    expect(find.text('Hero Build Usage'), findsOneWidget);
    expect(find.text('Doomsday'), findsOneWidget);
  });

  testWidgets(
    'stats equipment cards open focused equipment usage detail route',
    (tester) async {
      final router = createAppRouter();
      router.go('/tools/stats');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            statsDashboardProvider.overrideWith((ref, entry) async {
              return const StatsDashboard(
                heroes: [],
                equips: [
                  StatsEquipRow(
                    id: '88',
                    name: 'Doomsday',
                    iconUrl: '',
                    pickRate: 0.22,
                    winRate: 0.53,
                  ),
                ],
                combos: [],
              );
            }),
            statsEquipDetailProvider('88').overrideWith((ref) async {
              return const StatsEquipDetail(
                equipId: '88',
                equipName: 'Doomsday',
                equipIconUrl: '',
                heroes: [
                  StatsEquipHeroRow(
                    id: '199',
                    name: 'Lam',
                    avatarUrl: '',
                    pickRate: 0.42,
                    winRate: 0.57,
                    matches: 8900,
                  ),
                ],
              );
            }),
          ],
          child: HokHelperApp(router: router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Doomsday'));
      await tester.pumpAndSettle();

      final uri = router.routeInformationProvider.value.uri;
      expect(uri.path, '/tools/stats');
      expect(uri.queryParameters['entry'], 'equip_rank');
      expect(uri.queryParameters['equip_id'], '88');
      expect(find.text('Equipment Hero Usage'), findsOneWidget);
      expect(find.text('Lam'), findsOneWidget);
    },
  );

  testWidgets('equipment usage hero rows open focused hero detail route', (
    tester,
  ) async {
    final router = createAppRouter();
    router.go('/tools/stats?entry=equip_rank&equip_id=88');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          statsDashboardProvider.overrideWith((ref, entry) async {
            return const StatsDashboard(
              heroes: [],
              equips: [
                StatsEquipRow(
                  id: '88',
                  name: 'Doomsday',
                  iconUrl: '',
                  pickRate: 0.22,
                  winRate: 0.53,
                ),
              ],
              combos: [],
            );
          }),
          statsEquipDetailProvider('88').overrideWith((ref) async {
            return const StatsEquipDetail(
              equipId: '88',
              equipName: 'Doomsday',
              equipIconUrl: '',
              heroes: [
                StatsEquipHeroRow(
                  id: '199',
                  name: 'Lam',
                  avatarUrl: '',
                  pickRate: 0.42,
                  winRate: 0.57,
                  matches: 8900,
                ),
              ],
            );
          }),
          statsHeroDetailProvider('199').overrideWith((ref) async {
            return const StatsHeroDetail(
              heroId: '199',
              heroName: 'Lam',
              heroAvatarUrl: '',
              equips: [
                StatsHeroEquipRow(
                  id: '88',
                  name: 'Doomsday',
                  iconUrl: '',
                  pickRate: 0.42,
                  winRate: 0.57,
                  matches: 8900,
                ),
              ],
            );
          }),
        ],
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lam'));
    await tester.pumpAndSettle();

    final uri = router.routeInformationProvider.value.uri;
    expect(uri.path, '/tools/stats');
    expect(uri.queryParameters['entry'], 'tier_rank');
    expect(uri.queryParameters['hero_id'], '199');
    expect(find.text('Hero Build Usage'), findsOneWidget);
    expect(find.text('Doomsday'), findsWidgets);
  });

  testWidgets('hero usage equipment rows open focused equipment detail route', (
    tester,
  ) async {
    final router = createAppRouter();
    router.go('/tools/stats?entry=tier_rank&hero_id=199');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          statsDashboardProvider.overrideWith((ref, entry) async {
            return const StatsDashboard(
              heroes: [
                StatsHeroRow(
                  id: '199',
                  name: 'Lam',
                  avatarUrl: '',
                  winRate: 0.561,
                  pickRate: 0.18,
                  banRate: 0.07,
                  score: 91.4,
                ),
              ],
              equips: [],
              combos: [],
            );
          }),
          statsHeroDetailProvider('199').overrideWith((ref) async {
            return const StatsHeroDetail(
              heroId: '199',
              heroName: 'Lam',
              heroAvatarUrl: '',
              equips: [
                StatsHeroEquipRow(
                  id: '88',
                  name: 'Doomsday',
                  iconUrl: '',
                  pickRate: 0.42,
                  winRate: 0.57,
                  matches: 8900,
                ),
              ],
            );
          }),
          statsEquipDetailProvider('88').overrideWith((ref) async {
            return const StatsEquipDetail(
              equipId: '88',
              equipName: 'Doomsday',
              equipIconUrl: '',
              heroes: [
                StatsEquipHeroRow(
                  id: '199',
                  name: 'Lam',
                  avatarUrl: '',
                  pickRate: 0.42,
                  winRate: 0.57,
                  matches: 8900,
                ),
              ],
            );
          }),
        ],
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Doomsday'));
    await tester.pumpAndSettle();

    final uri = router.routeInformationProvider.value.uri;
    expect(uri.path, '/tools/stats');
    expect(uri.queryParameters['entry'], 'equip_rank');
    expect(uri.queryParameters['equip_id'], '88');
    expect(find.text('Equipment Hero Usage'), findsOneWidget);
    expect(find.text('Lam'), findsWidgets);
  });

  testWidgets('tier rank entry reaches the stats repository entry config', (
    tester,
  ) async {
    var usedTierRankProvider = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          statsDashboardProvider(StatsDashboardEntry.tierRank).overrideWith((
            ref,
          ) async {
            usedTierRankProvider = true;
            return const StatsDashboard(
              heroes: [
                StatsHeroRow(
                  id: '133',
                  name: 'Augran',
                  avatarUrl: '',
                  winRate: 0.62,
                  pickRate: 0.16,
                  banRate: 0.23,
                  score: 96.8,
                ),
              ],
            );
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(body: StatsScreen(initialEntry: StatsEntry.tierRank)),
        ),
      ),
    );
    for (var i = 0; i < 10 && !usedTierRankProvider; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump();

    expect(usedTierRankProvider, true);
    expect(find.text('Focused tier rank'), findsOneWidget);
    expect(find.text('Augran'), findsOneWidget);
  });

  testWidgets('player rank entry renders stats player leaderboard section', (
    tester,
  ) async {
    var usedPlayerRankProvider = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          statsDashboardProvider(StatsDashboardEntry.playerRank).overrideWith((
            ref,
          ) async {
            usedPlayerRankProvider = true;
            return const StatsDashboard(
              players: [
                StatsPlayerRow(
                  playerId: 'p1',
                  playerName: 'Top Laner',
                  avatarUrl: '',
                  peakScore: 2310,
                  rankStars: 88,
                  winRate: 0.63,
                  avgKda: 7.2,
                  playCount: 320,
                  grade: 98.6,
                ),
              ],
            );
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: StatsScreen(initialEntry: StatsEntry.playerRank),
          ),
        ),
      ),
    );
    for (var i = 0; i < 10 && !usedPlayerRankProvider; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump();

    expect(usedPlayerRankProvider, true);
    expect(find.text('Player Rankings'), findsOneWidget);
    expect(find.text('Focused player rank'), findsOneWidget);
    expect(find.text('Top Laner'), findsOneWidget);
    expect(find.text('2310 peak'), findsOneWidget);
    expect(find.text('63.0% WR'), findsOneWidget);
    expect(find.text('320 matches'), findsOneWidget);
  });
}
