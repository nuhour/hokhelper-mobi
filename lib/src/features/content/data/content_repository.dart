import '../../../core/network/api_client.dart';

class ContentRepository {
  const ContentRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<Map<String, dynamic>> loadSkins(int regionId) {
    return apiClient.postJson('/skin/list', body: _pagedRegionBody(regionId));
  }

  Future<Map<String, dynamic>> loadCgs(int regionId) {
    return apiClient.postJson('/cg/list', body: _pagedRegionBody(regionId));
  }

  Map<String, Object> _pagedRegionBody(int regionId) {
    return {
      'page': 1,
      'pageSize': 20,
      'filterRules': [
        {'field': 'region_id', 'op': 'eq', 'value': regionId},
      ],
    };
  }
}
