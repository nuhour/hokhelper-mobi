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
        'pageSize': 80,
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
  }) async {
    final json = await apiClient.postJson(
      '/teambuild/recommend',
      body: {
        'bans': bans,
        'my_picks': myPicks,
        'enemy_picks': enemyPicks,
        'my_side': mySide,
        'slot_type': slotType,
        'slot_index': slotIndex,
        'region_id': regionId,
        'recommend_type': recommendType.apiValue,
        'limit': limit,
      },
    );
    final data = json['data'];
    final recommendations = data is Map ? data['recommendations'] : null;
    final sideWinRates = data is Map ? data['side_win_rates'] : null;

    return TeamRecommendationResult(
      recommendations: recommendations is List
          ? recommendations
                .map(TeamRecommendation.fromJson)
                .toList(growable: false)
          : const [],
      sideWinRates: sideWinRates is Map
          ? TeamSideWinRates.fromJson(sideWinRates)
          : null,
    );
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
