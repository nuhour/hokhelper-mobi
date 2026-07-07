import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
import 'package:hok_helper_mobile/src/features/builds/data/builds_repository.dart';
import 'package:hok_helper_mobile/src/features/builds/domain/build_editor_asset.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient()
    : super(
        config: const AppConfig(
          apiBaseUrl: 'https://example.test',
          apiPrefix: '',
        ),
      );

  String? getPath;
  Map<String, dynamic>? getQuery;
  String? postPath;
  Object? postBody;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    getPath = path;
    getQuery = query;
    if (query?['action'] == 'mySchemes') {
      return const {
        'success': true,
        'result': {
          'schemes': [
            {
              'id': 8,
              'name': 'Slot one burst',
              'hero_id': 199,
              'hero_name': 'Lam',
              'author_name': 'me',
              'slot_index': 1,
              'equips': [
                {'icon': 'https://example.test/sword.png'},
              ],
              'likes_count': 2,
              'favorites_count': 1,
              'clones_count': 0,
              'is_public': false,
            },
          ],
        },
      };
    }
    return const {
      'success': true,
      'result': {
        'data': [
          {
            'id': 7,
            'name': 'Burst jungle',
            'hero_name': 'Lam',
            'author': {'id': 77, 'username': 'coach'},
            'equipment': [
              {'icon': 'https://example.test/axe.png'},
              {'icon': 'https://example.test/boots.png'},
            ],
            'like_count': 12,
            'favorite_count': 5,
            'clone_count': 3,
          },
        ],
      },
    };
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    postPath = path;
    postBody = body;
    if (path == '/build/schemes/my-favorites') {
      return const {
        'success': true,
        'result': {
          'schemes': [
            {
              'id': 42,
              'name': 'Favorite burst',
              'hero_name': 'Angela',
              'author_name': 'coach',
              'equipment': [],
              'like_count': 12,
              'favorite_count': 9,
              'clone_count': 4,
              'is_public': true,
            },
          ],
        },
      };
    }
    if (path == '/build/equips') {
      return const {
        'success': true,
        'result': {
          'equips': [
            {
              'equip_id': 101,
              'name': 'Storm Axe',
              'icon': 'https://example.test/storm.png',
            },
          ],
        },
      };
    }
    if (path == '/build/summoner-skills') {
      return const {
        'success': true,
        'result': {
          'skills': [
            {
              'skill_id': 12,
              'name': 'Smite',
              'icon': 'https://example.test/smite.png',
            },
          ],
        },
      };
    }
    if (path == '/build/runes') {
      return const {
        'success': true,
        'result': {
          'runes': [
            {
              'rune_id': 201,
              'name': 'Fate',
              'color': 1,
              'icon': 'https://example.test/fate.png',
            },
          ],
        },
      };
    }
    return const {
      'success': true,
      'result': {
        'scheme': {'id': 10},
      },
    };
  }
}

void main() {
  test(
    'loads public build schemes with explore action and region filter',
    () async {
      final apiClient = _FakeApiClient();
      final repository = BuildsRepository(apiClient: apiClient);

      final schemes = await repository.loadPublicSchemes(2);

      expect(apiClient.getPath, '/build/schemes');
      expect(apiClient.getQuery?['action'], 'explore');
      expect(apiClient.getQuery?['page'], 1);
      expect(apiClient.getQuery?['pageSize'], 20);
      expect(apiClient.getQuery?['sort'], '-hot');
      expect(apiClient.getQuery?['order'], 'desc');
      expect(jsonDecode(apiClient.getQuery?['filterRules'] as String), [
        {'field': 'region_id', 'op': 'eq', 'value': 2},
      ]);
      expect(schemes, hasLength(1));
      expect(schemes.single.id, 7);
      expect(schemes.single.title, 'Burst jungle');
      expect(schemes.single.heroName, 'Lam');
      expect(schemes.single.authorName, 'coach');
      expect(schemes.single.authorId, 77);
      expect(schemes.single.equipmentIcons, [
        'https://example.test/axe.png',
        'https://example.test/boots.png',
      ]);
      expect(schemes.single.likeCount, 12);
      expect(schemes.single.favoriteCount, 5);
      expect(schemes.single.cloneCount, 3);
    },
  );

  test('loads latest public build schemes with hokx sort parameter', () async {
    final apiClient = _FakeApiClient();
    final repository = BuildsRepository(apiClient: apiClient);

    await repository.loadPublicSchemes(2, sort: BuildSchemeSort.latest);

    expect(apiClient.getPath, '/build/schemes');
    expect(apiClient.getQuery?['action'], 'explore');
    expect(apiClient.getQuery?['sort'], '-updated_at');
    expect(apiClient.getQuery?['order'], 'desc');
  });

  test('loads public build schemes with hokx hero filter', () async {
    final apiClient = _FakeApiClient();
    final repository = BuildsRepository(apiClient: apiClient);

    await repository.loadPublicSchemes(2, heroId: 166);

    expect(apiClient.getPath, '/build/schemes');
    expect(jsonDecode(apiClient.getQuery?['filterRules'] as String), [
      {'field': 'region_id', 'op': 'eq', 'value': 2},
      {'field': 'hero__heroId', 'op': 'eq', 'value': 166},
    ]);
  });

  test(
    'loads my build slots for a hero with region and hero filters',
    () async {
      final apiClient = _FakeApiClient();
      final repository = BuildsRepository(apiClient: apiClient);

      final slots = await repository.loadUserHeroSlots(
        heroId: 199,
        regionId: 2,
      );

      expect(apiClient.getPath, '/build/schemes');
      expect(apiClient.getQuery?['action'], 'mySchemes');
      expect(apiClient.getQuery?['page'], 1);
      expect(apiClient.getQuery?['pageSize'], 3);
      expect(jsonDecode(apiClient.getQuery?['filterRules'] as String), [
        {'field': 'hero__heroId', 'op': 'eq', 'value': 199},
        {'field': 'region_id', 'op': 'eq', 'value': 2},
      ]);
      expect(slots, hasLength(3));
      expect(slots[0]?.title, 'Slot one burst');
      expect(slots[0]?.slotIndex, 1);
      expect(slots[1], isNull);
      expect(slots[2], isNull);
    },
  );

  test('loads favorite build schemes with hokx favorites endpoint', () async {
    final apiClient = _FakeApiClient();
    final repository = BuildsRepository(apiClient: apiClient);

    final schemes = await repository.loadFavoriteSchemes();

    expect(apiClient.postPath, '/build/schemes/my-favorites');
    expect(apiClient.postBody, {'page': 1, 'pageSize': 20});
    expect(schemes, hasLength(1));
    expect(schemes.single.title, 'Favorite burst');
    expect(schemes.single.heroName, 'Angela');
    expect(schemes.single.favoriteCount, 9);
  });

  test('likes build schemes with hokx-compatible endpoint', () async {
    final apiClient = _FakeApiClient();
    final repository = BuildsRepository(apiClient: apiClient);

    await repository.likeBuildScheme(7);

    expect(apiClient.postPath, '/build/schemes/like');
    expect(apiClient.postBody, {'scheme_id': '7'});
  });

  test('favorites build schemes with hokx-compatible endpoint', () async {
    final apiClient = _FakeApiClient();
    final repository = BuildsRepository(apiClient: apiClient);

    await repository.favoriteBuildScheme(7);

    expect(apiClient.postPath, '/build/schemes/favorite');
    expect(apiClient.postBody, {'scheme_id': '7'});
  });

  test('loads top equips with backend region filters', () async {
    final apiClient = _FakeApiClient();
    final repository = BuildsRepository(apiClient: apiClient);

    final equips = await repository.loadTopEquips(2);

    expect(apiClient.postPath, '/build/equips');
    final body = apiClient.postBody as Map<String, dynamic>;
    expect(body['page'], 1);
    expect(body['pageSize'], 100);
    expect(body['filterRules'], [
      {'field': 'region_id', 'op': 'eq', 'value': 2},
      {'field': 'is_top_equip', 'op': 'eq', 'value': true},
    ]);
    expect(equips.single.id, 101);
    expect(equips.single.name, 'Storm Axe');
  });

  test('loads summoner skills with backend region filters', () async {
    final apiClient = _FakeApiClient();
    final repository = BuildsRepository(apiClient: apiClient);

    final skills = await repository.loadSummonerSkills(2);

    expect(apiClient.postPath, '/build/summoner-skills');
    final body = apiClient.postBody as Map<String, dynamic>;
    expect(body['filterRules'], [
      {'field': 'region_id', 'op': 'eq', 'value': 2},
    ]);
    expect(skills.single.id, 12);
    expect(skills.single.name, 'Smite');
  });

  test('loads level five runes with backend region filters', () async {
    final apiClient = _FakeApiClient();
    final repository = BuildsRepository(apiClient: apiClient);

    final runes = await repository.loadRunes(2);

    expect(apiClient.postPath, '/build/runes');
    final body = apiClient.postBody as Map<String, dynamic>;
    expect(body['filterRules'], [
      {'field': 'region_id', 'op': 'eq', 'value': 2},
      {'field': 'level', 'op': 'eq', 'value': 5},
    ]);
    expect(runes.single.id, 201);
    expect(runes.single.name, 'Fate');
    expect(runes.single.color, 1);
  });

  test('creates a build scheme slot with editor payload', () async {
    final apiClient = _FakeApiClient();
    final repository = BuildsRepository(apiClient: apiClient);

    await repository.saveBuildScheme(
      const BuildSchemeDraft(
        heroId: 199,
        slotIndex: 2,
        title: 'Mobile burst',
        isPublic: true,
        equipIds: [101, 102],
        runeIds: [201],
        summonerSkillId: 12,
        regionCode: 'en',
      ),
    );

    expect(apiClient.postPath, '/build/schemes');
    expect(apiClient.postBody, {
      'hero_id': 199,
      'slot_index': 2,
      'region_code': 'en',
      'name': 'Mobile burst',
      'description': '',
      'is_public': true,
      'equips': [101, 102],
      'runes': [201],
      'summoner_skill_id': 12,
    });
  });

  test(
    'updates an existing build scheme through compatibility endpoint',
    () async {
      final apiClient = _FakeApiClient();
      final repository = BuildsRepository(apiClient: apiClient);

      await repository.saveBuildScheme(
        const BuildSchemeDraft(
          schemeId: 8,
          heroId: 199,
          slotIndex: 1,
          title: 'Updated burst',
          isPublic: false,
          equipIds: [101],
          runeIds: [201],
          summonerSkillId: 12,
          regionCode: 'en',
        ),
      );

      expect(apiClient.postPath, '/build/schemes/8/update');
      expect(
        (apiClient.postBody as Map<String, dynamic>)['name'],
        'Updated burst',
      );
    },
  );

  test(
    'likes and favorites build schemes through backend action endpoints',
    () async {
      final apiClient = _FakeApiClient();
      final repository = BuildsRepository(apiClient: apiClient);

      await repository.likeBuildScheme(7);
      expect(apiClient.postPath, '/build/schemes/like');
      expect(apiClient.postBody, {'scheme_id': '7'});

      await repository.favoriteBuildScheme(7);
      expect(apiClient.postPath, '/build/schemes/favorite');
      expect(apiClient.postBody, {'scheme_id': '7'});
    },
  );

  test('clones a public build scheme into a selected slot', () async {
    final apiClient = _FakeApiClient();
    final repository = BuildsRepository(apiClient: apiClient);

    await repository.cloneBuildScheme(
      schemeId: 7,
      slotIndex: 2,
      name: 'Burst jungle',
    );

    expect(apiClient.postPath, '/build/schemes/clone');
    expect(apiClient.postBody, {
      'scheme_id': '7',
      'slot_index': 2,
      'name': 'Burst jungle',
    });
  });
}
