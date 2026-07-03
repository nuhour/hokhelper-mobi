import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../domain/build_scheme_summary.dart';

class BuildsRepository {
  const BuildsRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<List<BuildSchemeSummary>> loadPublicSchemes(int regionId) async {
    final json = await apiClient.getJson(
      '/build/schemes',
      query: {
        'action': 'explore',
        'page': 1,
        'pageSize': 20,
        'filterRules': jsonEncode([
          {'field': 'region_id', 'op': 'eq', 'value': regionId},
        ]),
      },
    );
    final result = json['result'];
    final rows = result is Map ? result['data'] : json['data'];
    if (rows is! List) {
      return const [];
    }

    return rows.map(BuildSchemeSummary.fromJson).toList(growable: false);
  }
}
