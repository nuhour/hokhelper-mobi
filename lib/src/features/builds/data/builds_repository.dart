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
    return _readRows(
      json,
    ).map(BuildSchemeSummary.fromJson).toList(growable: false);
  }

  Future<List<BuildSchemeSummary?>> loadUserHeroSlots({
    required int heroId,
    required int regionId,
  }) async {
    final json = await apiClient.getJson(
      '/build/schemes',
      query: {
        'action': 'mySchemes',
        'page': 1,
        'pageSize': 3,
        'filterRules': jsonEncode([
          {'field': 'hero__heroId', 'op': 'eq', 'value': heroId},
          {'field': 'region_id', 'op': 'eq', 'value': regionId},
        ]),
      },
    );
    final slots = <BuildSchemeSummary?>[null, null, null];
    for (final scheme in _readRows(json).map(BuildSchemeSummary.fromJson)) {
      final index = scheme.slotIndex;
      if (index >= 1 && index <= 3) {
        slots[index - 1] = scheme;
      }
    }
    return slots;
  }

  List<Object?> _readRows(Map<String, dynamic> json) {
    final result = json['result'];
    if (result is List) {
      return result;
    }
    if (result is Map) {
      final data = result['data'];
      if (data is List) {
        return data;
      }
      final schemes = result['schemes'];
      if (schemes is List) {
        return schemes;
      }
      final rows = result['rows'];
      if (rows is List) {
        return rows;
      }
    }
    final data = json['data'];
    if (data is List) {
      return data;
    }
    final schemes = json['schemes'];
    if (schemes is List) {
      return schemes;
    }
    return const [];
  }
}
