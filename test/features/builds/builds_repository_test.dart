import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
import 'package:hok_helper_mobile/src/features/builds/data/builds_repository.dart';

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

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    getPath = path;
    getQuery = query;
    return const {
      'success': true,
      'result': {
        'data': [
          {
            'id': 7,
            'name': 'Burst jungle',
            'hero_name': 'Lam',
            'author': {'username': 'coach'},
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
      expect(jsonDecode(apiClient.getQuery?['filterRules'] as String), [
        {'field': 'region_id', 'op': 'eq', 'value': 2},
      ]);
      expect(schemes, hasLength(1));
      expect(schemes.single.id, 7);
      expect(schemes.single.title, 'Burst jungle');
      expect(schemes.single.heroName, 'Lam');
      expect(schemes.single.authorName, 'coach');
      expect(schemes.single.equipmentIcons, [
        'https://example.test/axe.png',
        'https://example.test/boots.png',
      ]);
      expect(schemes.single.likeCount, 12);
      expect(schemes.single.favoriteCount, 5);
      expect(schemes.single.cloneCount, 3);
    },
  );
}
