import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
import 'package:hok_helper_mobile/src/features/activity/data/event_assistance_repository.dart';

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
      'total': 1,
      'rows': [
        {
          'id': '77',
          'region_id': 1,
          'content': 'Need one player for Friday event team.',
          'event_time': '2026-07-03T12:00:00Z',
          'is_reported': false,
          'raw_text': 'Need one player for Friday event team.',
          'shared_by': 'captain',
          'created_at': '2026-07-03T12:00:00Z',
          'updated_at': '2026-07-03T12:00:00Z',
        },
      ],
    };
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    postPath = path;
    postBody = body;
    return const {
      'success': true,
      'message': 'Submitted',
      'result': {
        'id': '78',
        'region_id': 1,
        'content': 'Join my activity code ABCD.',
        'event_time': '2026-07-04T09:00:00Z',
        'is_reported': false,
        'created_at': '2026-07-04T09:00:00Z',
        'updated_at': '2026-07-04T09:00:00Z',
      },
    };
  }
}

void main() {
  test('loads event assistance records', () async {
    final apiClient = _FakeApiClient();
    final repository = EventAssistanceRepository(apiClient: apiClient);

    final records = await repository.loadRecords(regionId: 2);

    expect(apiClient.getPath, '/activity/records');
    expect(apiClient.getQuery, {'page': 1, 'pageSize': 50, 'region_id': 2});
    expect(records, hasLength(1));
    expect(records.single.id, '77');
    expect(records.single.content, 'Need one player for Friday event team.');
    expect(records.single.sharedBy, 'captain');
    expect(records.single.reportedLabel, 'Active');
  });

  test('submits assistance text with region id', () async {
    final apiClient = _FakeApiClient();
    final repository = EventAssistanceRepository(apiClient: apiClient);

    final record = await repository.submitText(
      text: 'Join my activity code ABCD.',
      regionId: 3,
    );

    expect(apiClient.postPath, '/activity/records');
    expect(apiClient.postBody, {
      'text': 'Join my activity code ABCD.',
      'region_id': 3,
    });
    expect(record.id, '78');
    expect(record.content, 'Join my activity code ABCD.');
    expect(record.reportedLabel, 'Active');
  });

  test('reports assistance record with web-compatible endpoint', () async {
    final apiClient = _FakeApiClient();
    final repository = EventAssistanceRepository(apiClient: apiClient);

    await repository.reportRecord('77');

    expect(apiClient.postPath, '/activity/records/77/report');
    expect(apiClient.postBody, isEmpty);
  });
}
