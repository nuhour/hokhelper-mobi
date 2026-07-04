import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hok_helper_mobile/src/features/heroes/domain/hero_summary.dart';
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
}
