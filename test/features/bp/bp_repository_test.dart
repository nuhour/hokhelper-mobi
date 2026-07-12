import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/config/app_config.dart';
import 'package:hok_helper_mobile/src/core/network/api_client.dart';
import 'package:hok_helper_mobile/src/core/network/api_error.dart';
import 'package:hok_helper_mobile/src/features/bp/data/bp_repository.dart';
import 'package:hok_helper_mobile/src/features/bp/domain/bp_scheme_summary.dart';

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
    if (path == '/bp/scheme/12/update') {
      final data = body is Map ? body['data'] : null;
      if (data is Map && data.containsKey('currentState')) {
        return const {
          'success': true,
          'message': 'success',
          'result': {
            'scheme': {
              'id': '12',
              'name': 'KPL Finals Draft',
              'createdAt': '2026-07-07T11:30:00Z',
              'boMode': 7,
              'teamAName': 'Wolves',
              'teamBName': 'AG',
              'sideSelectionRule': 'loser_selects',
              'gameNumber': 4,
              'history': [
                {'gameNumber': 1, 'winner': 'blue'},
                {'gameNumber': 2, 'winner': 'red'},
              ],
              'currentState': {
                'blueBans': ['mobile-blue-ban-1', 'mobile-blue-ban-2'],
                'redBans': ['mobile-red-ban-1'],
                'bluePicks': ['mobile-blue-pick-1'],
                'redPicks': ['mobile-red-pick-1', 'mobile-red-pick-2'],
                'currentStepIndex': 6,
                'isSaved': true,
              },
            },
          },
        };
      }
      return const {
        'success': true,
        'message': 'success',
        'result': {
          'scheme': {
            'id': '12',
            'name': 'Updated Draft',
            'createdAt': '2026-07-07T11:00:00Z',
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

class _UnauthorizedApiClient extends _FakeApiClient {
  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    requestedPath = path;
    requestedBody = body;
    throw const ApiError(
      kind: ApiErrorKind.authExpired,
      message: 'Authentication credentials were not provided.',
      statusCode: 401,
    );
  }
}

void main() {
  test('treats unauthorized BP scheme list as empty for guests', () async {
    final apiClient = _UnauthorizedApiClient();
    final repository = BpRepository(apiClient: apiClient);

    final schemes = await repository.loadSchemes();

    expect(apiClient.requestedPath, '/bp/scheme');
    expect(schemes, isEmpty);
  });

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
    expect(schemes.single.blueBanHeroIds, [199]);
    expect(schemes.single.redBanHeroIds, [133]);
    expect(schemes.single.bluePickHeroIds, [111]);
    expect(schemes.single.redPickHeroIds, [222]);
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
    expect(scheme.blueBanHeroIds, [199]);
    expect(scheme.redBanHeroIds, [133]);
    expect(scheme.bluePickHeroIds, [111]);
    expect(scheme.redPickHeroIds, [222]);
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

  test('updates a BP scheme with hokx-compatible request wrapper', () async {
    final apiClient = _FakeApiClient();
    final repository = BpRepository(apiClient: apiClient);

    final scheme = await repository.updateScheme(
      '12',
      name: 'Updated Draft',
      boMode: 5,
      teamAName: 'Team Alpha',
      teamBName: 'Team Beta',
      sideSelectionRule: 'alternating',
    );

    expect(apiClient.requestedPath, '/bp/scheme/12/update');
    expect(apiClient.requestedBody, {
      'schemeId': '12',
      'data': {
        'name': 'Updated Draft',
        'boMode': 5,
        'teamAName': 'Team Alpha',
        'teamBName': 'Team Beta',
        'sideSelectionRule': 'alternating',
      },
    });
    expect(scheme.id, '12');
    expect(scheme.name, 'Updated Draft');
    expect(scheme.boModeText, 'BO5');
    expect(scheme.matchupText, 'Team Alpha vs Team Beta');
  });

  test(
    'updates BP draft state with hokx-compatible currentState data',
    () async {
      final apiClient = _FakeApiClient();
      final repository = BpRepository(apiClient: apiClient);

      final scheme = await repository.updateDraftState(
        '12',
        gameNumber: 4,
        currentStepIndex: 6,
        blueBanCount: 2,
        redBanCount: 1,
        bluePickCount: 1,
        redPickCount: 2,
      );

      expect(apiClient.requestedPath, '/bp/scheme/12/update');
      expect(apiClient.requestedBody, {
        'schemeId': '12',
        'data': {
          'gameNumber': 4,
          'currentState': {
            'blueBans': ['mobile-blue-ban-1', 'mobile-blue-ban-2'],
            'redBans': ['mobile-red-ban-1'],
            'bluePicks': ['mobile-blue-pick-1'],
            'redPicks': ['mobile-red-pick-1', 'mobile-red-pick-2'],
            'currentStepIndex': 6,
            'isSaved': true,
          },
        },
      });
      expect(scheme.progressText, 'Game 4 · Step 6');
      expect(scheme.phaseSummaryText, '3 bans · 3 picks');
    },
  );

  test(
    'saves real BP slots and timer state for the landscape editor',
    () async {
      final apiClient = _FakeApiClient();
      final repository = BpRepository(apiClient: apiClient);

      await repository.saveDraftState(
        '12',
        gameNumber: 4,
        draftState: const BpDraftState(
          blueBans: [2624, null, -1, null, null],
          redBans: [2621, null, null, null, null],
          bluePicks: [2610, null, null, null, null],
          redPicks: [2600, null, null, null, null],
          currentStepIndex: 6,
          isStarted: true,
          isSaved: false,
          timeLeft: 31,
        ),
      );

      expect(apiClient.requestedPath, '/bp/scheme/12/update');
      expect(apiClient.requestedBody, {
        'schemeId': '12',
        'data': {
          'gameNumber': 4,
          'currentState': {
            'blueBans': [2624, null, -1, null, null],
            'redBans': [2621, null, null, null, null],
            'bluePicks': [2610, null, null, null, null],
            'redPicks': [2600, null, null, null, null],
            'currentStepIndex': 6,
            'isStarted': true,
            'isSaved': false,
            'timeLeft': 31,
            'gameWinner': null,
          },
        },
      });
    },
  );

  test('deletes a BP scheme with hokx-compatible request body', () async {
    final apiClient = _FakeApiClient();
    final repository = BpRepository(apiClient: apiClient);

    await repository.deleteScheme('12');

    expect(apiClient.requestedPath, '/bp/scheme/12/delete');
    expect(apiClient.requestedBody, {'schemeId': '12'});
  });
}
