import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/features/rankings/domain/hero_ranking_entry.dart';
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
}
