import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hok_helper_mobile/src/app/hok_helper_app.dart';
import 'package:hok_helper_mobile/src/app/router.dart';
import 'package:hok_helper_mobile/src/features/heroes/domain/hero_summary.dart';
import 'package:hok_helper_mobile/src/features/heroes/presentation/hero_detail_screen.dart';
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
        builder: (context, state) => HeroTrendsScreen(
          initialHeroId: int.tryParse(
            state.uri.queryParameters['hero_id'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/heroes/:heroId',
        builder: (context, state) =>
            HeroDetailScreen(heroId: state.pathParameters['heroId']!),
      ),
    ],
  );
}

void main() {
  testWidgets('legacy stats hero trend route preserves focused hero id', (
    tester,
  ) async {
    final router = createAppRouter();
    router.go('/stats?entry=hero_trend&hero_id=166');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          heroGalleryProvider.overrideWith((ref) async => const []),
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
              HeroTrendRow(
                id: 166,
                name: 'Yaria',
                avatarUrl: '',
                winRate: 60.2,
                mvpScore: 9.2,
                mvpRate: 11.4,
                dmgShare: 12.1,
                takeDmgShare: 18.2,
                ecoShare: 17.7,
              ),
            ];
          }),
        ],
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    final uri = router.routeInformationProvider.value.uri;
    expect(uri.path, '/trends');
    expect(uri.queryParameters['hero_id'], '166');
    expect(find.text('Focused hero'), findsOneWidget);
    final yariaTopLeft = tester.getTopLeft(find.text('Yaria'));
    final lamTopLeft = tester.getTopLeft(find.text('Lam'));
    expect(yariaTopLeft.dy, lessThan(lamTopLeft.dy));
  });

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

  testWidgets('web trend hero query opens with a focused hero', (tester) async {
    final router = _buildRouter();
    router.go('/trends?hero_id=166');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          heroGalleryProvider.overrideWith((ref) async => const []),
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
              HeroTrendRow(
                id: 166,
                name: 'Yaria',
                avatarUrl: '',
                winRate: 60.2,
                mvpScore: 9.2,
                mvpRate: 11.4,
                dmgShare: 12.1,
                takeDmgShare: 18.2,
                ecoShare: 17.7,
              ),
            ];
          }),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Focused hero'), findsOneWidget);
    final yariaTopLeft = tester.getTopLeft(find.text('Yaria'));
    final lamTopLeft = tester.getTopLeft(find.text('Lam'));
    expect(yariaTopLeft.dy, lessThan(lamTopLeft.dy));
  });

  testWidgets('hero trend cards open hero detail routes', (tester) async {
    final router = _buildRouter();
    router.go('/trends');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          heroGalleryProvider.overrideWith((ref) async => const []),
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
          selectedRegionHeroDetailProvider.overrideWith((ref, heroId) async {
            return {
              'hero': {'id': int.tryParse(heroId) ?? 199, 'name': 'Lam'},
            };
          }),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lam'));
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/heroes/199');
    expect(find.text('Hero #199'), findsOneWidget);
  });
}
