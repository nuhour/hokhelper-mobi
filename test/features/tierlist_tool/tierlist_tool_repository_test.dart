import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
import 'package:hok_helper_mobile/src/features/tierlist_tool/data/tierlist_tool_repository.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient()
    : super(
        config: const AppConfig(
          apiBaseUrl: 'https://example.test',
          apiPrefix: '',
        ),
      );

  String? requestedPath;
  Object? requestedBody;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    requestedPath = path;
    requestedBody = query;
    return const {
      'success': true,
      'message': 'success',
      'result': {
        'id': '42',
        'name': 'KIC Knockout Meta',
        'createdAt': '2026-07-02T08:00:00Z',
        'updatedAt': '2026-07-04T12:00:00Z',
        'rows': [
          {
            'id': 'r1',
            'label': 'T0',
            'color': 'bg-red-600',
            'heroIds': [111, 222, 333],
          },
          {
            'id': 'r2',
            'label': 'T1',
            'color': 'bg-orange-500',
            'heroIds': [444],
          },
        ],
      },
    };
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    requestedPath = path;
    requestedBody = body;
    if (path == '/tierlist/schemes/create') {
      return const {
        'success': true,
        'message': 'success',
        'result': {
          'scheme': {
            'id': '77',
            'name': 'Mobile Tier List',
            'createdAt': '2026-07-07T10:00:00Z',
            'updatedAt': '2026-07-07T10:00:00Z',
            'rows': [
              {'id': 't0', 'label': 'T0', 'color': 'bg-red-600', 'heroIds': []},
              {
                'id': 't1',
                'label': 'T1',
                'color': 'bg-orange-500',
                'heroIds': [111],
              },
            ],
          },
        },
      };
    }
    if (path == '/tierlist/schemes/9/delete') {
      return const {'success': true, 'message': 'success'};
    }
    return const {
      'success': true,
      'message': 'success',
      'result': {
        'total': 1,
        'schemes': [
          {
            'id': '9',
            'name': 'Solo Queue Meta',
            'createdAt': '2026-07-01T08:00:00Z',
            'updatedAt': '2026-07-03T12:00:00Z',
            'rows': [
              {
                'id': 'r1',
                'label': 'T0',
                'color': 'bg-red-600',
                'heroIds': [111, 222],
              },
              {
                'id': 'r2',
                'label': 'T1',
                'color': 'bg-orange-500',
                'heroIds': [333],
              },
            ],
          },
        ],
      },
    };
  }
}

void main() {
  test('loads tier list schemes with backend-compatible POST body', () async {
    final apiClient = _FakeApiClient();
    final repository = TierListToolRepository(apiClient: apiClient);

    final schemes = await repository.loadSchemes();

    expect(apiClient.requestedPath, '/tierlist/schemes');
    expect(apiClient.requestedBody, {
      'page': 1,
      'pageSize': 20,
      'sort': 'created_at',
      'order': 'desc',
    });
    expect(schemes.single.id, '9');
    expect(schemes.single.name, 'Solo Queue Meta');
    expect(schemes.single.updatedDateText, '2026-07-03');
    expect(schemes.single.heroCountText, '3 heroes');
    expect(schemes.single.rows.first.label, 'T0');
    expect(schemes.single.rows.first.heroCount, 2);
  });

  test('loads a tier list scheme detail with hokx detail endpoint', () async {
    final apiClient = _FakeApiClient();
    final repository = TierListToolRepository(apiClient: apiClient);

    final scheme = await repository.loadScheme('42');

    expect(apiClient.requestedPath, '/tierlist/schemes/42');
    expect(apiClient.requestedBody, isNull);
    expect(scheme.id, '42');
    expect(scheme.name, 'KIC Knockout Meta');
    expect(scheme.heroCountText, '4 heroes');
    expect(scheme.rows.first.label, 'T0');
    expect(scheme.rows.first.heroCount, 3);
  });

  test(
    'creates a tier list scheme with hokx-compatible request fields',
    () async {
      final apiClient = _FakeApiClient();
      final repository = TierListToolRepository(apiClient: apiClient);

      final scheme = await repository.createScheme(name: 'Mobile Tier List');

      expect(apiClient.requestedPath, '/tierlist/schemes/create');
      expect(apiClient.requestedBody, {
        'name': 'Mobile Tier List',
        'rows': [
          {'id': 't0', 'label': 'T0', 'color': 'bg-red-600', 'heroIds': []},
          {'id': 't1', 'label': 'T1', 'color': 'bg-orange-500', 'heroIds': []},
          {'id': 't2', 'label': 'T2', 'color': 'bg-yellow-500', 'heroIds': []},
          {'id': 't3', 'label': 'T3', 'color': 'bg-green-500', 'heroIds': []},
        ],
      });
      expect(scheme.id, '77');
      expect(scheme.name, 'Mobile Tier List');
      expect(scheme.heroCountText, '1 hero');
    },
  );

  test('deletes a tier list scheme with hokx-compatible endpoint', () async {
    final apiClient = _FakeApiClient();
    final repository = TierListToolRepository(apiClient: apiClient);

    await repository.deleteScheme('9');

    expect(apiClient.requestedPath, '/tierlist/schemes/9/delete');
    expect(apiClient.requestedBody, <String, Object?>{});
  });
}
