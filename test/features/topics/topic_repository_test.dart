import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
import 'package:hok_helper_mobile/src/features/topics/data/topic_repository.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient()
    : super(
        config: const AppConfig(
          apiBaseUrl: 'https://example.test',
          apiPrefix: '',
        ),
      );

  final requestedPaths = <String>[];
  final requestedQueries = <Map<String, dynamic>?>[];

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    requestedPaths.add(path);
    requestedQueries.add(query);

    if (path == '/topic/articles') {
      return const {
        'success': true,
        'message': 'ok',
        'result': {
          'topic_key': 'hok-world',
          'rows': [
            {
              'id': 11,
              'slug': 'hok-world-tier-list',
              'topic_key': 'hok-world',
              'locale': 'en',
              'title': 'HOK World Tier List',
              'excerpt': 'A starter guide for HOK World rankings.',
              'seo_description': 'Ranked context for HOK World.',
              'cover_image_url': 'https://example.test/world.jpg',
              'tags': ['Guide', 'Meta'],
              'sort_order': 1,
              'published_at': '2026-07-01 10:00:00',
            },
          ],
        },
      };
    }

    return const {
      'success': true,
      'message': 'ok',
      'result': {
        'id': 11,
        'slug': 'hok-world-tier-list',
        'topic_key': 'hok-world',
        'locale': 'en',
        'title': 'HOK World Tier List',
        'excerpt': 'A starter guide for HOK World rankings.',
        'content': '## Why it matters\nUse hero roles and stats together.',
        'seo_title': 'HOK World Tier List | HOK Helper',
        'seo_description': 'Ranked context for HOK World.',
        'cover_image_url': 'https://example.test/world.jpg',
        'tags': ['Guide', 'Meta'],
        'available_locales': ['en', 'zh'],
        'published_at': '2026-07-01 10:00:00',
        'updated_at': '2026-07-02 10:00:00',
      },
    };
  }
}

void main() {
  test('loads topic article summaries with hokx query contract', () async {
    final apiClient = _FakeApiClient();
    final repository = TopicRepository(apiClient: apiClient);

    final articles = await repository.loadArticles(
      topicKey: 'hok-world',
      locale: 'en',
      limit: 12,
    );

    expect(apiClient.requestedPaths.single, '/topic/articles');
    expect(apiClient.requestedQueries.single, {
      'topic_key': 'hok-world',
      'locale': 'en',
      'limit': 12,
    });
    expect(articles.single.slug, 'hok-world-tier-list');
    expect(articles.single.title, 'HOK World Tier List');
    expect(articles.single.tags, ['Guide', 'Meta']);
  });

  test('loads topic article detail by slug and locale', () async {
    final apiClient = _FakeApiClient();
    final repository = TopicRepository(apiClient: apiClient);

    final article = await repository.loadArticle(
      slug: 'hok-world-tier-list',
      locale: 'en',
    );

    expect(apiClient.requestedPaths.single, '/topic/article');
    expect(apiClient.requestedQueries.single, {
      'slug': 'hok-world-tier-list',
      'locale': 'en',
    });
    expect(article.title, 'HOK World Tier List');
    expect(article.content, contains('Why it matters'));
    expect(article.availableLocales, ['en', 'zh']);
  });
}
