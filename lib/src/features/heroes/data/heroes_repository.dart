import '../../../core/network/api_client.dart';
import '../domain/hero_relationship.dart';
import '../domain/hero_summary.dart';

class HeroesRepository {
  const HeroesRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<List<HeroSummary>> loadHeroes(
    int regionId, {
    int page = 1,
    int pageSize = 60,
    String sort = 'created_at',
    String order = 'desc',
    String search = '',
    int? lanePosition,
    double minRating = 0,
  }) async {
    final trimmedSearch = search.trim();
    final filterRules = [
      {'field': 'region_id', 'op': 'eq', 'value': regionId},
      if (trimmedSearch.isNotEmpty)
        {'field': 'name', 'op': 'contains', 'value': trimmedSearch, 'ig': true},
      if (lanePosition != null)
        {'field': 'position', 'op': 'eq', 'value': lanePosition},
      if (minRating > 0) {'field': 'rating', 'op': 'gte', 'value': minRating},
    ];

    final json = await apiClient.postJson(
      '/hero/gallery',
      body: {
        'page': page,
        'pageSize': pageSize,
        'sort': sort,
        'order': order,
        'filterRules': filterRules,
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

  Future<List<HeroRelationship>> loadHeroRelationships(int regionId) async {
    final json = await apiClient.postJson(
      '/hero/relationships',
      body: {
        'filterRules': [
          {'field': 'region_id', 'op': 'eq', 'value': regionId},
        ],
      },
    );

    return _readRows(json)
        .whereType<Map>()
        .map((row) => HeroRelationship.fromJson(Map<String, dynamic>.from(row)))
        .where((relationship) {
          return relationship.sourceHeroId.isNotEmpty ||
              relationship.targetHeroId.isNotEmpty ||
              relationship.title.isNotEmpty;
        })
        .toList(growable: false);
  }

  List<Object?> _readRows(Map<String, dynamic> json) {
    final result = json['result'];

    if (result is List) {
      return result;
    }

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
