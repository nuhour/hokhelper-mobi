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
          statsDashboardProvider.overrideWith((ref) async {
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
}
