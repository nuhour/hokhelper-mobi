import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hok_helper_mobile/src/app/hok_helper_app.dart';
import 'package:hok_helper_mobile/src/app/router.dart';
import 'package:hok_helper_mobile/src/features/bp/domain/bp_scheme_summary.dart';
import 'package:hok_helper_mobile/src/features/bp/presentation/bp_dashboard_screen.dart';
import 'package:hok_helper_mobile/src/features/builds/presentation/build_explorer_screen.dart';
import 'package:hok_helper_mobile/src/features/builds/presentation/build_simulator_screen.dart';
import 'package:hok_helper_mobile/src/features/curiosity/presentation/curiosity_lab_screen.dart';
import 'package:hok_helper_mobile/src/features/esports/domain/esports_match_summary.dart';
import 'package:hok_helper_mobile/src/features/esports/domain/esports_player_summary.dart';
import 'package:hok_helper_mobile/src/features/esports/domain/esports_team_summary.dart';
import 'package:hok_helper_mobile/src/features/esports/presentation/esports_screen.dart';
import 'package:hok_helper_mobile/src/features/game_assistant/presentation/game_assistant_screen.dart';
import 'package:hok_helper_mobile/src/features/prompts/data/prompts_repository.dart';
import 'package:hok_helper_mobile/src/features/prompts/domain/prompt_summary.dart';
import 'package:hok_helper_mobile/src/features/prompts/presentation/prompts_screen.dart';
import 'package:hok_helper_mobile/src/features/rank_fortune/domain/rank_fortune.dart';
import 'package:hok_helper_mobile/src/features/rank_fortune/presentation/rank_fortune_screen.dart';
import 'package:hok_helper_mobile/src/features/rankings/domain/hero_ranking_entry.dart';
import 'package:hok_helper_mobile/src/features/rankings/presentation/hero_ranking_screen.dart';
import 'package:hok_helper_mobile/src/features/rankings/presentation/tools_screen.dart';
import 'package:hok_helper_mobile/src/features/stats/domain/stats_dashboard.dart';
import 'package:hok_helper_mobile/src/features/stats/presentation/stats_screen.dart';
import 'package:hok_helper_mobile/src/features/teambuild/domain/team_build_hero.dart';
import 'package:hok_helper_mobile/src/features/teambuild/domain/team_recommendation.dart';
import 'package:hok_helper_mobile/src/features/teambuild/presentation/team_builder_screen.dart';
import 'package:hok_helper_mobile/src/features/tierlist_tool/domain/tierlist_scheme_summary.dart';
import 'package:hok_helper_mobile/src/features/tierlist_tool/presentation/tierlist_tool_screen.dart';

Widget _toolRoutePage(Widget child) => Scaffold(body: child);

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/tools',
    routes: [
      GoRoute(
        path: '/tools',
        builder: (context, state) => const ToolsScreen(),
        routes: [
          GoRoute(
            path: 'builds',
            builder: (context, state) =>
                _toolRoutePage(const BuildExplorerScreen()),
          ),
          GoRoute(
            path: 'build-sim',
            builder: (context, state) =>
                _toolRoutePage(const BuildSimulatorScreen()),
          ),
          GoRoute(
            path: 'bp-simulator',
            builder: (context, state) =>
                _toolRoutePage(const BpDashboardScreen()),
          ),
          GoRoute(
            path: 'tier-list',
            builder: (context, state) =>
                _toolRoutePage(const TierListToolScreen()),
          ),
          GoRoute(
            path: 'game-assistant',
            builder: (context, state) =>
                _toolRoutePage(const GameAssistantScreen()),
          ),
          GoRoute(
            path: 'rank-fortune',
            builder: (context, state) =>
                _toolRoutePage(const RankFortuneScreen()),
          ),
          GoRoute(
            path: 'curiosity-lab',
            builder: (context, state) =>
                _toolRoutePage(const CuriosityLabScreen()),
          ),
          GoRoute(
            path: 'rankings',
            builder: (context, state) =>
                _toolRoutePage(const HeroRankingScreen()),
          ),
          GoRoute(
            path: 'team-builder',
            builder: (context, state) =>
                _toolRoutePage(const TeamBuilderScreen()),
          ),
          GoRoute(
            path: 'prompts',
            builder: (context, state) => _toolRoutePage(const PromptsScreen()),
          ),
          GoRoute(
            path: 'esports',
            builder: (context, state) => _toolRoutePage(const EsportsScreen()),
          ),
          GoRoute(
            path: 'stats',
            builder: (context, state) => _toolRoutePage(const StatsScreen()),
          ),
        ],
      ),
    ],
  );
}

List<Override> _emptyToolOverrides() {
  return [
    publicBuildSchemesProvider.overrideWith((ref) async => const []),
    buildSimHeroesProvider.overrideWith((ref) async => const []),
    buildSimPublicSchemesProvider.overrideWith((ref) async => const []),
    buildSimUserSlotsProvider.overrideWith((ref, heroId) async => const []),
    bpSchemesProvider.overrideWith((ref) async => const []),
    tierListToolSchemesProvider.overrideWith((ref) async => const []),
    heroRankingProvider.overrideWith((ref) async => const []),
    playerRankingProvider.overrideWith((ref) async => const []),
    equipRankingProvider.overrideWith((ref) async => const []),
    tierRankingProvider.overrideWith((ref) async => const []),
    teamBuilderHeroesProvider.overrideWith((ref) async => const []),
    teamRecommendationsProvider.overrideWith(
      (ref) async => const TeamRecommendationResult(recommendations: []),
    ),
    promptListProvider(
      PromptListAction.explore,
    ).overrideWith((ref) async => const []),
    esportsMatchesProvider.overrideWith((ref) async => const []),
    esportsTeamsProvider.overrideWith((ref) async => const []),
    esportsPlayersProvider.overrideWith((ref) async => const []),
    statsDashboardProvider.overrideWith(
      (ref, entry) async => const StatsDashboard(),
    ),
  ];
}

List<Override> _toolOverrides({
  Future<List<HeroRankingEntry>> Function(Ref)? heroRanking,
  Future<List<BpSchemeSummary>> Function(Ref)? bpSchemes,
  Future<List<TierListSchemeSummary>> Function(Ref)? tierListSchemes,
  Future<List<TeamBuildHero>> Function(Ref)? teamBuilderHeroes,
  Future<List<PromptSummary>> Function(Ref)? publicPrompts,
  Future<List<EsportsMatchSummary>> Function(Ref)? esportsMatches,
  Future<List<EsportsTeamSummary>> Function(Ref)? esportsTeams,
  Future<List<EsportsPlayerSummary>> Function(Ref)? esportsPlayers,
  Future<StatsDashboard> Function(Ref, StatsDashboardEntry)? statsDashboard,
}) {
  return [
    publicBuildSchemesProvider.overrideWith((ref) async => const []),
    buildSimHeroesProvider.overrideWith((ref) async => const []),
    buildSimPublicSchemesProvider.overrideWith((ref) async => const []),
    buildSimUserSlotsProvider.overrideWith((ref, heroId) async => const []),
    bpSchemesProvider.overrideWith(bpSchemes ?? (ref) async => const []),
    tierListToolSchemesProvider.overrideWith(
      tierListSchemes ?? (ref) async => const [],
    ),
    heroRankingProvider.overrideWith(heroRanking ?? (ref) async => const []),
    playerRankingProvider.overrideWith((ref) async => const []),
    equipRankingProvider.overrideWith((ref) async => const []),
    tierRankingProvider.overrideWith((ref) async => const []),
    teamBuilderHeroesProvider.overrideWith(
      teamBuilderHeroes ?? (ref) async => const [],
    ),
    teamRecommendationsProvider.overrideWith(
      (ref) async => const TeamRecommendationResult(recommendations: []),
    ),
    promptListProvider(
      PromptListAction.explore,
    ).overrideWith(publicPrompts ?? (ref) async => const []),
    esportsMatchesProvider.overrideWith(
      esportsMatches ?? (ref) async => const [],
    ),
    esportsTeamsProvider.overrideWith(esportsTeams ?? (ref) async => const []),
    esportsPlayersProvider.overrideWith(
      esportsPlayers ?? (ref) async => const [],
    ),
    statsDashboardProvider.overrideWith(
      statsDashboard ?? (ref, entry) async => const StatsDashboard(),
    ),
  ];
}

void main() {
  testWidgets('standalone tool pages expose button and system back', (
    tester,
  ) async {
    final router = createAppRouter();
    router.go('/tools');

    await tester.pumpWidget(
      ProviderScope(
        overrides: _toolOverrides(
          bpSchemes: (ref) async {
            return const [
              BpSchemeSummary(
                id: '12',
                name: 'KPL Finals Draft',
                createdAt: '2026-07-03T10:00:00Z',
                boMode: 7,
                teamAName: 'Wolves',
                teamBName: 'AG',
                sideSelectionRule: 'loser_selects',
                gameNumber: 3,
                historyCount: 2,
                currentStepIndex: 4,
                blueBanCount: 1,
                redBanCount: 1,
                bluePickCount: 1,
                redPickCount: 1,
              ),
            ];
          },
        ),
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('BP Simulator'));
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.path,
      '/tools/bp-simulator',
    );
    expect(
      find.byKey(const ValueKey('standalone-back-button')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('standalone-back-button')));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/tools');

    await tester.tap(find.text('BP Simulator'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/tools');
  });

  testWidgets('tools screen renders a 2 by 3 core tools grid', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _emptyToolOverrides(),
        child: MaterialApp.router(routerConfig: _buildRouter()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('tools-nine-grid')), findsOneWidget);
    expect(
      find.byWidgetPredicate((widget) {
        final key = widget.key;
        return key is ValueKey<String> &&
            key.value.startsWith('tool-grid-card-');
      }),
      findsNWidgets(6),
    );
    expect(find.text('BP Simulator'), findsOneWidget);
    expect(find.text('Tier List Tool'), findsOneWidget);
    expect(find.text('Prompts'), findsOneWidget);
    expect(find.text('Team Builder'), findsOneWidget);
    expect(find.text('Build Simulator'), findsOneWidget);
    expect(find.text('Rank Fortune'), findsOneWidget);
    expect(find.text('Game Assistant'), findsNothing);
    expect(find.text('Event Assistance'), findsNothing);
    expect(find.text('Curiosity Lab'), findsNothing);
    expect(find.text('More'), findsNothing);
  });

  testWidgets('tools screen uses copied hokx icon assets', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _emptyToolOverrides(),
        child: MaterialApp.router(routerConfig: _buildRouter()),
      ),
    );
    await tester.pumpAndSettle();

    for (final assetPath in const [
      'assets/tools/bp.png',
      'assets/tools/tier.png',
      'assets/tools/prompt.png',
      'assets/tools/team.png',
      'assets/tools/build.png',
      'assets/tools/fortune.png',
    ]) {
      expect(
        find.byWidgetPredicate((widget) {
          return widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName == assetPath;
        }),
        findsOneWidget,
        reason: assetPath,
      );
    }
  });

  testWidgets('build simulator tile opens the build simulator route', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _emptyToolOverrides(),
        child: MaterialApp.router(routerConfig: _buildRouter()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Build Simulator'), 120);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Build Simulator'));
    await tester.pumpAndSettle();

    expect(find.text('Build Simulator'), findsOneWidget);
    expect(
      find.text('Select a hero to manage the three mobile slots.'),
      findsOneWidget,
    );
  });

  testWidgets('BP simulator tile opens the BP route', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _toolOverrides(
          bpSchemes: (ref) async {
            return const [
              BpSchemeSummary(
                id: '12',
                name: 'KPL Finals Draft',
                createdAt: '2026-07-03T10:00:00Z',
                boMode: 7,
                teamAName: 'Wolves',
                teamBName: 'AG',
                sideSelectionRule: 'loser_selects',
                gameNumber: 3,
                historyCount: 2,
                currentStepIndex: 4,
                blueBanCount: 1,
                redBanCount: 1,
                bluePickCount: 1,
                redPickCount: 1,
              ),
            ];
          },
        ),
        child: MaterialApp.router(routerConfig: _buildRouter()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('BP Simulator'));
    await tester.pumpAndSettle();

    expect(find.text('KPL Finals Draft'), findsOneWidget);
    expect(find.text('Wolves vs AG'), findsOneWidget);
  });

  testWidgets('tier list tile opens the tier list tool route', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _toolOverrides(
          tierListSchemes: (ref) async {
            return const [
              TierListSchemeSummary(
                id: '9',
                name: 'Solo Queue Meta',
                createdAt: '2026-07-01T08:00:00Z',
                updatedAt: '2026-07-03T12:00:00Z',
                rows: [
                  TierListSchemeRowSummary(
                    id: 'r1',
                    label: 'T0',
                    color: 'bg-red-600',
                    heroCount: 2,
                  ),
                ],
              ),
            ];
          },
        ),
        child: MaterialApp.router(routerConfig: _buildRouter()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Tier List Tool'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tier List Tool'));
    await tester.pumpAndSettle();

    expect(find.text('Solo Queue Meta'), findsOneWidget);
    expect(find.text('2 heroes'), findsOneWidget);
  });

  testWidgets('rank fortune tile opens the rank fortune route', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._emptyToolOverrides(),
          rankFortuneHistoryProvider.overrideWith((ref) async {
            return const RankFortuneHistory(
              rows: [],
              today: null,
              canDraw: true,
              days: 30,
              catalog: [],
            );
          }),
        ],
        child: MaterialApp.router(routerConfig: _buildRouter()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Rank Fortune'), 120);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rank Fortune'));
    await tester.pumpAndSettle();

    expect(
      find.text("Draw your fortune for today's ranked matches."),
      findsOneWidget,
    );
    expect(find.text('Fortune Jar'), findsOneWidget);
  });

  testWidgets('team builder tile opens the team builder route', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _toolOverrides(
          teamBuilderHeroes: (ref) async {
            return const [
              TeamBuildHero(
                id: 42,
                externalHeroId: '142',
                name: 'Lam',
                mainJob: 3,
                avatarUrl: '',
              ),
            ];
          },
        ),
        child: MaterialApp.router(routerConfig: _buildRouter()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Team Builder'), 120);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Team Builder'));
    await tester.pumpAndSettle();

    expect(find.text('Team Builder'), findsOneWidget);
    expect(find.text('Lam'), findsOneWidget);
  });

  testWidgets('prompts tile opens the prompts route', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _toolOverrides(
          publicPrompts: (ref) async {
            return const [
              PromptSummary(
                id: '7',
                title: 'Cyber skin concept',
                content: 'Create a neon Honor of Kings skin splash art.',
                tags: ['skin'],
                imageUrl: '',
                authorName: 'artist',
                likeCount: 12,
                favoriteCount: 5,
                isPublic: true,
              ),
            ];
          },
        ),
        child: MaterialApp.router(routerConfig: _buildRouter()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Prompts'), 120);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Prompts'));
    await tester.pumpAndSettle();

    expect(find.text('Prompts'), findsOneWidget);
    expect(find.text('Cyber skin concept'), findsOneWidget);
  });
}
