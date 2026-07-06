import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../domain/cg_detail.dart';
import '../domain/content_item_summary.dart';
import '../domain/patch_note_summary.dart';
import '../domain/skin_detail.dart';

class ContentRepository {
  const ContentRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<List<ContentItemSummary>> loadSkins(
    int regionId, {
    int pageSize = 20,
  }) async {
    final json = await apiClient.postJson(
      '/skin/list',
      body: _pagedRegionBody(regionId, pageSize: pageSize),
    );
    return _readRows(
      json,
    ).map(ContentItemSummary.skinFromJson).toList(growable: false);
  }

  Future<SkinDetail> loadSkinDetail(int skinId) async {
    final json = await apiClient.getJson('/skin/$skinId');
    return SkinDetail.fromJson(json['result'] ?? json);
  }

  Future<List<ContentItemSummary>> loadCgs(
    int regionId, {
    int pageSize = 20,
  }) async {
    final json = await apiClient.postJson(
      '/cg/list',
      body: _pagedRegionBody(regionId, pageSize: pageSize),
    );
    return _readRows(
      json,
    ).map(ContentItemSummary.cgFromJson).toList(growable: false);
  }

  Future<CgDetail> loadCgDetail(int cgId) async {
    final json = await apiClient.getJson('/cg/$cgId');
    return CgDetail.fromJson(json['result'] ?? json);
  }

  Future<List<CgCommentSummary>> loadCgComments(int cgId) async {
    final json = await apiClient.getJson(
      '/cg/$cgId/comments',
      query: {'page': 1, 'pageSize': 50, 'order': 'desc'},
    );
    final data = json['data'];
    final result = json['result'];
    final rows = data is Map
        ? data['rows']
        : result is Map
        ? result['rows']
        : json['rows'];
    if (rows is! List) {
      return const [];
    }
    return rows.map(CgCommentSummary.fromJson).toList(growable: false);
  }

  Future<void> createCgComment(int cgId, String content) async {
    await apiClient.postJson(
      '/cg/$cgId/comments',
      body: {'content': content.trim()},
    );
  }

  Future<List<PatchNoteSummary>> loadPatchNotes(int regionId) async {
    final json = await apiClient.getJson(
      '/community/posts',
      query: {
        'page': 1,
        'pageSize': 120,
        'sort': 'new',
        'filterRules': jsonEncode([
          {'field': 'region_id', 'op': 'eq', 'value': regionId},
        ]),
      },
    );

    return _readRows(json)
        .where(isPatchNotePost)
        .map(PatchNoteSummary.fromJson)
        .toList(growable: false);
  }

  Map<String, Object> _pagedRegionBody(int regionId, {int pageSize = 20}) {
    return {
      'page': 1,
      'pageSize': pageSize,
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
