import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
    await tester.pumpAndSettle();

    expect(find.text('Focused equipment'), findsOneWidget);
    final equipTopLeft = tester.getTopLeft(find.text('Equipment Trends'));
    final heroTopLeft = tester.getTopLeft(find.text('Hero Trends'));
    expect(equipTopLeft.dy, lessThan(heroTopLeft.dy));
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
}
