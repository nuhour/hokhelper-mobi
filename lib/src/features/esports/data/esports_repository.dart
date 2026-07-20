import '../../../core/network/api_client.dart';
import '../domain/esports_match_summary.dart';
import '../domain/esports_meta.dart';
import '../domain/esports_player_summary.dart';
import '../domain/esports_stat_summary.dart';
import '../domain/esports_team_summary.dart';

class EsportsRepository {
  const EsportsRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<EsportsMeta> loadMeta() async {
    final json = await apiClient.getJson('/esports/meta');
    final data = json['data'] ?? json['result'];
    return EsportsMeta.fromJson(data);
  }

  Future<List<EsportsMatchSummary>> loadMatches({String? league}) async {
    final json = await apiClient.postJson(
      '/esports/matches/list',
      body: {
        'page': 1,
        'pageSize': 200,
        'sort': 'start_time',
        'order': 'desc',
        if (league != null && league != 'all') 'league': league,
      },
    );
    return _readRows(json).map(EsportsMatchSummary.fromJson).toList();
  }

  Future<List<EsportsTeamSummary>> loadTeams({String? league}) async {
    final json = await apiClient.postJson(
      '/esports/teams/list',
      body: {
        'page': 1,
        'pageSize': 200,
        'sort': 'win_rate',
        'order': 'desc',
        if (league != null && league != 'all') 'league': league,
      },
    );
    return _readRows(json).map(EsportsTeamSummary.fromJson).toList();
  }

  Future<List<EsportsPlayerSummary>> loadPlayers({String? league}) async {
    final json = await apiClient.postJson(
      '/esports/players/list',
      body: {
        'page': 1,
        'pageSize': 200,
        'sort': 'grade',
        'order': 'desc',
        if (league != null && league != 'all') 'league': league,
      },
    );
    return _readRows(json).map(EsportsPlayerSummary.fromJson).toList();
  }

  Future<List<EsportsStatSummary>> loadStats({
    int rankType = 1,
    String? league,
    int regionId = 2,
  }) async {
    final json = await apiClient.postJson(
      '/esports/stats/list',
      body: {
        'page': 1,
        'pageSize': 500,
        'sort': 'winRate',
        'order': 'desc',
        'rank_type': rankType,
        'region_id': regionId,
        if (league != null && league != 'all') 'league': league,
      },
    );
    return _readRows(json).indexed
        .map(
          (entry) =>
              EsportsStatSummary.fromJson(entry.$2, fallbackRank: entry.$1 + 1),
        )
        .toList();
  }

  List<Object?> _readRows(Map<String, dynamic> json) {
    final envelope = json['result'] ?? json['data'];
    final rows = envelope is Map
        ? envelope['data'] ?? envelope['rows'] ?? envelope['results']
        : envelope;
    if (rows is! List) {
      return const [];
    }
    return rows;
  }
}
