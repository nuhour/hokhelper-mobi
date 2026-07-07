import '../../../core/network/api_client.dart';
import '../domain/bp_scheme_summary.dart';

class BpRepository {
  const BpRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<List<BpSchemeSummary>> loadSchemes() async {
    final json = await apiClient.postJson(
      '/bp/scheme',
      body: const {
        'page': 1,
        'pageSize': 20,
        'sort': 'created_at',
        'order': 'desc',
      },
    );

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
    return BpSchemeSummary.fromJson(result is Map ? result : json);
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

  Future<void> deleteScheme(String schemeId) async {
    await apiClient.postJson(
      '/bp/scheme/$schemeId/delete',
      body: {'schemeId': schemeId},
    );
  }
}
