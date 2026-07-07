import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hok_helper_mobile/src/app/hok_helper_app.dart';
import 'package:hok_helper_mobile/src/app/router.dart';
import 'package:hok_helper_mobile/src/features/home/data/home_repository.dart';
import 'package:hok_helper_mobile/src/features/home/presentation/home_screen.dart';

void main() {
  testWidgets('home screen opens global search route', (tester) async {
    final router = createAppRouter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeStatsProvider.overrideWith((ref) async {
            return const HomeStats(
              success: true,
              message: 'Backend connected',
              result: {'heroes': 128},
            );
          }),
        ],
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Global Search'));
    await tester.pumpAndSettle();

    expect(find.text('Search the portal'), findsOneWidget);
  });

  testWidgets('home screen opens core stats and tier list portal routes', (
    tester,
  ) async {
    final router = createAppRouter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeStatsProvider.overrideWith((ref) async {
            return const HomeStats(
              success: true,
              message: 'Backend connected',
              result: {'heroes': 128},
            );
          }),
        ],
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('View Core Stats'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(router.routeInformationProvider.value.uri.path, '/tools/stats');
    expect(
      router.routeInformationProvider.value.uri.queryParameters['entry'],
      'home_core',
    );

    router.go('/');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Enter Tier List'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(router.routeInformationProvider.value.uri.path, '/tier-list');
  });

  testWidgets('home preview sections open matching portal routes', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/tools/stats',
          builder: (context, state) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: '/tier-list',
          builder: (context, state) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: '/leaderboard',
          builder: (context, state) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: '/content/community',
          builder: (context, state) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: '/content/patch-notes',
          builder: (context, state) => const SizedBox.shrink(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeStatsProvider.overrideWith((ref) async {
            return const HomeStats(
              success: true,
              message: 'Backend connected',
              result: {
                'hero_ranking_table': {
                  'rows': [
                    {
                      'hero': {'name': 'Angela'},
                      'win_rate': 0.55,
                    },
                  ],
                },
                'tier_list': [
                  {
                    'tier': 'S',
                    'heroes': [
                      {'name': 'Dolia'},
                    ],
                  },
                ],
                'player_ranking': {
                  'peak': [
                    {'player_name': 'Top Player', 'peak_score': 2310},
                  ],
                },
                'community_hot': [
                  {'title': 'Draft talk', 'content_preview': 'Open discussion'},
                ],
                'patch_notes': [
                  {'title': 'Patch 1.2', 'content_preview': 'Balance update'},
                ],
              },
            );
          }),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hero Rankings'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/tools/stats');
    expect(
      router.routeInformationProvider.value.uri.queryParameters['entry'],
      'home_core',
    );

    router.go('/');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tier List Preview'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/tier-list');

    router.go('/');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leaderboard'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/leaderboard');

    router.go('/');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Community Hot'));
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      '/content/community',
    );

    router.go('/');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Latest Updates'));
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      '/content/patch-notes',
    );
  });
}
