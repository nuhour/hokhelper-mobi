import '../../../core/network/api_client.dart';
import '../domain/hero_trend_row.dart';
import '../domain/stats_dashboard.dart';

class StatsRepository {
  const StatsRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<StatsDashboard> loadDashboard({
    required String regionCode,
    StatsDashboardEntry entry = StatsDashboardEntry.overview,
  }) async {
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
