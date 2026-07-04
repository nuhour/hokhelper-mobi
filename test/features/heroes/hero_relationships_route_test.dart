import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hok_helper_mobile/src/features/heroes/domain/hero_relationship.dart';
import 'package:hok_helper_mobile/src/features/heroes/domain/hero_summary.dart';
import 'package:hok_helper_mobile/src/features/heroes/presentation/hero_gallery_screen.dart';
import 'package:hok_helper_mobile/src/features/heroes/presentation/hero_relationships_screen.dart';

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/heroes',
    routes: [
      GoRoute(
        path: '/heroes',
        builder: (context, state) => const HeroGalleryScreen(),
      ),
      GoRoute(
        path: '/relationships',
        builder: (context, state) => const HeroRelationshipsScreen(),
      ),
    ],
  );
}

void main() {
  testWidgets('hero gallery opens relationships route', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          heroGalleryProvider.overrideWith((ref) async {
            return const [
              HeroSummary(
                id: '101',
                name: 'Lam',
                avatar: '',
                title: 'Radiant Blade',
              ),
            ];
          }),
          heroRelationshipsProvider.overrideWith((ref) async {
            return const [
              HeroRelationship(
                id: '1',
                sourceHeroId: '101',
                sourceHeroName: 'Lam',
                targetHeroId: '202',
                targetHeroName: 'Angela',
                title: 'Starlight Pact',
                weight: 86,
                description: 'They share a story arc.',
              ),
            ];
          }),
        ],
        child: MaterialApp.router(routerConfig: _buildRouter()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hero Relationships'));
    await tester.pumpAndSettle();

    expect(find.text('Hero Relationships'), findsOneWidget);
    expect(find.text('Starlight Pact'), findsOneWidget);
  });
}
