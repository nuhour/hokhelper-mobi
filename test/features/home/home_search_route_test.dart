import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hok_helper_mobile/src/app/hok_helper_app.dart';
import 'package:hok_helper_mobile/src/app/router.dart';
import 'package:hok_helper_mobile/src/features/home/data/home_repository.dart';
import 'package:hok_helper_mobile/src/features/home/presentation/home_screen.dart';

void main() {
  testWidgets('home screen opens global search in a sheet', (tester) async {
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

    await tester.tap(find.byIcon(Icons.search_rounded));
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/');
    expect(find.text('Global Search'), findsOneWidget);
    expect(find.text('Search the portal'), findsOneWidget);

    await tester.tap(find.byTooltip('Close search'));
    await tester.pumpAndSettle();
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

    await tester.tap(find.text('Core Stats'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(router.routeInformationProvider.value.uri.path, '/stats-home');
    expect(router.routeInformationProvider.value.uri.query, isEmpty);

    router.go('/');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Tier List'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(router.routeInformationProvider.value.uri.path, '/stats-home');
    expect(
      router.routeInformationProvider.value.uri.queryParameters['tab'],
      'tier',
    );
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
          path: '/stats-home',
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
          path: '/content/community/post/:postId',
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
                  {
                    'id': 99,
                    'title': 'Draft talk',
                    'content_preview': 'Open discussion',
                  },
                ],
                'patch_notes': [
                  {
                    'id': 31,
                    'post_id': 100,
                    'title': 'Patch 1.2',
                    'content_preview': 'Balance update',
                  },
                ],
              },
            );
          }),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Hero Rankings'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'View More').first);
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/stats-home');
    expect(router.routeInformationProvider.value.uri.query, isEmpty);

    router.go('/');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Tier List Preview'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'View More').at(1));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/stats-home');
    expect(
      router.routeInformationProvider.value.uri.queryParameters['tab'],
      'tier',
    );

    router.go('/');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Leaderboard'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'View More').at(2));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/leaderboard');

    router.go('/');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Community Hot'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'View More').at(3));
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      '/content/community',
    );

    router.go('/');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Latest Updates'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'View More').at(4));
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      '/content/patch-notes',
    );
  });

  testWidgets('home preview rows open community detail routes', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/content/community',
          builder: (context, state) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: '/content/community/post/:postId',
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
                'community_hot': [
                  {
                    'id': 99,
                    'title': 'Draft talk',
                    'content_preview': 'Open discussion',
                  },
                ],
                'patch_notes': [
                  {
                    'id': 31,
                    'post_id': 100,
                    'title': 'Patch 1.2',
                    'content_preview': 'Balance update',
                  },
                ],
              },
            );
          }),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Draft talk'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Draft talk').hitTestable());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      router.routeInformationProvider.value.uri.path,
      '/content/community/post/99',
    );

    router.go('/');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Patch 1.2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Patch 1.2').hitTestable());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      router.routeInformationProvider.value.uri.path,
      '/content/community/post/100',
    );
  });
}
