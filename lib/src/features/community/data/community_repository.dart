import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../domain/community_post_detail.dart';
import '../domain/community_post_summary.dart';
import '../domain/leak_post_summary.dart';

class CommunityRepository {
  const CommunityRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<List<CommunityPostSummary>> loadPosts(
    int regionId, {
    int page = 1,
    int pageSize = 30,
  }) async {
    final json = await apiClient.getJson(
      '/community/posts',
      query: {
        'page': page,
        'pageSize': pageSize,
        'sort': 'hot',
        'filterRules': jsonEncode([
          {'field': 'region_id', 'op': 'eq', 'value': regionId},
        ]),
      },
    );

    return _readRows(json).map(CommunityPostSummary.fromJson).toList();
  }

  Future<CommunityPostSummary> createPost({
    required String title,
    required String content,
    required List<String> tags,
    required int regionId,
  }) async {
    final json = await apiClient.postJson(
      '/community/posts/create',
      body: {
        'title': title,
        'content': content,
        'tags': tags,
        'region_id': regionId,
      },
    );
    return CommunityPostSummary.fromJson(json);
  }

  Future<void> deletePost(String postId) async {
    await apiClient.postJson('/community/posts/$postId/delete', body: {});
  }

  Future<List<LeakPostSummary>> loadLeaks(
    int regionId, {
    int page = 1,
    int pageSize = 30,
  }) async {
    final json = await apiClient.getJson(
      '/leak/posts',
      query: {
        'page': page,
        'pageSize': pageSize,
        'region_id': regionId,
        'category': 'all',
      },
    );

    return _readRows(json).map(LeakPostSummary.fromJson).toList();
  }

  Future<CommunityPostDetail> loadPostDetail(
    String postId, {
    required int regionId,
  }) async {
    final json = await apiClient.getJson(
      '/community/posts/$postId',
      query: {'region_id': regionId},
    );
    final result = json['result'];
    return CommunityPostDetail.fromJson(result);
  }

  Future<CommunityLikeResult> togglePostLike(String postId) async {
    final json = await apiClient.postJson('/community/posts/$postId/like');
    return CommunityLikeResult.fromJson(json);
  }

  Future<CommunityCommentSummary> createComment(
    String postId, {
    required String content,
    String? parentId,
  }) async {
    final body = <String, Object?>{'content': content};
    if (parentId != null && parentId.isNotEmpty) {
      body['parent'] = parentId;
    }
    final json = await apiClient.postJson(
      '/community/posts/$postId/comments',
      body: body,
    );
    return CommunityCommentSummary.fromJson(json);
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

class CommunityLikeResult {
  const CommunityLikeResult({required this.isLiked, required this.likeCount});

  final bool isLiked;
  final int likeCount;

  factory CommunityLikeResult.fromJson(Map<dynamic, dynamic> json) {
    return CommunityLikeResult(
      isLiked: _readBool(json['liked'] ?? json['is_liked']),
      likeCount: _readInt(json['like_count']),
    );
  }
}

bool _readBool(Object? value) {
  if (value is bool) {
    return value;
  }
  final text = value?.toString().toLowerCase() ?? '';
  return text == 'true' || text == '1' || text == 'yes';
}

int _readInt(Object? value) {
  if (value is int) {
    return value;
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
