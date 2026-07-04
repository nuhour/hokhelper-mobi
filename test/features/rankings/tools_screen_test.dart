import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hok_helper_mobile/src/features/bp/domain/bp_scheme_summary.dart';
import 'package:hok_helper_mobile/src/features/bp/presentation/bp_dashboard_screen.dart';
import 'package:hok_helper_mobile/src/features/builds/presentation/build_explorer_screen.dart';
import 'package:hok_helper_mobile/src/features/esports/domain/esports_match_summary.dart';
import 'package:hok_helper_mobile/src/features/esports/domain/esports_player_summary.dart';
import 'package:hok_helper_mobile/src/features/esports/domain/esports_team_summary.dart';
import 'package:hok_helper_mobile/src/features/esports/presentation/esports_screen.dart';
import 'package:hok_helper_mobile/src/features/game_assistant/presentation/game_assistant_screen.dart';
import 'package:hok_helper_mobile/src/features/prompts/domain/prompt_summary.dart';
import 'package:hok_helper_mobile/src/features/prompts/presentation/prompts_screen.dart';
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
            builder: (context, state) => const BuildExplorerScreen(),
          ),
          GoRoute(
            path: 'bp-simulator',
            builder: (context, state) => const BpDashboardScreen(),
          ),
          GoRoute(
            path: 'tier-list',
            builder: (context, state) => const TierListToolScreen(),
          ),
          GoRoute(
            path: 'game-assistant',
            builder: (context, state) => const GameAssistantScreen(),
          ),
          GoRoute(
            path: 'rankings',
            builder: (context, state) => const HeroRankingScreen(),
          ),
          GoRoute(
            path: 'team-builder',
            builder: (context, state) => const TeamBuilderScreen(),
          ),
          GoRoute(
            path: 'prompts',
            builder: (context, state) => const PromptsScreen(),
          ),
          GoRoute(
            path: 'esports',
            builder: (context, state) => const EsportsScreen(),
          ),
          GoRoute(
            path: 'stats',
            builder: (context, state) => const StatsScreen(),
          ),
        ],
      ),
    ],
  );
}

List<Override> _emptyToolOverrides() {
  return [
    publicBuildSchemesProvider.overrideWith((ref) async => const []),
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
    publicPromptsProvider.overrideWith((ref) async => const []),
    esportsMatchesProvider.overrideWith((ref) async => const []),
    esportsTeamsProvider.overrideWith((ref) async => const []),
    esportsPlayersProvider.overrideWith((ref) async => const []),
    statsDashboardProvider.overrideWith((ref) async => const StatsDashboard()),
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
  Future<StatsDashboard> Function(Ref)? statsDashboard,
}) {
  return [
    publicBuildSchemesProvider.overrideWith((ref) async => const []),
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
    publicPromptsProvider.overrideWith(
      publicPrompts ?? (ref) async => const [],
    ),
    esportsMatchesProvider.overrideWith(
      esportsMatches ?? (ref) async => const [],
    ),
    esportsTeamsProvider.overrideWith(esportsTeams ?? (ref) async => const []),
    esportsPlayersProvider.overrideWith(
      esportsPlayers ?? (ref) async => const [],
    ),
    statsDashboardProvider.overrideWith(
      statsDashboard ?? (ref) async => const StatsDashboard(),
    ),
  ];
}

void main() {
  testWidgets('build explorer tile opens the build explorer route', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _emptyToolOverrides(),
        child: MaterialApp.router(routerConfig: _buildRouter()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Build Explorer'));
    await tester.pumpAndSettle();

    expect(find.text('Build Explorer'), findsOneWidget);
    expect(find.text('No public builds'), findsOneWidget);
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

  testWidgets('game assistant tile opens the game assistant route', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _emptyToolOverrides(),
        child: MaterialApp.router(routerConfig: _buildRouter()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Game Assistant'), 120);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Game Assistant'));
    await tester.pumpAndSettle();

    expect(find.text('Mobile Companion App'), findsOneWidget);
    expect(find.text('Jungle timers'), findsOneWidget);
  });

  testWidgets('rankings tile opens the hero rankings route', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _toolOverrides(
          heroRanking: (ref) async {
            return const [
              HeroRankingEntry(
                heroId: 42,
                externalHeroId: '199',
                name: 'Lam',
                mainJob: 'Assassin',
                winRate: 0.54,
                pickRate: 0.12,
                banRate: 0.03,
                mvpRate: 0.2,
                avgKills: 8,
                avgAssists: 5,
                avgGrade: 13,
              ),
            ];
          },
        ),
        child: MaterialApp.router(routerConfig: _buildRouter()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rankings'));
    await tester.pumpAndSettle();

    expect(find.text('Hero Rankings'), findsOneWidget);
    expect(find.text('Lam'), findsOneWidget);
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

  testWidgets('esports tile opens the esports route', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _toolOverrides(
          esportsMatches: (ref) async {
            return const [
              EsportsMatchSummary(
                id: '10',
                leagueName: 'KPL Spring',
                stageName: 'Playoffs',
                teamAName: 'Wolves',
                teamALogoUrl: '',
                teamBName: 'AG',
                teamBLogoUrl: '',
                scoreA: 4,
                scoreB: 3,
                statusKey: 'finished',
                startTime: '2026-06-28T11:00:00Z',
              ),
            ];
          },
          esportsTeams: (ref) async {
            return const [
              EsportsTeamSummary(
                id: '1',
                name: 'Wolves',
                shortName: 'WOL',
                logoUrl: '',
                leagueName: 'KPL Spring',
                club: 'Chongqing Wolves',
                wins: 12,
                losses: 3,
                winRate: 0.8,
              ),
            ];
          },
          esportsPlayers: (ref) async {
            return const [
              EsportsPlayerSummary(
                id: '8',
                name: 'Fly',
                avatarUrl: '',
                teamName: 'Wolves',
                teamLogoUrl: '',
                role: 'Clash Lane',
                grade: 91.5,
                kda: 6.8,
                winRate: 0.76,
              ),
            ];
          },
        ),
        child: MaterialApp.router(routerConfig: _buildRouter()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Esports'), 120);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Esports'));
    await tester.pumpAndSettle();

    expect(find.text('Esports'), findsOneWidget);
    expect(find.text('KPL Spring'), findsOneWidget);
    expect(find.text('4 - 3'), findsOneWidget);
  });

  testWidgets('stats tile opens the stats route', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _toolOverrides(
          statsDashboard: (ref) async {
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
          },
        ),
        child: MaterialApp.router(routerConfig: _buildRouter()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Stats'), 120);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();

    expect(find.text('Stats Dashboard'), findsOneWidget);
    expect(find.text('Lam'), findsOneWidget);
    expect(find.text('56.1% WR'), findsOneWidget);
  });
}
