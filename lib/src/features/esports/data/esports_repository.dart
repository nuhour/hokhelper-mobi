import '../../../core/network/api_client.dart';
import '../domain/esports_detail.dart';
import '../domain/esports_match_summary.dart';
import '../domain/esports_meta.dart';
import '../domain/esports_player_summary.dart';
import '../domain/esports_stat_summary.dart';
import '../domain/esports_team_summary.dart';

/// 分页接口的单页结果；[total] 缺失时调用方需回退到行数启发式。
class EsportsMatchesPage {
  const EsportsMatchesPage({required this.matches, this.total});

  final List<EsportsMatchSummary> matches;
  final int? total;
}

class EsportsStatsPage {
  const EsportsStatsPage({required this.stats, this.total});

  final List<EsportsStatSummary> stats;
  final int? total;
}

class EsportsRepository {
  const EsportsRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<EsportsMeta> loadMeta() async {
    final json = await apiClient.getJson('/esports/meta');
    final data = json['data'] ?? json['result'];
    return EsportsMeta.fromJson(data);
  }

  Future<List<EsportsMatchSummary>> loadMatches({String? league}) async {
    final result = await loadMatchesPage(league: league);
    return result.matches;
  }

  Future<EsportsMatchesPage> loadMatchesPage({
    String? league,
    int page = 1,
    // 后端 list_matches 的 pageSize 上限即 200。
    int pageSize = 200,
  }) async {
    final json = await apiClient.postJson(
      '/esports/matches/list',
      body: {
        'page': page,
        'pageSize': pageSize,
        'sort': 'start_time',
        'order': 'desc',
        if (league != null && league != 'all') 'league': league,
      },
    );
    return EsportsMatchesPage(
      matches: _readRows(json).map(EsportsMatchSummary.fromJson).toList(),
      total: _readTotal(json),
    );
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

  Future<EsportsTeamDetail> loadTeamDetail(String teamId) async {
    final json = await apiClient.getJson('/esports/teams/$teamId');
    return EsportsTeamDetail.fromJson(json['data'] ?? json['result']);
  }

  Future<EsportsPlayerDetail> loadPlayerDetail(String playerId) async {
    final json = await apiClient.getJson('/esports/players/$playerId');
    return EsportsPlayerDetail.fromJson(json['data'] ?? json['result']);
  }

  Future<List<EsportsStatSummary>> loadStats({
    int rankType = 1,
    String? league,
    int regionId = 2,
  }) async {
    final result = await loadStatsPage(
      rankType: rankType,
      league: league,
      regionId: regionId,
    );
    return result.stats;
  }

  Future<EsportsStatsPage> loadStatsPage({
    int rankType = 1,
    String? league,
    int regionId = 2,
    int page = 1,
    // 后端 list_stats 的 pageSize 上限即 500。
    int pageSize = 500,
  }) async {
    final json = await apiClient.postJson(
      '/esports/stats/list',
      body: {
        'page': page,
        'pageSize': pageSize,
        'sort': 'winRate',
        'order': 'desc',
        'rank_type': rankType,
        'region_id': regionId,
        if (league != null && league != 'all') 'league': league,
      },
    );
    // fallbackRank 需按已翻过的页数偏移，保证追加页的名次连续。
    final rankOffset = (page - 1) * pageSize;
    return EsportsStatsPage(
      stats: _readRows(json).indexed
          .map(
            (entry) => EsportsStatSummary.fromJson(
              entry.$2,
              fallbackRank: rankOffset + entry.$1 + 1,
            ),
          )
          .toList(),
      total: _readTotal(json),
    );
  }

  int? _readTotal(Map<String, dynamic> json) {
    final envelope = json['result'] ?? json['data'];
    final total = envelope is Map ? envelope['total'] : null;
    if (total is num) {
      return total.toInt();
    }
    if (total is String) {
      return int.tryParse(total);
    }
    return null;
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
