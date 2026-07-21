import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
import 'package:hok_helper_mobile/src/features/heroes/data/heroes_repository.dart';
import 'package:hok_helper_mobile/src/features/heroes/domain/hero_summary.dart';
import 'package:hok_helper_mobile/src/features/heroes/presentation/hero_gallery_screen.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient({this.postResponse = const {}, this.getResponse = const {}})
    : super(
        config: const AppConfig(
          apiBaseUrl: 'https://example.test',
          apiPrefix: '',
        ),
      );

  final Map<String, dynamic> postResponse;
  final Map<String, dynamic> getResponse;
  String? postPath;
  Object? postBody;
  String? getPath;
  Map<String, dynamic>? getQuery;

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    postPath = path;
    postBody = body;
    return postResponse;
  }

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    getPath = path;
    getQuery = query;
    return getResponse;
  }
}

class _FakeHeroesRepository extends HeroesRepository {
  _FakeHeroesRepository({
    this.heroes = const [
      HeroSummary(id: '1', name: 'Lam', avatar: '', title: 'Shark Rider'),
    ],
  }) : super(
         apiClient: _FakeApiClient(
           postResponse: {
             'result': {'data': <Map<String, Object>>[]},
           },
         ),
       );

  String? requestedSearch;
  String? requestedSort;
  String? requestedOrder;
  int? requestedLanePosition;
  double requestedMinRating = 0;
  final List<HeroSummary> heroes;

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
    requestedSort = sort;
    requestedOrder = order;
    requestedLanePosition = lanePosition;
    requestedMinRating = minRating;
    return heroes;
  }
}

void main() {
  group('HeroSummary', () {
    test('parses alternate backend field names', () {
      final byCamelCase = HeroSummary.fromJson({
        'heroId': 111,
        'heroName': 'Dolia',
        'icon': 'https://example.test/dolia.png',
        'heroTitle': 'Mermaid Song',
        'tier': 'T1',
        'rating': '4.5',
        'rating_count': 19,
      });
      final bySnakeCase = HeroSummary.fromJson({
        'hero_id': '222',
        'hero_name': 'Augran',
        'image': 'https://example.test/augran.png',
        'title': 'Seer',
      });

      expect(byCamelCase.id, '111');
      expect(byCamelCase.name, 'Dolia');
      expect(byCamelCase.avatar, 'https://example.test/dolia.png');
      expect(byCamelCase.title, 'Mermaid Song');
      expect(byCamelCase.tier, 'T1');
      expect(byCamelCase.rating, 4.5);
      expect(byCamelCase.ratingCount, 19);
      expect(bySnakeCase.id, '222');
      expect(bySnakeCase.name, 'Augran');
      expect(bySnakeCase.avatar, 'https://example.test/augran.png');
      expect(bySnakeCase.title, 'Seer');
    });

    test('prefers backend avatar url fields before legacy image fields', () {
      final hero = HeroSummary.fromJson({
        'id': 1,
        'name': 'Arthur',
        'avatar_url_large': 'large.png',
        'avatar_url_medium': 'medium.png',
        'avatar_url': 'avatar-url.png',
        'avatar': 'avatar.png',
        'icon': 'icon.png',
        'image': 'image.png',
      });
      final mediumOnly = HeroSummary.fromJson({
        'id': 2,
        'name': 'Angela',
        'avatar_url_large': '',
        'avatar_url_medium': 'medium.png',
        'avatar_url': 'avatar-url.png',
        'avatar': 'avatar.png',
      });
      final urlOnly = HeroSummary.fromJson({
        'id': 3,
        'name': 'Dolia',
        'avatar_url_large': '',
        'avatar_url_medium': '',
        'avatar_url': 'avatar-url.png',
        'avatar': 'avatar.png',
      });

      expect(hero.avatar, 'avatar-url.png');
      expect(mediumOnly.avatar, 'avatar-url.png');
      expect(urlOnly.avatar, 'avatar-url.png');
    });

    test('prefers Django hero id over external heroId for detail routes', () {
      final hero = HeroSummary.fromJson({
        'id': 42,
        'heroId': 190,
        'heroName': 'Arthur',
      });

      expect(hero.id, '42');
      expect(hero.detailRouteId, '42');
    });
  });

  group('HeroesRepository', () {
    test('loads heroes with region filter and result data rows', () async {
      final apiClient = _FakeApiClient(
        postResponse: {
          'result': {
            'data': [
              {'id': 1, 'name': 'Arthur', 'avatar': 'arthur.png'},
              {'heroId': 2, 'heroName': 'Angela', 'icon': 'angela.png'},
            ],
          },
        },
      );
      final repository = HeroesRepository(apiClient: apiClient);

      final heroes = await repository.loadHeroes(2);

      expect(apiClient.postPath, '/hero/gallery');
      expect(apiClient.postBody, {
        'page': 1,
        'pageSize': 60,
        'sort': 'created_at',
        'order': 'desc',
        'filterRules': [
          {'field': 'region_id', 'op': 'eq', 'value': 2},
        ],
      });
      expect(heroes.map((hero) => hero.name), ['Arthur', 'Angela']);
    });

    test(
      'loads heroes with hokx-compatible search sort and lane filters',
      () async {
        final apiClient = _FakeApiClient(
          postResponse: {
            'result': {'data': <Map<String, Object>>[]},
          },
        );
        final repository = HeroesRepository(apiClient: apiClient);

        await repository.loadHeroes(
          2,
          search: 'Lam',
          sort: 'rating',
          order: 'asc',
          lanePosition: 0,
          minRating: 4,
        );

        expect(apiClient.postPath, '/hero/gallery');
        expect(apiClient.postBody, {
          'page': 1,
          'pageSize': 60,
          'sort': 'rating',
          'order': 'asc',
          'filterRules': [
            {'field': 'region_id', 'op': 'eq', 'value': 2},
            {'field': 'name', 'op': 'contains', 'value': 'Lam', 'ig': true},
            {'field': 'position', 'op': 'eq', 'value': 0},
            {'field': 'rating', 'op': 'gte', 'value': 4.0},
          ],
        });
      },
    );

    test('filters heroes with empty malformed or non-numeric ids', () async {
      final repository = HeroesRepository(
        apiClient: _FakeApiClient(
          postResponse: {
            'result': {
              'data': [
                {'id': 1, 'name': 'Arthur'},
                {'id': '', 'name': 'Empty'},
                {'id': 'abc', 'name': 'Text'},
                {'id': '12x', 'name': 'Mixed'},
                {'id': null, 'name': 'Null'},
                {'hero_id': '2', 'hero_name': 'Angela'},
              ],
            },
          },
        ),
      );

      final heroes = await repository.loadHeroes(2);

      expect(heroes.map((hero) => hero.id), ['1', '2']);
      expect(heroes.map((hero) => hero.name), ['Arthur', 'Angela']);
    });

    test('loads heroes from result rows or top-level rows', () async {
      final resultRowsRepository = HeroesRepository(
        apiClient: _FakeApiClient(
          postResponse: {
            'result': {
              'rows': [
                {'id': 3, 'name': 'Mulan'},
              ],
            },
          },
        ),
      );
      final topLevelRowsRepository = HeroesRepository(
        apiClient: _FakeApiClient(
          postResponse: {
            'rows': [
              {'id': 4, 'name': 'Li Bai'},
            ],
          },
        ),
      );

      final resultRows = await resultRowsRepository.loadHeroes(2);
      final topLevelRows = await topLevelRowsRepository.loadHeroes(2);

      expect(resultRows.single.name, 'Mulan');
      expect(topLevelRows.single.name, 'Li Bai');
    });

    test('loads hero detail with region query', () async {
      final apiClient = _FakeApiClient(
        getResponse: {
          'success': true,
          'result': {'id': 1, 'name': 'Arthur'},
        },
      );
      final repository = HeroesRepository(apiClient: apiClient);

      final detail = await repository.loadHeroDetail('001', 2);

      expect(apiClient.getPath, '/hero/1');
      expect(apiClient.getQuery, {'region_id': 2});
      expect(detail['result'], {'id': 1, 'name': 'Arthur'});
    });
  });

  testWidgets(
    'hero gallery handles long names and titles without layout errors',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            heroGalleryProvider.overrideWith((ref) async {
              return const [
                HeroSummary(
                  id: '123456',
                  name: 'A Very Long Internationalized Hero Display Name',
                  avatar: '',
                  title: 'An Equally Long Title That Should Ellipsize Cleanly',
                ),
              ];
            }),
          ],
          child: const MaterialApp(home: Scaffold(body: HeroGalleryScreen())),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Heroes'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('hero gallery filters from initial search query', (tester) async {
    final repository = _FakeHeroesRepository(
      heroes: const [
        HeroSummary(id: '1', name: 'Lam', avatar: '', title: 'Shark Rider'),
        HeroSummary(id: '2', name: 'Angela', avatar: '', title: 'Arcane Mage'),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          heroesRepositoryProvider.overrideWithValue(repository),
          heroGalleryRegionProvider.overrideWith((ref) async => 2),
        ],
        child: const MaterialApp(
          home: Scaffold(body: HeroGalleryScreen(initialSearchQuery: 'Lam')),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Lam'), findsOneWidget);
    expect(find.text('Lam'), findsWidgets);
    expect(find.text('Angela'), findsNothing);
    expect(repository.requestedSearch, 'Lam');
  });

  testWidgets('hero gallery requests hokx-compatible filters', (tester) async {
    final repository = _FakeHeroesRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          heroesRepositoryProvider.overrideWithValue(repository),
          heroGalleryRegionProvider.overrideWith((ref) async => 2),
        ],
        child: const MaterialApp(home: Scaffold(body: HeroGalleryScreen())),
      ),
    );

    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Lam');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rating'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('hero-lane-0')));
    await tester.pumpAndSettle();

    expect(repository.requestedSearch, 'Lam');
    expect(repository.requestedSort, 'rating');
    expect(repository.requestedOrder, 'asc');
    expect(repository.requestedLanePosition, 0);
    expect(repository.requestedMinRating, 0);
  });
}
