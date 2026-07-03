import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
import 'package:hok_helper_mobile/src/features/community/data/community_repository.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient()
    : super(
        config: const AppConfig(
          apiBaseUrl: 'https://example.test',
          apiPrefix: '',
        ),
      );

  final getQueries = <String, Map<String, dynamic>?>{};

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    getQueries[path] = query;

    return switch (path) {
      '/community/posts' => const {
        'total': 1,
        'rows': [
          {
            'id': '101',
            'title': 'Best jungle rotation',
            'content_preview': 'Start blue, punish mid wave, then invade.',
            'author_name': 'coach',
            'author_avatar': 'https://example.test/coach.png',
            'tags': ['Guide', 'Jungle'],
            'region_code': 'en',
            'created_at': '2026-07-01T10:00:00Z',
            'view_count': 230,
            'like_count': 18,
            'comment_count': 7,
          },
        ],
      },
      '/leak/posts' => const {
        'total': 1,
        'rows': [
          {
            'id': '501',
            'category': 'skin',
            'platform': 'youtube',
            'title': 'New Lam skin teaser',
            'content_text': 'A cyber themed Lam skin appeared in preview.',
            'author_name': 'leaker',
            'author_handle': '@leaker',
            'author_avatar_url': 'https://example.test/leaker.png',
            'source_url': 'https://example.test/source',
            'media_url': 'https://example.test/leak.jpg',
            'media_type': 'image',
            'published_at': '2026-07-02T12:00:00Z',
            'like_count': 91,
            'view_count': 1200,
            'matched_keywords': ['Lam', 'skin'],
          },
        ],
      },
      _ => throw StateError('Unexpected path $path'),
    };
  }
}

void main() {
  test('loads community posts with region filter', () async {
    final apiClient = _FakeApiClient();
    final repository = CommunityRepository(apiClient: apiClient);

    final posts = await repository.loadPosts(2);

    expect(apiClient.getQueries['/community/posts'], {
      'page': 1,
      'pageSize': 30,
      'sort': 'hot',
      'filterRules': '[{"field":"region_id","op":"eq","value":2}]',
    });
    expect(posts, hasLength(1));
    expect(posts.single.id, '101');
    expect(posts.single.title, 'Best jungle rotation');
    expect(posts.single.preview, 'Start blue, punish mid wave, then invade.');
    expect(posts.single.authorName, 'coach');
    expect(posts.single.tags, ['Guide', 'Jungle']);
    expect(posts.single.metricText, '18 likes · 7 comments');
  });

  test('loads leak posts with region and all-category query', () async {
    final apiClient = _FakeApiClient();
    final repository = CommunityRepository(apiClient: apiClient);

    final leaks = await repository.loadLeaks(3);

    expect(apiClient.getQueries['/leak/posts'], {
      'page': 1,
      'pageSize': 30,
      'region_id': 3,
      'category': 'all',
    });
    expect(leaks, hasLength(1));
    expect(leaks.single.id, '501');
    expect(leaks.single.title, 'New Lam skin teaser');
    expect(leaks.single.category, 'skin');
    expect(leaks.single.platform, 'youtube');
    expect(leaks.single.authorLabel, 'leaker · @leaker');
    expect(leaks.single.metricText, '91 likes · 1200 views');
    expect(leaks.single.keywords, ['Lam', 'skin']);
  });
}
