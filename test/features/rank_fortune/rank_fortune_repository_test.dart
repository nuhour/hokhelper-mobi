import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
import 'package:hok_helper_mobile/src/features/rank_fortune/data/rank_fortune_repository.dart';

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
  String? postPath;
  Object? postBody;

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
        'rows': [
          {
            'id': 3,
            'date': '2026-07-04',
            'typeId': 'great',
            'score': 92,
            'created_at': '2026-07-04T09:00:00Z',
          },
        ],
        'today': {
          'id': 3,
          'date': '2026-07-04',
          'typeId': 'great',
          'score': 92,
          'created_at': '2026-07-04T09:00:00Z',
        },
        'can_draw': false,
        'days': 30,
        'fortune_catalog': [
          {'typeId': 'great', 'score': 92},
        ],
      },
    };
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    postPath = path;
    postBody = body;
    return const {
      'success': true,
      'result': {
        'id': 4,
        'date': '2026-07-05',
        'typeId': 'legendary',
        'score': 99,
        'created_at': '2026-07-05T09:00:00Z',
        'already_drawn': false,
        'can_draw': false,
        'fortune_catalog': [
          {'typeId': 'legendary', 'score': 99},
        ],
      },
    };
  }
}

void main() {
  test('loads rank fortune history with backend-compatible params', () async {
    final apiClient = _FakeApiClient();
    final repository = RankFortuneRepository(apiClient: apiClient);

    final history = await repository.loadHistory(days: 30);

    expect(apiClient.getPath, '/rank-fortune/history');
    expect(apiClient.getQuery, {'days': 30});
    expect(history.rows, hasLength(1));
    expect(history.today?.typeId, 'great');
    expect(history.today?.score, 92);
    expect(history.canDraw, isFalse);
    expect(history.catalog.single.typeId, 'great');
  });

  test('draws today fortune through backend endpoint', () async {
    final apiClient = _FakeApiClient();
    final repository = RankFortuneRepository(apiClient: apiClient);

    final draw = await repository.drawToday();

    expect(apiClient.postPath, '/rank-fortune/draw');
    expect(apiClient.postBody, <String, Object?>{});
    expect(draw.record.typeId, 'legendary');
    expect(draw.record.score, 99);
    expect(draw.canDraw, isFalse);
    expect(draw.catalog.single.typeId, 'legendary');
  });
}
