import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hok_helper_mobile/src/app/hok_helper_app.dart';
import 'package:hok_helper_mobile/src/app/router.dart';
import 'package:hok_helper_mobile/src/features/rankings/domain/player_leaderboard_result.dart';
import 'package:hok_helper_mobile/src/features/rankings/presentation/player_leaderboard_screen.dart';
import 'package:hok_helper_mobile/src/features/rankings/presentation/tools_screen.dart';

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/tools',
    routes: [
      GoRoute(
        path: '/tools',
        builder: (context, state) => const ToolsScreen(),
        routes: [
          GoRoute(
            path: 'leaderboard',
            builder: (context, state) => const PlayerLeaderboardScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/leaderboard',
        builder: (context, state) => const PlayerLeaderboardScreen(),
      ),
    ],
  );
}

void main() {
  testWidgets('tools screen opens standalone player leaderboard', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerLeaderboardProvider.overrideWith((ref) async {
            return const PlayerLeaderboardResult(
              players: [],
              total: 0,
              regionId: 0,
              rankType: 'rank',
              regionOptions: [],
            );
          }),
        ],
        child: MaterialApp.router(routerConfig: _buildRouter()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Player Leaderboard'));
    await tester.pumpAndSettle();

    expect(find.text('Player Leaderboard'), findsOneWidget);
    expect(find.text('No players found'), findsOneWidget);
  });

  testWidgets('web leaderboard route preserves rank type and region query', (
    tester,
  ) async {
    final router = createAppRouter();
    router.go('/leaderboard?rank_type=peak&region_id=44');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerLeaderboardProvider.overrideWith((ref) async {
            return const PlayerLeaderboardResult(
              players: [],
              total: 0,
              regionId: 44,
              rankType: 'peak',
              regionOptions: [44, 62],
            );
          }),
        ],
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/leaderboard');
    expect(
      router.routeInformationProvider.value.uri.queryParameters['rank_type'],
      'peak',
    );
    expect(
      router.routeInformationProvider.value.uri.queryParameters['region_id'],
      '44',
    );
    expect(find.text('Peak'), findsAtLeastNWidgets(1));
    expect(find.text('Region +44'), findsAtLeastNWidgets(1));
  });

  testWidgets('leaderboard controls synchronize web route query', (
    tester,
  ) async {
    final router = createAppRouter();
    router.go('/leaderboard');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerLeaderboardProvider.overrideWith((ref) async {
            return const PlayerLeaderboardResult(
              players: [],
              total: 0,
              regionId: 0,
              rankType: 'rank',
              regionOptions: [44, 62],
            );
          }),
        ],
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Peak'));
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.queryParameters['rank_type'],
      'peak',
    );

    await tester.tap(find.text('Global').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Region +62').last);
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.queryParameters['region_id'],
      '62',
    );
    expect(
      router.routeInformationProvider.value.uri.queryParameters['rank_type'],
      'peak',
    );

    await tester.tap(find.text('Ranked'));
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.queryParameters.containsKey(
        'rank_type',
      ),
      isFalse,
    );
    expect(
      router.routeInformationProvider.value.uri.queryParameters['region_id'],
      '62',
    );
  });
}
