import '../../../core/network/api_client.dart';
import '../domain/hero_relationship.dart';
import '../domain/hero_summary.dart';

/// /hero/gallery 单页结果：分页 UI 需要 total 判断是否还有更多。
class HeroGalleryPage {
  const HeroGalleryPage({required this.heroes, this.total});

  final List<HeroSummary> heroes;

  /// 后端未返回 total 时为 null，调用方需回退到行数启发式。
  final int? total;
}

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
    final result = await loadHeroGalleryPage(
      regionId,
      page: page,
      pageSize: pageSize,
      sort: sort,
      order: order,
      search: search,
      lanePosition: lanePosition,
      minRating: minRating,
    );
    return result.heroes;
  }

  Future<HeroGalleryPage> loadHeroGalleryPage(
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

    final heroes = _readRows(json)
        .whereType<Map>()
        .map((row) => HeroSummary.fromJson(Map<String, dynamic>.from(row)))
        .where((hero) => hero.hasValidId)
        .toList(growable: false);
    return HeroGalleryPage(heroes: heroes, total: _readTotal(json));
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

  int? _readTotal(Map<String, dynamic> json) {
    final result = json['result'];
    final total = result is Map ? result['total'] : json['total'];
    if (total is num) {
      return total.toInt();
    }
    if (total is String) {
      return int.tryParse(total);
    }
    return null;
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
