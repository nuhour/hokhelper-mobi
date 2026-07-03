import '../../../core/network/api_client.dart';
import '../domain/content_item_summary.dart';

class ContentRepository {
  const ContentRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<List<ContentItemSummary>> loadSkins(int regionId) async {
    final json = await apiClient.postJson(
      '/skin/list',
      body: _pagedRegionBody(regionId),
    );
    return _readRows(
      json,
    ).map(ContentItemSummary.skinFromJson).toList(growable: false);
  }

  Future<List<ContentItemSummary>> loadCgs(int regionId) async {
    final json = await apiClient.postJson(
      '/cg/list',
      body: _pagedRegionBody(regionId),
    );
    return _readRows(
      json,
    ).map(ContentItemSummary.cgFromJson).toList(growable: false);
  }

  Map<String, Object> _pagedRegionBody(int regionId) {
    return {
      'page': 1,
      'pageSize': 20,
      'filterRules': [
        {'field': 'region_id', 'op': 'eq', 'value': regionId},
      ],
    };
  }

  List<Object?> _readRows(Map<String, dynamic> json) {
    final result = json['result'];
    final rows = result is Map
        ? result['rows'] ?? result['data']
        : json['rows'] ?? json['data'];
    if (rows is! List) {
      return const [];
    }

    return rows;
  }
}
