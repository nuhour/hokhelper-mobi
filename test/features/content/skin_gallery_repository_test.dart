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

  final postCalls = <String>[];
  final postBodies = <Object?>[];
  final getCalls = <String>[];
  Object? lastBody;

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    postCalls.add(path);
    postBodies.add(body);
    lastBody = body;
    if (path.endsWith('/rate')) {
      return const {
        'success': true,
        'avg_rating': 5,
        'rating_count': 13,
        'action': 'created',
      };
    }

    return const {
      'success': true,
      'result': {
        'rows': [
          {
            'id': 1001,
            'name': 'Crimson Hunter',
            'hero_name': 'Lam',
            'additional_image_url': 'https://example.test/portrait.jpg',
            'image_url': 'https://example.test/splash.jpg',
            'series_name': 'Hunter Series',
            'region_name': 'Global',
            'hero_position': 0,
            'rating': 4.5,
            'rating_count': 12,
            'link_url': 'https://example.test/skin/1001',
          },
        ],
      },
    };
  }

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    getCalls.add(path);
    return const {
      'success': true,
      'id': 1001,
      'name': 'Crimson Hunter',
      'hero_name': 'Lam',
      'additional_image_url': 'https://example.test/portrait.jpg',
      'image_url': 'https://example.test/splash.jpg',
      'series_name': 'Hunter Series',
      'region_name': 'Global',
      'rating': 4.5,
      'rating_count': 12,
      'link_url': 'https://example.test/skin/1001',
    };
  }
}

void main() {
  test('loads skin gallery list and skin detail', () async {
    final apiClient = _FakeApiClient();
    final repository = ContentRepository(apiClient: apiClient);

    final skins = await repository.loadSkins(2, pageSize: 60);
    final detail = await repository.loadSkinDetail(1001);

    expect(apiClient.postCalls, ['/skin/list']);
    expect(apiClient.lastBody, isA<Map<String, Object>>());
    expect(skins.single.id, 1001);
    expect(skins.single.title, 'Crimson Hunter');
    expect(skins.single.heroName, 'Lam');
    expect(skins.single.imageUrl, 'https://example.test/portrait.jpg');
    expect(skins.single.landscapeImageUrl, 'https://example.test/splash.jpg');
    expect(skins.single.heroPosition, 0);

    expect(apiClient.getCalls, ['/skin/1001']);
    expect(detail.id, 1001);
    expect(detail.title, 'Crimson Hunter');
    expect(detail.landscapeUrl, 'https://example.test/splash.jpg');
    expect(detail.seriesName, 'Hunter Series');
    expect(detail.linkUrl, 'https://example.test/skin/1001');
  });

  test(
    'rates skins with web-compatible payload and parses updated metrics',
    () async {
      final apiClient = _FakeApiClient();
      final repository = ContentRepository(apiClient: apiClient);

      final result = await repository.rateSkin(1001, 5);

      expect(apiClient.postCalls, ['/skin/1001/rate']);
      expect(apiClient.postBodies.single, {'rating': 5.0});
      expect(result.rating, 5);
      expect(result.ratingCount, 13);
    },
  );
}
