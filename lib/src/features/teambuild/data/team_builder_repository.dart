import '../../../core/network/api_client.dart';
import '../domain/team_build_hero.dart';
import '../domain/team_recommendation.dart';

class TeamBuilderRepository {
  const TeamBuilderRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<List<TeamBuildHero>> loadHeroes(int regionId) async {
    final json = await apiClient.postJson(
      '/teambuild/heroes',
      body: {
        'page': 1,
        'pageSize': 200,
        'filterRules': [
          {'field': 'region_id', 'op': 'eq', 'value': regionId},
        ],
      },
    );

    return _readRows(json)
        .map(TeamBuildHero.fromJson)
        .where((hero) => hero.id > 0)
        .toList(growable: false);
  }

  Future<TeamRecommendationResult> loadRecommendations({
    required int regionId,
    List<int> myPicks = const [],
    List<int> enemyPicks = const [],
    List<int> bans = const [],
    TeamRecommendType recommendType = TeamRecommendType.balanced,
    String mySide = 'blue',
    String slotType = 'pick',
    int slotIndex = 0,
    int limit = 10,
    int? mainJob,
    List<int>? blueBans,
    List<int>? redBans,
    List<int>? bluePicks,
    List<int>? redPicks,
    String? activeSide,
    String? activeSlotType,
    int? activeSlotIndex,
  }) async {
    final hasDraftState =
        blueBans != null ||
        redBans != null ||
        bluePicks != null ||
        redPicks != null ||
        activeSide != null ||
        activeSlotType != null ||
        activeSlotIndex != null;
    final resolvedActiveSide = activeSide ?? (mySide == 'red' ? 'red' : 'blue');
    final resolvedSlotType = activeSlotType ?? slotType;
    final resolvedSlotIndex = activeSlotIndex ?? slotIndex;
    final resolvedBlueBans = blueBans ?? (hasDraftState ? const <int>[] : bans);
    final resolvedRedBans = redBans ?? const <int>[];
    final resolvedBluePicks =
        bluePicks ?? (resolvedActiveSide == 'blue' ? myPicks : enemyPicks);
    final resolvedRedPicks =
        redPicks ?? (resolvedActiveSide == 'red' ? myPicks : enemyPicks);
    final resolvedMyPicks = resolvedActiveSide == 'red'
        ? resolvedRedPicks
        : resolvedBluePicks;
    final resolvedEnemyPicks = resolvedActiveSide == 'red'
        ? resolvedBluePicks
        : resolvedRedPicks;
    final body = <String, Object?>{
      'bans': hasDraftState
          ? {...resolvedBlueBans, ...resolvedRedBans}.toList()
          : bans,
      'my_picks': hasDraftState ? resolvedMyPicks : myPicks,
      'enemy_picks': hasDraftState ? resolvedEnemyPicks : enemyPicks,
      'my_side': hasDraftState ? resolvedActiveSide : mySide,
      'slot_type': hasDraftState ? resolvedSlotType : slotType,
      'slot_index': hasDraftState ? resolvedSlotIndex : slotIndex,
      'region_id': regionId,
      // Draft v2 始终返回适配/保护与克制/拆解两组列表，界面只切换本地 Tab。
      'recommend_type': hasDraftState
          ? TeamRecommendType.balanced.apiValue
          : recommendType.apiValue,
      'limit': limit,
      'main_job': ?mainJob,
    };
    if (hasDraftState) {
      body.addAll({
        'blue_bans': resolvedBlueBans,
        'red_bans': resolvedRedBans,
        'blue_picks': resolvedBluePicks,
        'red_picks': resolvedRedPicks,
        'active_side': resolvedActiveSide,
        'active_slot_type': resolvedSlotType,
        'active_slot_index': resolvedSlotIndex,
      });
    }
    final json = await apiClient.postJson('/teambuild/recommend', body: body);
    final data = json['data'];
    final legacyRecommendations = data is Map ? data['recommendations'] : null;
    final fitRecommendations = data is Map ? data['fit_recommendations'] : null;
    final counterRecommendations = data is Map
        ? data['counter_recommendations']
        : null;
    final fit = _readRecommendations(fitRecommendations);
    final legacy = _readRecommendations(legacyRecommendations);
    final primary = legacy.isNotEmpty ? legacy : fit;
    final counter = _readRecommendations(counterRecommendations);
    final sideWinRates = data is Map ? data['side_win_rates'] : null;

    return TeamRecommendationResult(
      recommendations: primary,
      fitRecommendations: fit.isNotEmpty ? fit : primary,
      counterRecommendations: counter,
      sideWinRates: sideWinRates is Map
          ? TeamSideWinRates.fromJson(sideWinRates)
          : null,
      phase: data is Map ? data['phase']?.toString() : null,
      modelVersion: data is Map ? data['model_version']?.toString() : null,
      statsSnapshot: data is Map ? data['stats_snapshot']?.toString() : null,
      hasOwnPickContext: data is Map && data['has_own_pick_context'] == true,
      hasEnemyPickContext:
          data is Map && data['has_enemy_pick_context'] == true,
      counterContextAvailable:
          data is Map && data['counter_context_available'] == true,
    );
  }

  List<TeamRecommendation> _readRecommendations(Object? value) {
    if (value is! List) return const [];
    return value.map(TeamRecommendation.fromJson).toList(growable: false);
  }

  List<Object?> _readRows(Map<String, dynamic> json) {
    final data = json['data'];
    final result = json['result'];
    final rows = data is Map
        ? data['data'] ?? data['rows']
        : result is Map
        ? result['data'] ?? result['rows']
        : json['rows'] ?? json['data'];
    if (rows is! List) {
      return const [];
    }

    return rows;
  }
}
