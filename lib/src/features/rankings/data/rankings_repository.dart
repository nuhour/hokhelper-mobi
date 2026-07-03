import '../../../core/network/api_client.dart';
import '../domain/equip_ranking_entry.dart';
import '../domain/hero_ranking_entry.dart';
import '../domain/player_ranking_entry.dart';
import '../domain/tier_list_entry.dart';

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

  Future<List<PlayerRankingEntry>> loadPlayerRanking(
    int regionId, {
    String rankType = 'peak',
    int windowDays = 999,
    int limit = 20,
  }) async {
    final json = await apiClient.getJson(
      '/ranking/players',
      query: {
        'region_id': regionId,
        'rank_type': rankType,
        'window_days': windowDays,
        'limit': limit,
      },
    );
    final data = json['data'];
    final result = json['result'];
    final players = data is Map
        ? data['players']
        : result is Map
        ? result['players'] ?? result['data']
        : json['players'];
    if (players is! List) {
      return const [];
    }

    return players.map(PlayerRankingEntry.fromJson).toList(growable: false);
  }

  Future<List<EquipRankingEntry>> loadEquipRanking({
    String sortBy = 'pick_rate',
    int limit = 20,
  }) async {
    final json = await apiClient.getJson(
      '/ranking/equips',
      query: {'sort_by': sortBy, 'limit': limit},
    );
    final data = json['data'];
    final result = json['result'];
    final equips = data is Map
        ? data['equips']
        : result is Map
        ? result['equips'] ?? result['data']
        : json['equips'];
    if (equips is! List) {
      return const [];
    }

    return equips.map(EquipRankingEntry.fromJson).toList(growable: false);
  }

  Future<List<TierListEntry>> loadTierList(
    int regionId, {
    String source = 'all',
    int windowDays = 999,
  }) async {
    final json = await apiClient.getJson(
      '/ranking/tier-list',
      query: {
        'region_id': regionId,
        'source': source,
        'window_days': windowDays,
      },
    );
    final data = json['data'];
    final result = json['result'];
    final tierList = data is Map
        ? data['tier_list']
        : result is Map
        ? result['tier_list'] ?? result['data']
        : json['tier_list'];
    if (tierList is! List) {
      return const [];
    }

    return tierList.map(TierListEntry.fromJson).toList(growable: false);
  }
}
