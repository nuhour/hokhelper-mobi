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

    await tester.scrollUntilVisible(
      find.text('Lam'),
      200,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(find.text('Lam'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Ally Picks'),
      -200,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Ally Picks'), findsOneWidget);
    expect(find.text('Slot 1: Lam'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Dolia'),
      200,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Dolia'), findsOneWidget);
    expect(find.text('Score 88.5'), findsOneWidget);
    expect(find.text('Blue 57.0%'), findsOneWidget);
  });

  testWidgets('switches recommendation type like the hokx team builder', (
    tester,
  ) async {
    final requestedTypes = <TeamRecommendType>[];

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
            final draft = ref.watch(teamBuilderDraftProvider);
            requestedTypes.add(draft.recommendType);
            return TeamRecommendationResult(
              recommendations: [
                TeamRecommendation(
                  heroId: draft.recommendType == TeamRecommendType.counter
                      ? 100
                      : 99,
                  externalHeroId:
                      draft.recommendType == TeamRecommendType.counter
                      ? '200'
                      : '199',
                  name: draft.recommendType == TeamRecommendType.counter
                      ? 'Anti-carry'
                      : 'Dolia',
                  mainJob: 6,
                  score: 88.5,
                  reason: draft.recommendType == TeamRecommendType.counter
                      ? 'Counter enemy burst'
                      : 'Strong synergy with Lam',
                  pickRate: 0.125,
                  banRate: 0.04,
                  synergy: 0.72,
                  counter: 0.81,
                ),
              ],
            );
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: TeamBuilderScreen())),
      ),
    );

    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Dolia'),
      200,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Dolia'), findsOneWidget);
    await tester.ensureVisible(find.text('Counter'));
    await tester.tap(find.text('Counter'));
    await tester.pumpAndSettle();

    expect(requestedTypes, contains(TeamRecommendType.counter));
    expect(find.text('Anti-carry'), findsOneWidget);
    expect(find.text('Counter enemy burst'), findsOneWidget);
  });

  testWidgets('selects ban slots and sends bans to recommendations', (
    tester,
  ) async {
    final requestedBans = <List<int>>[];
    final requestedSlotTypes = <String>[];

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
            ];
          }),
          teamRecommendationsProvider.overrideWith((ref) async {
            final draft = ref.watch(teamBuilderDraftProvider);
            requestedBans.add(draft.banIds);
            requestedSlotTypes.add(draft.activeSlotType.apiValue);
            return TeamRecommendationResult(
              recommendations: [
                TeamRecommendation(
                  heroId: draft.banIds.contains(42) ? 7 : 99,
                  externalHeroId: draft.banIds.contains(42) ? '107' : '199',
                  name: draft.banIds.contains(42) ? 'Marco Polo' : 'Dolia',
                  mainJob: 1,
                  score: 76,
                  reason: draft.banIds.contains(42)
                      ? 'Lam is removed from the pool'
                      : 'Default suggestion',
                  pickRate: 0.11,
                  banRate: 0.02,
                  synergy: 0.4,
                  counter: 0.7,
                ),
              ],
            );
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: TeamBuilderScreen())),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Ban 1: Empty'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Lam'),
      200,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(find.text('Lam'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Ban 1: Lam'),
      -200,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Bans'), findsOneWidget);
    expect(find.text('Ban 1: Lam'), findsOneWidget);
    expect(
      requestedBans,
      contains(predicate<List<int>>((ids) => ids.length == 1 && ids[0] == 42)),
    );
    expect(requestedSlotTypes, contains('ban'));
    await tester.scrollUntilVisible(
      find.text('Lam is removed from the pool'),
      200,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Marco Polo'), findsWidgets);
    expect(find.text('Lam is removed from the pool'), findsOneWidget);
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

  testWidgets('hydrates ban slots from team builder route query', (
    tester,
  ) async {
    final requestedBans = <List<int>>[];
    final requestedSlotTypes = <String>[];

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
            ];
          }),
          teamRecommendationsProvider.overrideWith((ref) async {
            final draft = ref.watch(teamBuilderDraftProvider);
            requestedBans.add(draft.banIds);
            requestedSlotTypes.add(draft.activeSlotType.apiValue);
            return const TeamRecommendationResult(recommendations: []);
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: TeamBuilderScreen(
              initialBanHeroIds: [42, 7],
              initialSlotType: TeamBuilderSlotType.ban,
              initialSlotIndex: 1,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Ban 1: Lam'), findsOneWidget);
    expect(find.text('Ban 2: Marco Polo'), findsOneWidget);
    expect(
      requestedBans,
      contains(
        predicate<List<int>>(
          (ids) => ids.length == 2 && ids[0] == 42 && ids[1] == 7,
        ),
      ),
    );
    expect(requestedSlotTypes, contains('ban'));
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

  testWidgets('team builder alias hydrates ban query in app router', (
    tester,
  ) async {
    final router = createAppRouter()
      ..go('/team-builder?ban_ids=42,7&slot_type=ban&slot=2');

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
    expect(find.text('Ban 1: Lam'), findsOneWidget);
    expect(find.text('Ban 2: Marco Polo'), findsOneWidget);
  });
}
