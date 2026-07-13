import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
import 'package:hok_helper_mobile/src/features/esports/data/esports_repository.dart';
import 'package:hok_helper_mobile/src/features/esports/domain/esports_match_summary.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient()
    : super(
        config: const AppConfig(
          apiBaseUrl: 'https://example.test',
          apiPrefix: '',
        ),
      );

  final postBodies = <String, Object?>{};

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    postBodies[path] = body;

    return switch (path) {
      '/esports/matches/list' => const {
        'success': true,
        'data': {
          'total': 1,
          'rows': [
            {
              'id': 10,
              'league_name': 'KPL Spring',
              'stage_name': 'Playoffs',
              'status_key': 'finished',
              'start_time': '2026-06-28T11:00:00Z',
              'bo': 7,
              'winner_team_id': 1,
              'team_a': {
                'id': 1,
                'name': 'Wolves',
                'short_name': 'WOL',
                'logo_url': 'https://example.test/wolves.png',
              },
              'team_b': {
                'id': 2,
                'name': 'AG',
                'short_name': 'AG',
                'logo_url': 'https://example.test/ag.png',
              },
              'score_a': 4,
              'score_b': 3,
            },
          ],
        },
      },
      '/esports/teams/list' => const {
        'success': true,
        'data': {
          'total': 1,
          'rows': [
            {
              'id': 1,
              'name': 'Wolves',
              'short_name': 'WOL',
              'league_name': 'KPL Spring',
              'club': 'Chongqing Wolves',
              'logo_url': 'https://example.test/wolves.png',
              'wins': 12,
              'losses': 3,
              'win_rate': 0.8,
            },
          ],
        },
      },
      '/esports/players/list' => const {
        'success': true,
        'data': {
          'total': 1,
          'rows': [
            {
              'id': 8,
              'name': 'Fly',
              'role': 'Clash Lane',
              'team_name': 'Wolves',
              'team_logo_url': 'https://example.test/wolves.png',
              'avatar_url': 'https://example.test/fly.png',
              'stats_json': {'grade': 91.5, 'kda': 6.8, 'win_rate': 0.76},
            },
          ],
        },
      },
      '/esports/stats/list' => const {
        'success': true,
        'data': {
          'total': 1,
          'rows': [
            {
              'id': 'stat-1',
              'league_name': 'KPL Spring',
              'hero': {
                'hero_name': 'Luban No.7',
                'hero_icon': 'https://example.test/luban.png',
              },
              'player': {'player_name': 'Fly', 'position': 'Clash Lane'},
              'team': {'name': 'Wolves'},
              'stats': {'rank': 1, 'winRate': 0.662, 'kda': 5.4},
              'stats_keys': ['winRate', 'kda'],
            },
          ],
        },
      },
      _ => throw StateError('Unexpected path $path'),
    };
  }
}

void main() {
  test('loads esports matches from the list endpoint', () async {
    final apiClient = _FakeApiClient();
    final repository = EsportsRepository(apiClient: apiClient);

    final matches = await repository.loadMatches();

    expect(apiClient.postBodies['/esports/matches/list'], {
      'page': 1,
      'pageSize': 10,
      'sort': 'start_time',
      'order': 'desc',
    });
    expect(matches, hasLength(1));
    expect(matches.single.leagueName, 'KPL Spring');
    expect(matches.single.stageName, 'Playoffs');
    expect(matches.single.teamAName, 'Wolves');
    expect(matches.single.teamBName, 'AG');
    expect(matches.single.scoreText, '4 - 3');
    expect(matches.single.statusLabel, 'Finished');
    expect(matches.single.bestOf, 7);
    expect(matches.single.boText, 'BO7');
    expect(matches.single.winnerSide, 'a');
  });

  test('uses win camp before scores when resolving match winner side', () {
    final match = EsportsMatchSummary.fromJson(const {
      'id': 11,
      'league_name': 'KPL Spring',
      'stage_name': 'Finals',
      'status_key': 'finished',
      'win_camp': 2,
      'team_a': {'id': 1, 'name': 'Wolves'},
      'team_b': {'id': 2, 'name': 'AG'},
      'score_a': 4,
      'score_b': 3,
    });

    expect(match.winnerSide, 'b');
  });

  test('loads esports teams sorted by win rate', () async {
    final apiClient = _FakeApiClient();
    final repository = EsportsRepository(apiClient: apiClient);

    final teams = await repository.loadTeams();

    expect(apiClient.postBodies['/esports/teams/list'], {
      'page': 1,
      'pageSize': 12,
      'sort': 'win_rate',
      'order': 'desc',
    });
    expect(teams, hasLength(1));
    expect(teams.single.name, 'Wolves');
    expect(teams.single.club, 'Chongqing Wolves');
    expect(teams.single.recordText, '12W / 3L');
    expect(teams.single.winRateText, '80.0%');
  });

  test('loads esports players sorted by grade', () async {
    final apiClient = _FakeApiClient();
    final repository = EsportsRepository(apiClient: apiClient);

    final players = await repository.loadPlayers();

    expect(apiClient.postBodies['/esports/players/list'], {
      'page': 1,
      'pageSize': 12,
      'sort': 'grade',
      'order': 'desc',
    });
    expect(players, hasLength(1));
    expect(players.single.name, 'Fly');
    expect(players.single.teamName, 'Wolves');
    expect(players.single.role, 'Clash Lane');
    expect(players.single.gradeText, '91.5');
    expect(players.single.kdaText, '6.8');
    expect(players.single.winRateText, '76.0%');
  });

  test('loads esports stats sorted by win rate', () async {
    final apiClient = _FakeApiClient();
    final repository = EsportsRepository(apiClient: apiClient);

    final stats = await repository.loadStats();

    expect(apiClient.postBodies['/esports/stats/list'], {
      'page': 1,
      'pageSize': 40,
      'sort': 'winRate',
      'order': 'desc',
      'rank_type': 1,
    });
    expect(stats, hasLength(1));
    expect(stats.single.objectName, 'Luban No.7');
    expect(stats.single.subtitle, 'Wolves · Fly');
    expect(stats.single.leagueName, 'KPL Spring');
    expect(stats.single.rank, 1);
    expect(stats.single.metrics.first.label, 'Win Rate');
    expect(stats.single.metrics.first.value, '66.2%');
  });
}
