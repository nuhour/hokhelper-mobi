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

  String? getPath;
  Map<String, dynamic>? getQuery;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    getPath = path;
    getQuery = query;
    if (path == '/community/posts/31') {
      return const {
        'success': true,
        'result': {
          'post': {
            'id': 31,
            'title': 'Version 1.2.3 Patch Notes',
            'content':
                'Complete balance notes with item, lane, and hero details.',
            'content_preview': 'Lam and Angela adjusted.',
            'tags': ['Patch Notes', 'Balance'],
            'hero_histories': [
              {
                'hero_id': 42,
                'hero_name': 'Lam',
                'avatar_url': 'https://example.test/lam.png',
                'change_type': 'buff',
              },
            ],
          },
        },
      };
    }
    return const {
      'success': true,
      'result': {
        'rows': [
          {
            'id': 31,
            'title': 'Version 1.2.3 Patch Notes',
            'date': '2026-07-01',
            'content_preview': 'Lam and Angela adjusted.',
            'content': 'Full patch note body with balance details.',
            'tags': ['Patch Notes', 'Balance'],
            'hero_histories': [
              {
                'hero_id': 42,
                'hero_name': 'Lam',
                'avatar_url': 'https://example.test/lam.png',
                'change_type': 'buff',
              },
              {
                'heroId': 21,
                'heroName': 'Angela',
                'avatar_url': '',
                'change_type': 'nerf',
              },
            ],
          },
          {
            'id': 32,
            'title': 'Community Story',
            'tags': ['Guide'],
          },
        ],
      },
    };
  }
}

void main() {
  test('loads patch notes and parses hero changes', () async {
    final apiClient = _FakeApiClient();
    final repository = ContentRepository(apiClient: apiClient);

    final notes = await repository.loadPatchNotes(2);

    expect(apiClient.getPath, '/community/posts');
    expect(apiClient.getQuery?['pageSize'], 120);
    expect(apiClient.getQuery?['sort'], 'new');
    expect(notes, hasLength(1));
    expect(notes.single.version, '1.2.3');
    expect(notes.single.content, 'Full patch note body with balance details.');
    expect(notes.single.changeCount, 2);
    expect(notes.single.heroChanges, hasLength(2));
    expect(notes.single.heroChanges.first.heroName, 'Lam');
    expect(notes.single.heroChanges.first.changeType, 'buff');
    expect(notes.single.heroChanges.last.heroName, 'Angela');
    expect(notes.single.heroChanges.last.changeType, 'nerf');
  });

  test('loads later patch note pages with backend-compatible query', () async {
    final apiClient = _FakeApiClient();
    final repository = ContentRepository(apiClient: apiClient);

    await repository.loadPatchNotes(3, page: 2, pageSize: 40);

    expect(apiClient.getPath, '/community/posts');
    expect(apiClient.getQuery?['page'], 2);
    expect(apiClient.getQuery?['pageSize'], 40);
    expect(apiClient.getQuery?['sort'], 'new');
    expect(apiClient.getQuery?['filterRules'], contains('"value":3'));
  });

  test('loads patch note detail content from community post detail', () async {
    final apiClient = _FakeApiClient();
    final repository = ContentRepository(apiClient: apiClient);

    final note = await repository.loadPatchNoteDetail(31, regionId: 2);

    expect(apiClient.getPath, '/community/posts/31');
    expect(apiClient.getQuery?['region_id'], 2);
    expect(
      note.content,
      'Complete balance notes with item, lane, and hero details.',
    );
    expect(note.preview, 'Lam and Angela adjusted.');
    expect(note.heroChanges, hasLength(1));
    expect(note.heroChanges.single.heroName, 'Lam');
  });
}
