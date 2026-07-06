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
    int page = 1,
    int pageSize = 20,
    String sort = 'id',
    String order = 'desc',
    String search = '',
    double minRating = 0,
    int? lanePosition,
  }) async {
    final filterRules = _skinFilterRules(
      regionId,
      search: search,
      minRating: minRating,
      lanePosition: lanePosition,
    );
    final json = await apiClient.postJson(
      '/skin/list',
      body: {
        'page': page,
        'pageSize': pageSize,
        'filterRules': filterRules,
        'sort': sort,
        'order': order == 'asc' ? 'asc' : 'desc',
      },
    );
    return _readRows(
      json,
    ).map(ContentItemSummary.skinFromJson).toList(growable: false);
  }

  Future<SkinDetail> loadSkinDetail(int skinId) async {
    final json = await apiClient.getJson('/skin/$skinId');
    return SkinDetail.fromJson(json['result'] ?? json);
  }

  Future<SkinRatingResult> rateSkin(int skinId, double rating) async {
    final normalizedRating = (rating.clamp(0.5, 5) * 2).round() / 2;
    final json = await apiClient.postJson(
      '/skin/$skinId/rate',
      body: {'rating': normalizedRating},
    );
    return SkinRatingResult.fromJson(json['result'] ?? json);
  }

  Future<List<ContentItemSummary>> loadCgs(
    int regionId, {
    int page = 1,
    int pageSize = 20,
    String sort = 'updated_at',
    String order = 'desc',
    String search = '',
    int? heroId,
  }) async {
    final filterRules = _cgFilterRules(
      regionId,
      search: search,
      heroId: heroId,
    );
    final json = await apiClient.postJson(
      '/cg/list',
      body: {
        'page': page,
        'pageSize': pageSize,
        'filterRules': filterRules,
        'sort': sort,
        'order': order == 'asc' ? 'asc' : 'desc',
      },
    );
    return _readRows(
      json,
    ).map(ContentItemSummary.cgFromJson).toList(growable: false);
  }

  Future<CgDetail> loadCgDetail(int cgId) async {
    final json = await apiClient.getJson('/cg/$cgId');
    return CgDetail.fromJson(json['result'] ?? json);
  }

  Future<List<CgCommentSummary>> loadCgComments(
    int cgId, {
    String order = 'desc',
  }) async {
    final normalizedOrder = order == 'asc' ? 'asc' : 'desc';
    final json = await apiClient.getJson(
      '/cg/$cgId/comments',
      query: {'page': 1, 'pageSize': 50, 'order': normalizedOrder},
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

  Future<int> recordCgView(int cgId) async {
    final json = await apiClient.postJson(
      '/cg/$cgId/view',
      body: const <String, Object?>{},
    );
    final result = json['result'];
    final source = result is Map ? result : json;
    return _readInt(source['view_count'] ?? source['viewCount']);
  }

  Future<CgRatingResult> rateCg(int cgId, double rating) async {
    final normalizedRating = (rating.clamp(0.5, 5) * 2).round() / 2;
    final json = await apiClient.postJson(
      '/cg/$cgId/rate',
      body: {'rating': normalizedRating},
    );
    return CgRatingResult.fromJson(json['result'] ?? json);
  }

  Future<List<PatchNoteSummary>> loadPatchNotes(
    int regionId, {
    int page = 1,
    int pageSize = 120,
  }) async {
    final json = await apiClient.getJson(
      '/community/posts',
      query: {
        'page': page,
        'pageSize': pageSize,
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

  Future<PatchNoteSummary> loadPatchNoteDetail(
    int noteId, {
    required int regionId,
  }) async {
    final json = await apiClient.getJson(
      '/community/posts/$noteId',
      query: {'region_id': regionId},
    );
    final result = json['result'];
    final resultMap = result is Map ? result : json;
    return PatchNoteSummary.fromJson(resultMap['post'] ?? resultMap);
  }

  List<Map<String, Object>> _skinFilterRules(
    int regionId, {
    String search = '',
    double minRating = 0,
    int? lanePosition,
  }) {
    final trimmedSearch = search.trim();
    return [
      {'field': 'region_id', 'op': 'eq', 'value': regionId},
      if (trimmedSearch.isNotEmpty) ...[
        {'field': 'name', 'op': 'contains', 'value': trimmedSearch, 'ig': true},
        {
          'field': 'hero_name',
          'op': 'contains',
          'value': trimmedSearch,
          'ig': true,
        },
      ],
      if (minRating > 0) {'field': 'rating', 'op': 'gte', 'value': minRating},
      if (lanePosition != null)
        {'field': 'hero_position', 'op': 'eq', 'value': lanePosition},
    ];
  }

  List<Map<String, Object>> _cgFilterRules(
    int regionId, {
    String search = '',
    int? heroId,
  }) {
    final trimmedSearch = search.trim();
    return [
      {'field': 'region_id', 'op': 'eq', 'value': regionId},
      if (heroId != null) {'field': 'hero_id', 'op': 'eq', 'value': heroId},
      if (trimmedSearch.isNotEmpty) ...[
        {
          'field': 'title1_key',
          'op': 'contains',
          'value': trimmedSearch,
          'ig': true,
        },
        {
          'field': 'hero_name',
          'op': 'contains',
          'value': trimmedSearch,
          'ig': true,
        },
      ],
    ];
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

class CgRatingResult {
  const CgRatingResult({required this.rating, required this.ratingCount});

  final double rating;
  final int ratingCount;

  factory CgRatingResult.fromJson(Object? json) {
    final map = json is Map ? json : const <String, Object?>{};
    return CgRatingResult(
      rating: _readDouble(map['avg_rating'] ?? map['rating']),
      ratingCount: _readInt(map['rating_count'] ?? map['ratingCount']),
    );
  }
}

class SkinRatingResult {
  const SkinRatingResult({required this.rating, required this.ratingCount});

  final double rating;
  final int ratingCount;

  factory SkinRatingResult.fromJson(Object? json) {
    final map = json is Map ? json : const <String, Object?>{};
    return SkinRatingResult(
      rating: _readDouble(map['avg_rating'] ?? map['rating']),
      ratingCount: _readInt(map['rating_count'] ?? map['ratingCount']),
    );
  }
}

int _readInt(Object? value) {
  if (value is int) {
    return value;
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _readDouble(Object? value) {
  if (value is double) {
    return value;
  }
  if (value is int) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
