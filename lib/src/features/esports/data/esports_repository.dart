import '../../../core/network/api_client.dart';
import '../domain/esports_match_summary.dart';
import '../domain/esports_player_summary.dart';
import '../domain/esports_team_summary.dart';

class EsportsRepository {
  const EsportsRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<List<EsportsMatchSummary>> loadMatches() async {
    final json = await apiClient.postJson(
      '/esports/matches/list',
      body: const {
        'page': 1,
        'pageSize': 10,
        'sort': 'start_time',
        'order': 'desc',
      },
    );
    return _readRows(json).map(EsportsMatchSummary.fromJson).toList();
  }

  Future<List<EsportsTeamSummary>> loadTeams() async {
    final json = await apiClient.postJson(
      '/esports/teams/list',
      body: const {
        'page': 1,
        'pageSize': 12,
        'sort': 'win_rate',
        'order': 'desc',
      },
    );
    return _readRows(json).map(EsportsTeamSummary.fromJson).toList();
  }

  Future<List<EsportsPlayerSummary>> loadPlayers() async {
    final json = await apiClient.postJson(
      '/esports/players/list',
      body: const {'page': 1, 'pageSize': 12, 'sort': 'grade', 'order': 'desc'},
    );
    return _readRows(json).map(EsportsPlayerSummary.fromJson).toList();
  }

  List<Object?> _readRows(Map<String, dynamic> json) {
    final result = json['result'];
    final rows = result is Map
        ? result['data'] ?? result['rows'] ?? result['results']
        : json['data'];
    if (rows is! List) {
      return const [];
    }
    return rows;
  }
}
