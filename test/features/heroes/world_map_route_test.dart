import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hok_helper_mobile/src/app/hok_helper_app.dart';
import 'package:hok_helper_mobile/src/app/router.dart';
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
        builder: (context, state) =>
            WorldMapScreen(initialHeroId: state.uri.queryParameters['hero_id']),
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
    final router = _buildRouter();
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
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('World Map'));
    await tester.pump();
    await tester.pump();

    expect(find.byTooltip('Exit world map'), findsOneWidget);
    expect(find.text('Sunset Sea'), findsOneWidget);

    await tester.tap(find.byTooltip('Exit world map'));
    await tester.pump();

    expect(router.routeInformationProvider.value.uri.path, '/heroes');
    expect(find.byTooltip('World Map'), findsOneWidget);
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
    await tester.pump();
    await tester.pump();

    await tester.drag(
      find.byType(InteractiveViewer).first,
      const Offset(260, 0),
    );
    await tester.pump();
    await tester.tap(find.text('Sunset Sea'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Forest Child'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(router.routeInformationProvider.value.uri.path, '/heroes/1');
    expect(find.byType(HeroDetailScreen), findsOneWidget);
  });

  testWidgets('app router world map query opens focused region detail', (
    tester,
  ) async {
    final router = createAppRouter()..go('/world-map?hero_id=199');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          worldMapHeroesProvider.overrideWith((ref) async {
            return const [
              HeroSummary(
                id: '2',
                heroId: '199',
                name: 'Lam',
                avatar: '',
                title: 'Shark Blade',
              ),
            ];
          }),
        ],
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(router.routeInformationProvider.value.uri.path, '/world-map');
    expect(find.text('Domain Records'), findsOneWidget);
    expect(find.text('Great River Basin'), findsWidgets);
    expect(find.text('Lam'), findsOneWidget);
  });
}
