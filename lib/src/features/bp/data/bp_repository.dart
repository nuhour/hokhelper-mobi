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
}
