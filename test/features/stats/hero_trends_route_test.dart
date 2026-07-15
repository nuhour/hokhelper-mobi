import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hok_helper_mobile/src/app/hok_helper_app.dart';
import 'package:hok_helper_mobile/src/app/router.dart';
import 'package:hok_helper_mobile/src/features/heroes/domain/hero_summary.dart';
import 'package:hok_helper_mobile/src/features/heroes/presentation/hero_gallery_screen.dart';
import 'package:hok_helper_mobile/src/features/stats/presentation/hero_trends_screen.dart';

import 'stats_trends_fixture.dart';

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
          heroTrendTableProvider.overrideWith(
            (ref, query) async => sampleStatsTrendTable(),
          ),
        ],
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    final uri = router.routeInformationProvider.value.uri;
    expect(uri.path, '/trends');
    expect(uri.queryParameters['hero_id'], '166');
    final yaria = find.byKey(const ValueKey('trend-row-hero-166'));
    final lam = find.byKey(const ValueKey('trend-row-hero-199'));
    expect(yaria, findsOneWidget);
    expect(tester.getTopLeft(yaria).dy, lessThan(tester.getTopLeft(lam).dy));
  });

  testWidgets('hero gallery omits the removed trends shortcut', (tester) async {
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
        ],
        child: MaterialApp.router(routerConfig: _buildRouter()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hero Trends'), findsNothing);
    expect(find.text('Lam'), findsOneWidget);
  });

  testWidgets('trend row opens an in-app stats panel and keeps route', (
    tester,
  ) async {
    final router = _buildRouter();
    router.go('/trends');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          heroGalleryProvider.overrideWith((ref) async => const []),
          heroTrendTableProvider.overrideWith(
            (ref, query) async => sampleStatsTrendTable(),
          ),
          heroTrendDetailProvider.overrideWith(
            (ref, request) async => sampleStatsTrendDetail(),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('trend-row-hero-199')));
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/trends');
    expect(find.text('Core trend'), findsOneWidget);
  });
}
