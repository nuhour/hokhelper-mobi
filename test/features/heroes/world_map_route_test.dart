import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hok_helper_mobile/src/features/heroes/domain/hero_summary.dart';
import 'package:hok_helper_mobile/src/features/heroes/presentation/hero_detail_screen.dart';
import 'package:hok_helper_mobile/src/features/heroes/presentation/hero_gallery_screen.dart';
import 'package:hok_helper_mobile/src/features/heroes/presentation/world_map_screen.dart';

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/heroes',
    routes: [
      GoRoute(
        path: '/heroes',
        builder: (context, state) => const HeroGalleryScreen(),
      ),
      GoRoute(
        path: '/world-map',
        builder: (context, state) => const WorldMapScreen(),
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
  testWidgets('hero gallery opens world map route', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          heroGalleryProvider.overrideWith((ref) async {
            return const [
              HeroSummary(
                id: '1',
                heroId: '166',
                name: 'Yaria',
                avatar: '',
                title: 'Forest Child',
              ),
            ];
          }),
          worldMapHeroesProvider.overrideWith((ref) async {
            return const [
              HeroSummary(
                id: '1',
                heroId: '166',
                name: 'Yaria',
                avatar: '',
                title: 'Forest Child',
              ),
            ];
          }),
        ],
        child: MaterialApp.router(routerConfig: _buildRouter()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('World Map'));
    await tester.pumpAndSettle();

    expect(find.text('World Map'), findsOneWidget);
    expect(find.text('Sunset Sea'), findsOneWidget);
  });

  testWidgets('world map representative hero rows open hero detail routes', (
    tester,
  ) async {
    final router = _buildRouter();
    router.go('/world-map');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          worldMapHeroesProvider.overrideWith((ref) async {
            return const [
              HeroSummary(
                id: '1',
                heroId: '166',
                name: 'Yaria',
                avatar: '',
                title: 'Forest Child',
              ),
            ];
          }),
          selectedRegionHeroDetailProvider.overrideWith((ref, heroId) async {
            return {
              'hero': {'id': int.tryParse(heroId) ?? 1, 'name': 'Yaria'},
            };
          }),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sunset Sea'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Forest Child'));
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/heroes/1');
    expect(find.text('Hero #1'), findsOneWidget);
  });
}
