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
  final getQueries = <Map<String, dynamic>?>[];
  Object? lastBody;

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    postCalls.add(path);
    postBodies.add(body);
    lastBody = body;
    if (path.endsWith('/comments')) {
      return const {
        'success': true,
        'data': {'id': 12},
      };
    }
    if (path.endsWith('/view')) {
      return const {'success': true, 'view_count': 2301};
    }
    if (path.endsWith('/rate')) {
      return const {
        'success': true,
        'avg_rating': 5,
        'rating_count': 18,
        'action': 'created',
      };
    }

    return const {
      'success': true,
      'result': {
        'rows': [
          {
            'id': 501,
            'title1_key': 'Lam Cinematic',
            'hero_name': 'Lam',
            'video_cover': 'https://example.test/lam-cover.jpg',
            'play_url_info_list': [
              {'playURL': 'https://example.test/lam.mp4'},
            ],
            'view_count': 2300,
            'rating': 4.8,
            'rating_count': 17,
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
    getQueries.add(query);
    if (path.endsWith('/comments')) {
      return const {
        'success': true,
        'data': {
          'total': 1,
          'rows': [
            {
              'id': 9,
              'cg_id': 501,
              'author_name': 'coach',
              'author_avatar': '',
              'content': 'Great cinematic.',
              'created_at': '2026-07-03T08:30:00Z',
            },
          ],
        },
      };
    }

    return const {
      'success': true,
      'id': 501,
      'title1_key': 'Lam Cinematic',
      'hero_name': 'Lam',
      'video_cover': 'https://example.test/lam-cover.jpg',
      'play_url_info_list': [
        {'playURL': 'https://example.test/lam.mp4'},
      ],
      'view_count': 2300,
      'rating': 4.8,
      'rating_count': 17,
    };
  }
}

void main() {
  test('loads cg gallery, detail, and comments', () async {
    final apiClient = _FakeApiClient();
    final repository = ContentRepository(apiClient: apiClient);

    final cgs = await repository.loadCgs(2, pageSize: 50);
    final detail = await repository.loadCgDetail(501);
    final comments = await repository.loadCgComments(501);

    expect(apiClient.postCalls, ['/cg/list']);
    expect(apiClient.lastBody, isA<Map<String, Object>>());
    expect(cgs.single.id, 501);
    expect(cgs.single.title, 'Lam Cinematic');
    expect(cgs.single.viewCount, 2300);

    expect(apiClient.getCalls, ['/cg/501', '/cg/501/comments']);
    expect(detail.id, 501);
    expect(detail.playUrl, 'https://example.test/lam.mp4');
    expect(detail.coverUrl, 'https://example.test/lam-cover.jpg');
    expect(detail.rating, 4.8);
    expect(comments.single.authorName, 'coach');
    expect(comments.single.content, 'Great cinematic.');
  });

  test('loads global cg gallery with compatible sort and order', () async {
    final apiClient = _FakeApiClient();
    final repository = ContentRepository(apiClient: apiClient);

    await repository.loadCgs(
      2,
      page: 3,
      pageSize: 12,
      sort: 'created_at',
      order: 'asc',
    );

    expect(apiClient.postCalls, ['/cg/list']);
    expect(apiClient.lastBody, {
      'page': 3,
      'pageSize': 12,
      'sort': 'created_at',
      'order': 'asc',
      'filterRules': [],
    });
  });

  test('loads cg gallery with web-compatible search and hero filter', () async {
    final apiClient = _FakeApiClient();
    final repository = ContentRepository(apiClient: apiClient);

    await repository.loadCgs(2, search: 'lam', heroId: 199);

    expect(apiClient.postCalls, ['/cg/list']);
    expect(apiClient.lastBody, {
      'page': 1,
      'pageSize': 20,
      'sort': 'updated_at',
      'order': 'desc',
      'filterRules': [
        {'field': 'hero_id', 'op': 'eq', 'value': 199},
        {'field': 'title1_key', 'op': 'contains', 'value': 'lam', 'ig': true},
        {'field': 'hero_name', 'op': 'contains', 'value': 'lam', 'ig': true},
      ],
    });
  });

  test('loads cg comments with requested web-compatible order', () async {
    final apiClient = _FakeApiClient();
    final repository = ContentRepository(apiClient: apiClient);

    await repository.loadCgComments(501, order: 'asc');

    expect(apiClient.getCalls, ['/cg/501/comments']);
    expect(apiClient.getQueries.single, {
      'page': 1,
      'pageSize': 50,
      'order': 'asc',
    });
  });

  test('creates cg comments with web-compatible payload', () async {
    final apiClient = _FakeApiClient();
    final repository = ContentRepository(apiClient: apiClient);

    await repository.createCgComment(501, 'Nice trailer.');

    expect(apiClient.postCalls, ['/cg/501/comments']);
    expect(apiClient.postBodies.single, {'content': 'Nice trailer.'});
  });

  test('records cg views with web-compatible endpoint', () async {
    final apiClient = _FakeApiClient();
    final repository = ContentRepository(apiClient: apiClient);

    final viewCount = await repository.recordCgView(501);

    expect(apiClient.postCalls, ['/cg/501/view']);
    expect(apiClient.postBodies.single, isEmpty);
    expect(viewCount, 2301);
  });

  test(
    'rates cgs with web-compatible payload and parses updated metrics',
    () async {
      final apiClient = _FakeApiClient();
      final repository = ContentRepository(apiClient: apiClient);

      final result = await repository.rateCg(501, 5);

      expect(apiClient.postCalls, ['/cg/501/rate']);
      expect(apiClient.postBodies.single, {'rating': 5.0});
      expect(result.rating, 5);
      expect(result.ratingCount, 18);
    },
  );
}
