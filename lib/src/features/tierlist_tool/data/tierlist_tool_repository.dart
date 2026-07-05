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
}
