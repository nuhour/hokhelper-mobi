import '../../../core/network/api_client.dart';

class RankingsRepository {
  const RankingsRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<Map<String, dynamic>> loadHeroRanking(int regionId) {
    return apiClient.getJson(
      '/ranking/heroes',
      query: {'region_id': regionId, 'limit': 20},
    );
  }
}
