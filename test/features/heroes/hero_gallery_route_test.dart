import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/app/hok_helper_app.dart';
import 'package:hok_helper_mobile/src/app/router.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
import 'package:hok_helper_mobile/src/features/heroes/data/heroes_repository.dart';
import 'package:hok_helper_mobile/src/features/heroes/domain/hero_summary.dart';
import 'package:hok_helper_mobile/src/features/heroes/presentation/hero_detail_screen.dart';
import 'package:hok_helper_mobile/src/features/heroes/presentation/hero_gallery_screen.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient()
    : super(
        config: const AppConfig(
          apiBaseUrl: 'https://example.test',
          apiPrefix: '',
        ),
      );
}

class _FakeHeroesRepository extends HeroesRepository {
  _FakeHeroesRepository() : super(apiClient: _FakeApiClient());

  String? requestedSearch;

  @override
  Future<List<HeroSummary>> loadHeroes(
    int regionId, {
    int page = 1,
    int pageSize = 60,
    String sort = 'created_at',
    String order = 'desc',
    String search = '',
    int? lanePosition,
    double minRating = 0,
  }) async {
    requestedSearch = search;
    return const [
      HeroSummary(id: '1', name: 'Lam', avatar: '', title: 'Shark Rider'),
      HeroSummary(id: '2', name: 'Angela', avatar: '', title: 'Arcane Mage'),
    ];
  }
}

void main() {
  testWidgets('web hero gallery route preserves search query', (tester) async {
    final router = createAppRouter();
    final repository = _FakeHeroesRepository();
    router.go('/hero-gallery?q=Lam');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          heroesRepositoryProvider.overrideWithValue(repository),
          heroGalleryRegionProvider.overrideWith((ref) async => 2),
        ],
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/heroes');
    expect(
      router.routeInformationProvider.value.uri.queryParameters['q'],
      'Lam',
    );
    expect(find.widgetWithText(TextField, 'Lam'), findsOneWidget);
    expect(find.text('Lam'), findsWidgets);
    expect(find.text('Angela'), findsNothing);
    expect(repository.requestedSearch, 'Lam');
  });

  testWidgets('hero cards preserve list query when opening detail route', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = createAppRouter();
    final repository = _FakeHeroesRepository();
    router.go('/hero-gallery?q=Lam');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          heroesRepositoryProvider.overrideWithValue(repository),
          heroGalleryRegionProvider.overrideWith((ref) async => 2),
          selectedRegionHeroDetailProvider.overrideWith((ref, heroId) async {
            return {
              'hero': {'id': int.tryParse(heroId) ?? 1, 'name': 'Lam'},
            };
          }),
        ],
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    final heroCard = find.byKey(const ValueKey('hero-card-1'));
    await tester.ensureVisible(heroCard);
    await tester.tap(heroCard);
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/heroes/1');
    expect(
      router.routeInformationProvider.value.uri.queryParameters['q'],
      'Lam',
    );
  });

  testWidgets('web hero history tab deep link focuses mobile history', (
    tester,
  ) async {
    final router = createAppRouter();
    router.go('/hero-gallery/166?tab=history');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedRegionHeroDetailProvider.overrideWith((ref, heroId) async {
            return {
              'hero': {'id': 166, 'name': 'Lam', 'title': 'Shark Rider'},
              'history': [
                {
                  'version': '1.2.3',
                  'date': '2026-07-01',
                  'type': 'buff',
                  'title': 'Jungle tuning',
                  'content': 'Improved early clear speed.',
                },
              ],
            };
          }),
        ],
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/heroes/166');
    expect(find.text('Patch history focus'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Jungle tuning'),
      320,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Jungle tuning'), findsOneWidget);
  });

  testWidgets('legacy hero id query preserves history tab on detail route', (
    tester,
  ) async {
    final router = createAppRouter();
    router.go('/hero-gallery?hero_id=166&tab=history');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedRegionHeroDetailProvider.overrideWith((ref, heroId) async {
            return {
              'hero': {'id': 166, 'name': 'Lam', 'title': 'Shark Rider'},
              'history': [
                {
                  'version': '1.2.3',
                  'date': '2026-07-01',
                  'type': 'buff',
                  'title': 'Jungle tuning',
                  'content': 'Improved early clear speed.',
                },
              ],
            };
          }),
        ],
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    final uri = router.routeInformationProvider.value.uri;
    expect(uri.path, '/heroes/166');
    expect(uri.queryParameters['tab'], 'history');
    expect(find.text('Patch history focus'), findsOneWidget);
  });

  testWidgets('web hero lore tab deep link focuses mobile lore', (
    tester,
  ) async {
    final router = createAppRouter();
    router.go('/hero-gallery/166?tab=lore');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedRegionHeroDetailProvider.overrideWith((ref, heroId) async {
            return {
              'hero': {
                'id': 166,
                'name': 'Lam',
                'title': 'Shark Rider',
                'lore': 'Lam rides the waves between battlefields.',
              },
            };
          }),
        ],
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/heroes/166');
    expect(find.text('Lore focus'), findsOneWidget);
    expect(
      find.text('Lam rides the waves between battlefields.'),
      findsOneWidget,
    );
  });

  testWidgets('legacy hero id query preserves lore tab on detail route', (
    tester,
  ) async {
    final router = createAppRouter();
    router.go('/hero-gallery?hero_id=166&tab=lore');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedRegionHeroDetailProvider.overrideWith((ref, heroId) async {
            return {
              'hero': {
                'id': 166,
                'name': 'Lam',
                'title': 'Shark Rider',
                'lore': 'Lam rides the waves between battlefields.',
              },
            };
          }),
        ],
        child: HokHelperApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    final uri = router.routeInformationProvider.value.uri;
    expect(uri.path, '/heroes/166');
    expect(uri.queryParameters['tab'], 'lore');
    expect(find.text('Lore focus'), findsOneWidget);
  });
}
