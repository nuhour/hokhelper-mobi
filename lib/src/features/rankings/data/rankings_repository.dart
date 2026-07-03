import '../../../core/network/api_client.dart';
import '../domain/hero_ranking_entry.dart';

class RankingsRepository {
  const RankingsRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<List<HeroRankingEntry>> loadHeroRanking(
    int regionId, {
    String sortBy = 'win_rate',
    int limit = 20,
  }) async {
    final json = await apiClient.getJson(
      '/ranking/heroes',
      query: {
        'region_id': regionId,
        'sort_by': sortBy,
        'order': 'desc',
        'limit': limit,
      },
    );
    final data = json['data'];
    final result = json['result'];
    final heroes = data is Map
        ? data['heroes']
        : result is Map
        ? result['heroes'] ?? result['data']
        : json['heroes'];
    if (heroes is! List) {
      return const [];
    }

    return heroes.map(HeroRankingEntry.fromJson).toList(growable: false);
  }
}
