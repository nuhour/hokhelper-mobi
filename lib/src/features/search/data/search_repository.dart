import '../../../core/network/api_client.dart';

class SearchRepository {
  const SearchRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<Map<String, dynamic>> search(String keyword, int regionId) {
    return apiClient.postJson(
      '/search/global',
      body: {'query': keyword, 'region_id': regionId, 'limit_per_type': 10},
    );
  }
}
