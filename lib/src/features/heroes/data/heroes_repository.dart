import '../../../core/network/api_client.dart';
import '../domain/hero_summary.dart';

class HeroesRepository {
  const HeroesRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<List<HeroSummary>> loadHeroes(int regionId) async {
    final json = await apiClient.postJson(
      '/hero/gallery',
      body: {
        'page': 1,
        'pageSize': 60,
        'filterRules': [
          {'field': 'region_id', 'op': 'eq', 'value': regionId},
        ],
      },
    );

    return _readRows(json)
        .whereType<Map>()
        .map((row) => HeroSummary.fromJson(Map<String, dynamic>.from(row)))
        .where((hero) => hero.hasValidId)
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> loadHeroDetail(
    String heroId,
    int regionId,
  ) async {
    final normalizedHeroId = HeroSummary.normalizeId(heroId);
    if (normalizedHeroId == null) {
      throw ArgumentError.value(heroId, 'heroId', 'Must be a positive integer');
    }

    return apiClient.getJson(
      '/hero/$normalizedHeroId',
      query: {'region_id': regionId},
    );
  }

  List<Object?> _readRows(Map<String, dynamic> json) {
    final result = json['result'];

    if (result is Map) {
      final data = result['data'];
      if (data is List) {
        return data;
      }

      final rows = result['rows'];
      if (rows is List) {
        return rows;
      }
    }

    final rows = json['rows'];
    if (rows is List) {
      return rows;
    }

    return const [];
  }
}
