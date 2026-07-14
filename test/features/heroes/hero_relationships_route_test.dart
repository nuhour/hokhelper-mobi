import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hok_helper_mobile/src/app/hok_helper_app.dart';
import 'package:hok_helper_mobile/src/app/router.dart';
import 'package:hok_helper_mobile/src/features/heroes/presentation/hero_detail_screen.dart';
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
        builder: (context, state) => HeroRelationshipsScreen(
          initialHeroId: state.uri.queryParameters['hero_id'],
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

    await tester.tap(find.byTooltip('Hero Relationships'));
    await tester.pumpAndSettle();

    expect(find.text('Global'), findsOneWidget);
    expect(find.text('Starlight Pact'), findsNothing);
  });

  testWidgets('relationships route keeps the global graph for a hero query', (
    tester,
  ) async {
    final router = _buildRouter();
    router.go('/relationships?hero_id=166');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          heroRelationshipsProvider.overrideWith((ref) async {
            return const [
              HeroRelationship(
                id: '1',
                sourceHeroId: '166',
                sourceHeroName: 'Lam',
                targetHeroId: '202',
                targetHeroName: 'Angela',
                title: 'Starlight Pact',
                weight: 86,
                description: 'They share a story arc.',
              ),
              HeroRelationship(
                id: '2',
                sourceHeroId: '303',
                sourceHeroName: 'Arthur',
                targetHeroId: '404',
                targetHeroName: 'Dolia',
                title: 'River Memory',
                weight: 44,
                description: 'A distant connection.',
              ),
            ];
          }),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/relationships');
    expect(find.text('Global'), findsOneWidget);
    expect(find.text('Starlight Pact'), findsNothing);
    expect(find.text('River Memory'), findsNothing);
  });

  testWidgets('app router relationship query opens unrestricted mobile graph', (
    tester,
  ) async {
    final router = createAppRouter()..go('/relationships?hero_id=166');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          heroRelationshipsProvider.overrideWith((ref) async {
            return const [
              HeroRelationship(
                id: '1',
                sourceHeroId: '166',
                sourceHeroName: 'Lam',
                targetHeroId: '202',
                targetHeroName: 'Angela',
                title: 'Starlight Pact',
                weight: 86,
                description: 'They share a story arc.',
              ),
              HeroRelationship(
                id: '2',
                sourceHeroId: '303',
                sourceHeroName: 'Arthur',
                targetHeroId: '404',
                targetHeroName: 'Dolia',
                title: 'River Memory',
                weight: 44,
                description: 'A distant connection.',
              ),
            ];
          }),
        ],
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/relationships');
    expect(find.text('Global'), findsOneWidget);
    expect(find.text('Starlight Pact'), findsNothing);
    expect(find.text('River Memory'), findsNothing);
  });
}
