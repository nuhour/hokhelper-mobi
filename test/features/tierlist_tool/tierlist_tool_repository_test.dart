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
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    requestedPath = path;
    requestedBody = body;
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
}
