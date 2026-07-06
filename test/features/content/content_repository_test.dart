import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
import 'package:hok_helper_mobile/src/features/content/data/content_repository.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient()
    : super(
        config: const AppConfig(
          apiBaseUrl: 'https://example.test',
          apiPrefix: '',
        ),
      );

  String? postPath;
  Object? postBody;
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
      'total': 2,
      'rows': [
        {
          'id': 31,
          'title': 'Version 1.2.3 Patch Notes',
          'date': '2026-07-01',
          'created_at': '2026-07-01T10:00:00Z',
          'content_preview': 'Lam and Angela adjusted.',
          'tags': ['Patch Notes'],
          'hero_histories': [
            {'hero_id': 42, 'change_type': 'buff'},
            {'hero_id': 99, 'change_type': 'nerf'},
          ],
        },
        {
          'id': 32,
          'title': 'Community Spotlight',
          'date': '2026-07-02',
          'content_preview': 'Not a patch note.',
          'tags': ['Community'],
        },
      ],
    };
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    postPath = path;
    postBody = body;
    if (path == '/skin/list') {
      return const {
        'success': true,
        'rows': [
          {
            'id': 11,
            'name': 'Starlit Blade',
            'hero_name': 'Lam',
            'additional_image_url': 'https://example.test/skin.png',
            'series_name': 'Galaxy',
            'rating': 4.5,
            'rating_count': 18,
          },
        ],
      };
    }

    return const {
      'success': true,
      'result': {
        'data': [
          {
            'id': 21,
            'title1_key': 'Origin Story',
            'hero_name': 'Angela',
            'video_cover': 'https://example.test/cg.png',
            'play_url_info_list': [
              {'playURL': 'https://example.test/cg.mp4'},
            ],
            'view_count': 300,
            'rating': 4,
            'rating_count': 9,
          },
        ],
      },
    };
  }
}

void main() {
  group('ContentRepository', () {
    test('loads skins with region filter', () async {
      final apiClient = _FakeApiClient();
      final repository = ContentRepository(apiClient: apiClient);

      final skins = await repository.loadSkins(2);

      expect(apiClient.postPath, '/skin/list');
      expect(apiClient.postBody, {
        'page': 1,
        'pageSize': 20,
        'filterRules': [
          {'field': 'region_id', 'op': 'eq', 'value': 2},
        ],
      });
      expect(skins, hasLength(1));
      expect(skins.single.id, 11);
      expect(skins.single.title, 'Starlit Blade');
      expect(skins.single.heroName, 'Lam');
      expect(skins.single.imageUrl, 'https://example.test/skin.png');
      expect(skins.single.subtitle, 'Galaxy');
      expect(skins.single.rating, 4.5);
      expect(skins.single.ratingCount, 18);
    });

    test('loads CGs with region filter', () async {
      final apiClient = _FakeApiClient();
      final repository = ContentRepository(apiClient: apiClient);

      final cgs = await repository.loadCgs(3);

      expect(apiClient.postPath, '/cg/list');
      expect(apiClient.postBody, {
        'page': 1,
        'pageSize': 20,
        'sort': 'updated_at',
        'order': 'desc',
        'filterRules': [
          {'field': 'region_id', 'op': 'eq', 'value': 3},
        ],
      });
      expect(cgs, hasLength(1));
      expect(cgs.single.id, 21);
      expect(cgs.single.title, 'Origin Story');
      expect(cgs.single.heroName, 'Angela');
      expect(cgs.single.imageUrl, 'https://example.test/cg.png');
      expect(cgs.single.subtitle, 'Playable video');
      expect(cgs.single.viewCount, 300);
      expect(cgs.single.rating, 4);
      expect(cgs.single.ratingCount, 9);
    });

    test('loads patch notes from community posts with region filter', () async {
      final apiClient = _FakeApiClient();
      final repository = ContentRepository(apiClient: apiClient);

      final notes = await repository.loadPatchNotes(2);

      expect(apiClient.getPath, '/community/posts');
      expect(apiClient.getQuery, {
        'page': 1,
        'pageSize': 120,
        'sort': 'new',
        'filterRules': '[{"field":"region_id","op":"eq","value":2}]',
      });
      expect(notes, hasLength(1));
      expect(notes.single.id, 31);
      expect(notes.single.version, '1.2.3');
      expect(notes.single.title, 'Version 1.2.3 Patch Notes');
      expect(notes.single.date, '2026-07-01');
      expect(notes.single.preview, 'Lam and Angela adjusted.');
      expect(notes.single.changeCount, 2);
      expect(notes.single.tags, ['Patch Notes']);
    });
  });
}
