import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hok_helper_mobile/src/features/builds/presentation/build_explorer_screen.dart';
import 'package:hok_helper_mobile/src/features/prompts/domain/prompt_summary.dart';
import 'package:hok_helper_mobile/src/features/prompts/presentation/prompts_screen.dart';
import 'package:hok_helper_mobile/src/features/rankings/domain/hero_ranking_entry.dart';
import 'package:hok_helper_mobile/src/features/rankings/presentation/hero_ranking_screen.dart';
import 'package:hok_helper_mobile/src/features/rankings/presentation/tools_screen.dart';
import 'package:hok_helper_mobile/src/features/teambuild/domain/team_build_hero.dart';
import 'package:hok_helper_mobile/src/features/teambuild/domain/team_recommendation.dart';
import 'package:hok_helper_mobile/src/features/teambuild/presentation/team_builder_screen.dart';

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
        ],
      ),
    ],
  );
}

void main() {
  testWidgets('build explorer tile opens the build explorer route', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          publicBuildSchemesProvider.overrideWith((ref) async => const []),
          heroRankingProvider.overrideWith((ref) async => const []),
          playerRankingProvider.overrideWith((ref) async => const []),
          equipRankingProvider.overrideWith((ref) async => const []),
          tierRankingProvider.overrideWith((ref) async => const []),
          teamBuilderHeroesProvider.overrideWith((ref) async => const []),
          teamRecommendationsProvider.overrideWith(
            (ref) async => const TeamRecommendationResult(recommendations: []),
          ),
          publicPromptsProvider.overrideWith((ref) async => const []),
        ],
        child: MaterialApp.router(routerConfig: _buildRouter()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Build Explorer'));
    await tester.pumpAndSettle();

    expect(find.text('Build Explorer'), findsOneWidget);
    expect(find.text('No public builds'), findsOneWidget);
  });

  testWidgets('rankings tile opens the hero rankings route', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          publicBuildSchemesProvider.overrideWith((ref) async => const []),
          playerRankingProvider.overrideWith((ref) async => const []),
          equipRankingProvider.overrideWith((ref) async => const []),
          tierRankingProvider.overrideWith((ref) async => const []),
          teamBuilderHeroesProvider.overrideWith((ref) async => const []),
          teamRecommendationsProvider.overrideWith(
            (ref) async => const TeamRecommendationResult(recommendations: []),
          ),
          publicPromptsProvider.overrideWith((ref) async => const []),
          heroRankingProvider.overrideWith((ref) async {
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
          }),
        ],
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
        overrides: [
          publicBuildSchemesProvider.overrideWith((ref) async => const []),
          heroRankingProvider.overrideWith((ref) async => const []),
          playerRankingProvider.overrideWith((ref) async => const []),
          equipRankingProvider.overrideWith((ref) async => const []),
          tierRankingProvider.overrideWith((ref) async => const []),
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
          teamRecommendationsProvider.overrideWith(
            (ref) async => const TeamRecommendationResult(recommendations: []),
          ),
          publicPromptsProvider.overrideWith((ref) async => const []),
        ],
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
        overrides: [
          publicBuildSchemesProvider.overrideWith((ref) async => const []),
          heroRankingProvider.overrideWith((ref) async => const []),
          playerRankingProvider.overrideWith((ref) async => const []),
          equipRankingProvider.overrideWith((ref) async => const []),
          tierRankingProvider.overrideWith((ref) async => const []),
          teamBuilderHeroesProvider.overrideWith((ref) async => const []),
          teamRecommendationsProvider.overrideWith(
            (ref) async => const TeamRecommendationResult(recommendations: []),
          ),
          publicPromptsProvider.overrideWith((ref) async {
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
          }),
        ],
        child: MaterialApp.router(routerConfig: _buildRouter()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Prompts'));
    await tester.pumpAndSettle();

    expect(find.text('Prompts'), findsOneWidget);
    expect(find.text('Cyber skin concept'), findsOneWidget);
  });
}
