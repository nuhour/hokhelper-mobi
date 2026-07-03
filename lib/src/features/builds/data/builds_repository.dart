import 'dart:convert';

import '../../../core/network/api_client.dart';

class BuildsRepository {
  const BuildsRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<Map<String, dynamic>> loadPublicSchemes(int regionId) {
    return apiClient.getJson(
      '/build/schemes',
      query: {
        'action': 'explore',
        'page': 1,
        'pageSize': 20,
        'filterRules': jsonEncode([
          {'field': 'region_id', 'op': 'eq', 'value': regionId},
        ]),
      },
    );
  }
}
