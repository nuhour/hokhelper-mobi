import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../domain/bp_scheme_summary.dart';

class BpRepository {
  const BpRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<List<BpSchemeSummary>> loadSchemes() async {
    final Map<String, dynamic> json;
    try {
      json = await apiClient.postJson(
        '/bp/scheme',
        body: const {
          'page': 1,
          'pageSize': 20,
          'sort': 'created_at',
          'order': 'desc',
        },
      );
    } on ApiError catch (error) {
      if (_isGuestReadableListError(error)) {
        return const [];
      }
      rethrow;
    }

    final result = json['result'];
    final schemes = result is Map ? result['schemes'] : json['schemes'];
    if (schemes is! List) {
      return const [];
    }

    return schemes.map(BpSchemeSummary.fromJson).toList(growable: false);
  }

  Future<BpSchemeSummary> loadScheme(String schemeId) async {
    final json = await apiClient.getJson('/bp/scheme/$schemeId');
    final result = json['result'];
    // Detail responses are wrapped as result.scheme, while legacy responses
    // may expose the scheme directly. Unwrap the canonical HOKX envelope so
    // the editor retains the scheme ID for later save requests.
    final scheme = result is Map ? result['scheme'] : json['scheme'];
    return BpSchemeSummary.fromJson(scheme is Map ? scheme : result ?? json);
  }

  Future<BpSchemeSummary> createScheme({
    required String name,
    required int boMode,
    required String teamAName,
    required String teamBName,
    required String sideSelectionRule,
  }) async {
    final json = await apiClient.postJson(
      '/bp/scheme/create',
      body: {
        'name': name,
        'boMode': boMode,
        'teamAName': teamAName,
        'teamBName': teamBName,
        'sideSelectionRule': sideSelectionRule,
      },
    );
    final result = json['result'];
    final scheme = result is Map ? result['scheme'] : json['scheme'];
    return BpSchemeSummary.fromJson(scheme is Map ? scheme : result);
  }

  Future<BpSchemeSummary> updateScheme(
    String schemeId, {
    required String name,
    required int boMode,
    required String teamAName,
    required String teamBName,
    required String sideSelectionRule,
  }) async {
    final json = await apiClient.postJson(
      '/bp/scheme/$schemeId/update',
      body: {
        'schemeId': schemeId,
        'data': {
          'name': name,
          'boMode': boMode,
          'teamAName': teamAName,
          'teamBName': teamBName,
          'sideSelectionRule': sideSelectionRule,
        },
      },
    );
    final result = json['result'];
    final scheme = result is Map ? result['scheme'] : json['scheme'];
    return BpSchemeSummary.fromJson(scheme is Map ? scheme : result);
  }

  Future<BpSchemeSummary> updateDraftState(
    String schemeId, {
    required int gameNumber,
    required int currentStepIndex,
    required int blueBanCount,
    required int redBanCount,
    required int bluePickCount,
    required int redPickCount,
  }) async {
    final json = await apiClient.postJson(
      '/bp/scheme/$schemeId/update',
      body: {
        'schemeId': schemeId,
        'data': {
          'gameNumber': gameNumber,
          'currentState': {
            'blueBans': _mobileDraftSlots('mobile-blue-ban', blueBanCount),
            'redBans': _mobileDraftSlots('mobile-red-ban', redBanCount),
            'bluePicks': _mobileDraftSlots('mobile-blue-pick', bluePickCount),
            'redPicks': _mobileDraftSlots('mobile-red-pick', redPickCount),
            'currentStepIndex': currentStepIndex,
            'isSaved': true,
          },
        },
      },
    );
    final result = json['result'];
    final scheme = result is Map ? result['scheme'] : json['scheme'];
    return BpSchemeSummary.fromJson(scheme is Map ? scheme : result);
  }

  Future<BpSchemeSummary> saveDraftState(
    String schemeId, {
    required int gameNumber,
    required BpDraftState draftState,
  }) async {
    final json = await apiClient.postJson(
      '/bp/scheme/$schemeId/update',
      body: {
        'schemeId': schemeId,
        'data': {'gameNumber': gameNumber, 'currentState': draftState.toJson()},
      },
    );
    final result = json['result'];
    final scheme = result is Map ? result['scheme'] : json['scheme'];
    return BpSchemeSummary.fromJson(scheme is Map ? scheme : result);
  }

  Future<BpSchemeSummary> advanceSeries(
    String schemeId, {
    required int nextGameNumber,
    required List<BpHistoryGame> history,
  }) async {
    final json = await apiClient.postJson(
      '/bp/scheme/$schemeId/update',
      body: {
        'schemeId': schemeId,
        'data': {
          'gameNumber': nextGameNumber,
          'history': history.map((game) => game.toJson()).toList(),
          'currentState': null,
        },
      },
    );
    final result = json['result'];
    final scheme = result is Map ? result['scheme'] : json['scheme'];
    return BpSchemeSummary.fromJson(scheme is Map ? scheme : result);
  }

  Future<void> deleteScheme(String schemeId) async {
    await apiClient.postJson(
      '/bp/scheme/$schemeId/delete',
      body: {'schemeId': schemeId},
    );
  }
}

bool _isGuestReadableListError(ApiError error) {
  return error.kind == ApiErrorKind.authExpired ||
      error.kind == ApiErrorKind.forbidden;
}

List<String> _mobileDraftSlots(String prefix, int count) {
  final normalized = count.clamp(0, 5);
  return List.generate(normalized, (index) => '$prefix-${index + 1}');
}
