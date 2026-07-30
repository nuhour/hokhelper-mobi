import '../../../core/network/api_client.dart';

class SearchRepository {
  const SearchRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<Map<String, dynamic>> search(String keyword, int regionId) {
    return apiClient.postJson(
      '/search/global',
      // 后端 MAX_LIMIT=20：取到每类可得的最大条数。
      body: {'query': keyword, 'region_id': regionId, 'limit_per_type': 20},
    );
  }
}
