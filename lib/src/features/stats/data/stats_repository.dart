import '../../../core/network/api_client.dart';
import '../domain/hero_trend_row.dart';
import '../domain/stats_dashboard.dart';
import '../domain/stats_trends.dart';

class StatsRepository {
  const StatsRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<StatsDashboard> loadDashboard({
    required String regionCode,
    StatsDashboardEntry entry = StatsDashboardEntry.overview,
  }) async {
    if (entry == StatsDashboardEntry.playerRank) {
      final players = await _loadRows(
        dimension: 'player_rank',
        view: 'peak',
        regionCode: regionCode,
        mapper: StatsPlayerRow.fromJson,
      );
      return StatsDashboard(players: players.cast<StatsPlayerRow>());
    }

    final heroTable = _heroTableFor(entry);
    final equipView = _equipViewFor(entry);
    final results = await Future.wait([
      _loadRows(
        dimension: heroTable.dimension,
        view: heroTable.view,
        regionCode: regionCode,
        mapper: StatsHeroRow.fromJson,
      ),
      _loadRows(
        dimension: 'equip_rank',
        view: equipView,
        regionCode: regionCode,
        mapper: StatsEquipRow.fromJson,
      ),
      _loadRows(
        dimension: 'hero_combo',
        view: 'synergy',
        regionCode: regionCode,
        mapper: StatsComboRow.fromJson,
      ),
    ]);

    return StatsDashboard(
      heroes: results[0].cast<StatsHeroRow>(),
      equips: results[1].cast<StatsEquipRow>(),
      combos: results[2].cast<StatsComboRow>(),
    );
  }

  Future<List<HeroTrendRow>> loadHeroTrends({
    required String regionCode,
  }) async {
    final json = await apiClient.getJson(
      '/stats/table',
      query: {
        'dimension': 'hero_rank',
        'baseline': 'peak_1000',
        'view': 'base',
        'region': regionCode,
        'window_days': 30,
      },
    );
    return _readRows(json)
        .map(HeroTrendRow.fromJson)
        .where((row) {
          return row.id > 0 && row.name.isNotEmpty;
        })
        .toList(growable: false);
  }

  Future<StatsTrendTable> loadTrendTable({
    required StatsTrendQuery query,
    required String regionCode,
  }) async {
    final request = <String, dynamic>{
      'dimension': query.dimension,
      'baseline': query.baseline,
      'view': query.view,
      'window_days': query.windowDays,
      'snapshot_date': query.snapshotDate,
      'region': query.region,
      'equip_type': query.equipType,
      'lang': regionCode,
      'lite': 1,
    }..removeWhere((key, value) => value == null || value == '');
    final json = await apiClient.getJson('/stats/table', query: request);
    return StatsTrendTable.fromJson(json['data'] ?? json['result'] ?? json);
  }

  Future<StatsTrendDetail> loadTrendDetail({
    required StatsTrendDetailRequest request,
    required String regionCode,
  }) async {
    final row = request.row;
    final query = request.query;
    final requestQuery = <String, dynamic>{
      if (row.kind == 'equip') 'equip_id': int.tryParse(row.id),
      if (row.kind == 'hero') 'hero_id': int.tryParse(row.id),
      'baseline': query.baseline == 'all' ? 'peak_1000' : query.baseline,
      'window_days': query.windowDays,
      'snapshot_date': query.snapshotDate,
      'region': query.region.isNotEmpty ? query.region : regionCode,
      'lang': regionCode,
    }..removeWhere((key, value) => value == null || value == '');
    final json = await apiClient.getJson(
      '/stats/hero-combos',
      query: requestQuery,
    );
    return StatsTrendDetail.fromJson(json['data'] ?? json['result'] ?? json);
  }

  Future<StatsEquipDetail> loadEquipDetail({
    required String equipId,
    required String regionCode,
  }) async {
    final parsedEquipId = int.tryParse(equipId);
    final query = <String, dynamic>{
      'equip_id': parsedEquipId,
      'baseline': 'peak_1000',
      'region': regionCode,
    }..removeWhere((key, value) => value == null);
    final json = await apiClient.getJson('/stats/hero-combos', query: query);
    return StatsEquipDetail.fromJson(json['data'] ?? json['result'] ?? json);
  }

  Future<StatsHeroDetail> loadHeroDetail({
    required String heroId,
    required String regionCode,
  }) async {
    final parsedHeroId = int.tryParse(heroId);
    final query = <String, dynamic>{
      'hero_id': parsedHeroId,
      'baseline': 'peak_1000',
      'region': regionCode,
    }..removeWhere((key, value) => value == null);
    final json = await apiClient.getJson('/stats/hero-combos', query: query);
    return StatsHeroDetail.fromJson(json['data'] ?? json['result'] ?? json);
  }

  Future<List<T>> _loadRows<T>({
    required String dimension,
    required String view,
    required String regionCode,
    required T Function(Object? json) mapper,
  }) async {
    final json = await apiClient.getJson(
      '/stats/table',
      query: {
        'dimension': dimension,
        'baseline': 'peak_1000',
        'view': view,
        'region': regionCode,
        'lite': 1,
      },
    );
    final rows = _readRows(json);
    return rows.map(mapper).toList(growable: false);
  }

  List<Object?> _readRows(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map && data['rows'] is List) {
      return List<Object?>.from(data['rows'] as List);
    }

    final result = json['result'];
    if (result is Map && result['rows'] is List) {
      return List<Object?>.from(result['rows'] as List);
    }

    if (json['rows'] is List) {
      return List<Object?>.from(json['rows'] as List);
    }

    return const [];
  }
}

({String dimension, String view}) _heroTableFor(StatsDashboardEntry entry) {
  return switch (entry) {
    StatsDashboardEntry.tierRank => (dimension: 'tier_rank', view: 'main'),
    StatsDashboardEntry.powerRank => (dimension: 'power_rank', view: 'main'),
    _ => (dimension: 'hero_rank', view: 'base'),
  };
}

String _equipViewFor(StatsDashboardEntry entry) {
  return switch (entry) {
    StatsDashboardEntry.equipRank => 'main',
    _ => 'base',
  };
}
