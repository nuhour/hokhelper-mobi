import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
import 'package:hok_helper_mobile/src/features/builds/data/builds_repository.dart';

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
    return const {
      'success': true,
      'result': {'data': []},
    };
  }
}

void main() {
  test(
    'loads public build schemes with explore action and region filter',
    () async {
      final apiClient = _FakeApiClient();
      final repository = BuildsRepository(apiClient: apiClient);

      await repository.loadPublicSchemes(2);

      expect(apiClient.getPath, '/build/schemes');
      expect(apiClient.getQuery?['action'], 'explore');
      expect(apiClient.getQuery?['page'], 1);
      expect(apiClient.getQuery?['pageSize'], 20);
      expect(jsonDecode(apiClient.getQuery?['filterRules'] as String), [
        {'field': 'region_id', 'op': 'eq', 'value': 2},
      ]);
    },
  );
}
