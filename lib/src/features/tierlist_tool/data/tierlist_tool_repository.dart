import '../../../core/network/api_client.dart';
import '../domain/tierlist_scheme_summary.dart';

class TierListToolRepository {
  const TierListToolRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<List<TierListSchemeSummary>> loadSchemes() async {
    final json = await apiClient.postJson(
      '/tierlist/schemes',
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

    return schemes.map(TierListSchemeSummary.fromJson).toList(growable: false);
  }

  Future<TierListSchemeSummary> loadScheme(String schemeId) async {
    final json = await apiClient.getJson('/tierlist/schemes/$schemeId');
    final result = json['result'];
    return TierListSchemeSummary.fromJson(result is Map ? result : json);
  }

  Future<TierListSchemeSummary> createScheme({required String name}) async {
    final json = await apiClient.postJson(
      '/tierlist/schemes/create',
      body: {
        'name': name,
        'rows': const [
          {'id': 't0', 'label': 'T0', 'color': 'bg-red-600', 'heroIds': []},
          {'id': 't1', 'label': 'T1', 'color': 'bg-orange-500', 'heroIds': []},
          {'id': 't2', 'label': 'T2', 'color': 'bg-yellow-500', 'heroIds': []},
          {'id': 't3', 'label': 'T3', 'color': 'bg-green-500', 'heroIds': []},
        ],
      },
    );
    final result = json['result'];
    final scheme = result is Map ? result['scheme'] : json['scheme'];
    return TierListSchemeSummary.fromJson(scheme is Map ? scheme : result);
  }

  Future<void> deleteScheme(String schemeId) async {
    await apiClient.postJson(
      '/tierlist/schemes/$schemeId/delete',
      body: <String, Object?>{},
    );
  }
}
