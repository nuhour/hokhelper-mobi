import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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
}
