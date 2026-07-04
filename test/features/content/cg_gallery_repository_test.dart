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
  final getCalls = <String>[];
  Object? lastBody;

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    postCalls.add(path);
    lastBody = body;
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
}
