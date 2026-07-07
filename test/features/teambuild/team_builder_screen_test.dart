import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/app/hok_helper_app.dart';
import 'package:hok_helper_mobile/src/app/router.dart';
import 'package:hok_helper_mobile/src/features/teambuild/domain/team_build_hero.dart';
import 'package:hok_helper_mobile/src/features/teambuild/domain/team_recommendation.dart';
import 'package:hok_helper_mobile/src/features/teambuild/presentation/team_builder_screen.dart';

void main() {
  testWidgets('selects ally hero and renders recommendations', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          teamBuilderHeroesProvider.overrideWith((ref) async {
            return const [
              TeamBuildHero(
                id: 42,
                externalHeroId: '142',
                name: 'Lam',
                mainJob: 3,
                avatarUrl: '',
              ),
            ];
          }),
          teamRecommendationsProvider.overrideWith((ref) async {
            return const TeamRecommendationResult(
              recommendations: [
                TeamRecommendation(
                  heroId: 99,
                  externalHeroId: '199',
                  name: 'Dolia',
                  mainJob: 6,
                  score: 88.5,
                  reason: 'Strong synergy with Lam',
                  pickRate: 0.125,
                  banRate: 0.04,
                  synergy: 0.72,
                  counter: 0.31,
                ),
              ],
              sideWinRates: TeamSideWinRates(blue: 0.57, red: 0.43),
            );
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: TeamBuilderScreen())),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Team Builder'), findsOneWidget);
    expect(find.text('Lam'), findsOneWidget);

    await tester.tap(find.text('Lam'));
    await tester.pumpAndSettle();

    expect(find.text('Ally Picks'), findsOneWidget);
    expect(find.text('Slot 1: Lam'), findsOneWidget);
    expect(find.text('Dolia'), findsOneWidget);
    expect(find.text('Score 88.5'), findsOneWidget);
    expect(find.text('Blue 57.0%'), findsOneWidget);
  });

  testWidgets('hydrates draft from hokx team builder route query', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          teamBuilderHeroesProvider.overrideWith((ref) async {
            return const [
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
                mainJob: 1,
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
          }),
          teamRecommendationsProvider.overrideWith((ref) async {
            return const TeamRecommendationResult(recommendations: []);
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: TeamBuilderScreen(
              initialAllyHeroIds: [42, 7],
              initialEnemyHeroIds: [99],
              initialSide: TeamBuilderSide.enemy,
              initialSlotIndex: 2,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Slot 1: Lam'), findsOneWidget);
    expect(find.text('Slot 2: Marco Polo'), findsOneWidget);
    expect(find.text('Slot 1: Dolia'), findsOneWidget);
  });

  testWidgets('web team builder alias hydrates draft in app router', (
    tester,
  ) async {
    final router = createAppRouter()
      ..go('/team-builder?ally_ids=42,7&enemy_id=99&side=enemy&slot=3');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          teamBuilderHeroesProvider.overrideWith((ref) async {
            return const [
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
                mainJob: 1,
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
          }),
          teamRecommendationsProvider.overrideWith((ref) async {
            return const TeamRecommendationResult(recommendations: []);
          }),
        ],
        child: HokHelperApp(router: router),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.path,
      '/tools/team-builder',
    );
    expect(find.text('Slot 1: Lam'), findsOneWidget);
    expect(find.text('Slot 2: Marco Polo'), findsOneWidget);
    expect(find.text('Slot 1: Dolia'), findsOneWidget);
  });
}
