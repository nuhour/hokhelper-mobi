import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hok_helper_mobile/src/features/heroes/domain/hero_summary.dart';
import 'package:hok_helper_mobile/src/features/heroes/presentation/hero_gallery_screen.dart';
import 'package:hok_helper_mobile/src/features/stats/domain/hero_trend_row.dart';
import 'package:hok_helper_mobile/src/features/stats/presentation/hero_trends_screen.dart';

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/heroes',
    routes: [
      GoRoute(
        path: '/heroes',
        builder: (context, state) => const HeroGalleryScreen(),
      ),
      GoRoute(
        path: '/trends',
        builder: (context, state) => const HeroTrendsScreen(),
      ),
    ],
  );
}

void main() {
  testWidgets('hero gallery opens hero trends route', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          heroGalleryProvider.overrideWith((ref) async {
            return const [
              HeroSummary(
                id: '1',
                heroId: '199',
                name: 'Lam',
                avatar: '',
                title: 'Shark Blade',
              ),
            ];
          }),
          heroTrendsProvider.overrideWith((ref) async {
            return const [
              HeroTrendRow(
                id: 199,
                name: 'Lam',
                avatarUrl: '',
                winRate: 56.1,
                mvpScore: 13.8,
                mvpRate: 22.5,
                dmgShare: 31.4,
                takeDmgShare: 28.7,
                ecoShare: 24.1,
              ),
            ];
          }),
        ],
        child: MaterialApp.router(routerConfig: _buildRouter()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hero Trends'));
    await tester.pumpAndSettle();

    expect(find.text('Hero Trends'), findsOneWidget);
    expect(find.text('Lam'), findsOneWidget);
  });
}
