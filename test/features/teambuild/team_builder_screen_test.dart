import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/features/teambuild/domain/team_build_hero.dart';
import 'package:hok_helper_mobile/src/features/teambuild/domain/team_recommendation.dart';
import 'package:hok_helper_mobile/src/features/teambuild/presentation/team_builder_screen.dart';

const _heroes = [
  TeamBuildHero(
    id: 42,
    externalHeroId: '142',
    name: 'Lam',
    mainJob: 3,
    avatarUrl: '',
  ),
  TeamBuildHero(
    id: 7,
    externalHeroId: '107',
    name: 'Marco Polo',
    mainJob: 5,
    avatarUrl: '',
  ),
  TeamBuildHero(
    id: 99,
    externalHeroId: '199',
    name: 'Dolia',
    mainJob: 6,
    avatarUrl: '',
  ),
];

Widget _app({TeamBuilderScreen screen = const TeamBuilderScreen()}) =>
    ProviderScope(
      overrides: [
        teamBuilderHeroesProvider.overrideWith((ref) async => _heroes),
        teamRecommendationsProvider.overrideWith(
          (ref) async => const TeamRecommendationResult(
            recommendations: [
              TeamRecommendation(
                heroId: 99,
                externalHeroId: '199',
                name: 'Dolia',
                mainJob: 6,
                score: .79,
                reason: 'Fits the lineup',
                pickRate: .1,
                banRate: .02,
                synergy: .5,
                counter: .4,
              ),
            ],
            sideWinRates: TeamSideWinRates(blue: .57, red: .43),
          ),
        ),
      ],
      child: MaterialApp(home: Scaffold(body: screen)),
    );

void main() {
  testWidgets('renders the HOKX-style mobile team builder workspace', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(find.text('Smart Team Builder'), findsOneWidget);
    expect(find.text('Synergy Picks'), findsOneWidget);
    expect(find.text('Counter Picks'), findsOneWidget);
    expect(find.text('Dolia'), findsOneWidget);
  });

  testWidgets('fills the active pick slot and locks the hero in the pool', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('team-pool-42')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('team-pick-ally-0')), findsOneWidget);
  });

  testWidgets(
    'uses either ban strip side and sends its combined bans to recommendations',
    (tester) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('team-ban-ally-0')));
      await tester.tap(find.byKey(const ValueKey('team-pool-42')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('team-ban-ally-0')), findsOneWidget);
    },
  );

  testWidgets(
    'hydrates incoming HOKX draft query values into workspace slots',
    (tester) async {
      await tester.pumpWidget(
        _app(
          screen: const TeamBuilderScreen(
            initialAllyHeroIds: [42],
            initialEnemyHeroIds: [99],
            initialBanHeroIds: [7],
            initialSlotType: TeamBuilderSlotType.ban,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('team-pick-ally-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('team-pick-enemy-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('team-ban-ally-0')), findsOneWidget);
    },
  );
}
