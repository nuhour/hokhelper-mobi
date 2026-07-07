import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
import 'package:hok_helper_mobile/src/features/bp/data/bp_repository.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient()
    : super(
        config: const AppConfig(
          apiBaseUrl: 'https://example.test',
          apiPrefix: '',
        ),
      );

  String? requestedPath;
  Map<String, dynamic>? requestedQuery;
  Object? requestedBody;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    requestedPath = path;
    requestedQuery = query;
    return const {
      'success': true,
      'message': 'success',
      'result': {
        'id': '12',
        'name': 'KPL Finals Draft',
        'createdAt': '2026-07-03T10:00:00Z',
        'boMode': 7,
        'teamAName': 'Wolves',
        'teamBName': 'AG',
        'gameNumber': 3,
        'history': [
          {'gameNumber': 1, 'winner': 'blue'},
          {'gameNumber': 2, 'winner': 'red'},
        ],
        'currentState': {
          'blueBans': ['199'],
          'redBans': ['133'],
          'bluePicks': ['111'],
          'redPicks': ['222'],
          'currentStepIndex': 4,
        },
      },
    };
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    requestedPath = path;
    requestedBody = body;
    if (path == '/bp/scheme/create') {
      return const {
        'success': true,
        'message': 'success',
        'result': {
          'scheme': {
            'id': '99',
            'name': 'Mobile Draft',
            'createdAt': '2026-07-07T10:00:00Z',
            'boMode': 5,
            'teamAName': 'Team Alpha',
            'teamBName': 'Team Beta',
            'sideSelectionRule': 'alternating',
            'gameNumber': 1,
            'history': [],
            'currentState': {'currentStepIndex': 0},
          },
        },
      };
    }
    return const {
      'success': true,
      'message': 'success',
      'result': {
        'total': 1,
        'schemes': [
          {
            'id': '12',
            'name': 'KPL Finals Draft',
            'createdAt': '2026-07-03T10:00:00Z',
            'boMode': 7,
            'teamAName': 'Wolves',
            'teamBName': 'AG',
            'sideSelectionRule': 'loser_selects',
            'gameNumber': 3,
            'history': [
              {'gameNumber': 1, 'winner': 'blue'},
              {'gameNumber': 2, 'winner': 'red'},
            ],
            'currentState': {
              'blueBans': ['199'],
              'redBans': ['133'],
              'bluePicks': ['111'],
              'redPicks': ['222'],
              'currentStepIndex': 4,
              'isSaved': true,
            },
          },
        ],
      },
    };
  }
}

void main() {
  test('loads BP schemes with backend-compatible POST body', () async {
    final apiClient = _FakeApiClient();
    final repository = BpRepository(apiClient: apiClient);

    final schemes = await repository.loadSchemes();

    expect(apiClient.requestedPath, '/bp/scheme');
    expect(apiClient.requestedBody, {
      'page': 1,
      'pageSize': 20,
      'sort': 'created_at',
      'order': 'desc',
    });
    expect(schemes.single.id, '12');
    expect(schemes.single.name, 'KPL Finals Draft');
    expect(schemes.single.matchupText, 'Wolves vs AG');
    expect(schemes.single.boModeText, 'BO7');
    expect(schemes.single.progressText, 'Game 3 · Step 4');
    expect(schemes.single.historyCountText, '2 games');
  });

  test('loads a BP scheme detail with hokx detail endpoint', () async {
    final apiClient = _FakeApiClient();
    final repository = BpRepository(apiClient: apiClient);

    final scheme = await repository.loadScheme('12');

    expect(apiClient.requestedPath, '/bp/scheme/12');
    expect(apiClient.requestedQuery, isNull);
    expect(scheme.id, '12');
    expect(scheme.name, 'KPL Finals Draft');
    expect(scheme.phaseSummaryText, '2 bans · 2 picks');
  });

  test('creates a BP scheme with hokx-compatible request fields', () async {
    final apiClient = _FakeApiClient();
    final repository = BpRepository(apiClient: apiClient);

    final scheme = await repository.createScheme(
      name: 'Mobile Draft',
      boMode: 5,
      teamAName: 'Team Alpha',
      teamBName: 'Team Beta',
      sideSelectionRule: 'alternating',
    );

    expect(apiClient.requestedPath, '/bp/scheme/create');
    expect(apiClient.requestedBody, {
      'name': 'Mobile Draft',
      'boMode': 5,
      'teamAName': 'Team Alpha',
      'teamBName': 'Team Beta',
      'sideSelectionRule': 'alternating',
    });
    expect(scheme.id, '99');
    expect(scheme.name, 'Mobile Draft');
    expect(scheme.boModeText, 'BO5');
    expect(scheme.matchupText, 'Team Alpha vs Team Beta');
  });
}
