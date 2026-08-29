import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/providers/core_providers.dart';
import '../domain/community_post_detail.dart';
import '../domain/community_post_summary.dart';
import '../domain/community_sticker.dart';
import '../domain/leak_post_summary.dart';

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return CommunityRepository(apiClient: ref.watch(apiClientProvider));
});

enum CommunityPostSort {
  newest('new'),
  oldest('old'),
  hot('hot');

  const CommunityPostSort(this.backendValue);

  final String backendValue;
}

class CommunityRepository {
  CommunityRepository({required this.apiClient});

  final ApiClient apiClient;
  final Map<String, CommunityLikeResult> _postLikeOverrides = {};
  final Map<String, Map<String, CommunityCommentSummary>>
  _postCommentOverrides = {};

  Future<List<CommunityPostSummary>> loadPosts(
    int regionId, {
    int page = 1,
    int pageSize = 30,
    String search = '',
    String tag = '',
    CommunityPostSort sort = CommunityPostSort.newest,
  }) async {
    final trimmedSearch = search.trim();
    final trimmedTag = tag.trim();
    final json = await apiClient.getJson(
      '/community/posts',
      query: {
        'page': page,
        'pageSize': pageSize,
        'sort': sort.backendValue,
        if (trimmedSearch.isNotEmpty) 'search': trimmedSearch,
        if (trimmedTag.isNotEmpty) 'tag': trimmedTag,
        'filterRules': jsonEncode([
          {'field': 'region_id', 'op': 'eq', 'value': regionId},
        ]),
      },
    );

    return _readRows(
      json,
    ).map(CommunityPostSummary.fromJson).map(_applyLikeOverride).toList();
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
    final post = CommunityPostSummary.fromJson(_unwrapResult(json));
    if (post.id.isEmpty) {
      throw const FormatException('Post creation returned no post id');
    }
    return post;
  }

  Future<List<String>> loadPostTags(int regionId) async {
    final json = await apiClient.getJson(
      '/community/tags',
      query: {
        'region_id': regionId,
        'filterRules': jsonEncode([
          {'field': 'region_id', 'op': 'eq', 'value': regionId},
        ]),
      },
    );
    final result = json['result'];
    final values = result is List
        ? result
        : json['rows'] is List
        ? json['rows'] as List
        : json['data'] is List
        ? json['data'] as List
        : const <Object?>[];
    return values
        .map((value) => value?.toString().trim() ?? '')
        .where((value) => value.isNotEmpty && value.toLowerCase() != 'all')
        .toSet()
        .toList(growable: false);
  }

  Future<List<CommunitySticker>> loadStickers(
    int regionId, {
    String keyword = '',
    int pageSize = 48,
  }) async {
    final json = await apiClient.getJson(
      '/community/stickers',
      query: {
        'page': 1,
        'pageSize': pageSize,
        'region_id': regionId,
        if (keyword.trim().isNotEmpty) 'keyword': keyword.trim(),
      },
    );
    return _readRows(json)
        .map(CommunitySticker.fromJson)
        .where((sticker) => sticker.imageUrl.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> deletePost(String postId) async {
    await apiClient.postJson('/community/posts/$postId/delete', body: {});
  }

  Future<List<LeakPostSummary>> loadLeaks(
    int regionId, {
    int page = 1,
    int pageSize = 30,
    String category = 'all',
    String platform = 'all',
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
      'region_id': regionId,
      'category': category.trim().isEmpty ? 'all' : category.trim(),
    };
    final platformValue = platform.trim();
    if (platformValue.isNotEmpty && platformValue != 'all') {
      query['platform'] = platformValue;
    }
    final json = await apiClient.getJson('/leak/posts', query: query);

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
    final detail = CommunityPostDetail.fromJson(result is Map ? result : json);
    return _applyDetailOverrides(postId, detail);
  }

  Future<CommunityLikeResult> togglePostLike(String postId) async {
    final json = await apiClient.postJson('/community/posts/$postId/like');
    final result = CommunityLikeResult.fromJson(_unwrapResult(json));
    _postLikeOverrides[postId] = result;
    return result;
  }

  CommunityPostSummary _applyLikeOverride(CommunityPostSummary post) {
    final override = _postLikeOverrides[post.id];
    return override == null
        ? post
        : post.copyWith(
            likeCount: override.likeCount,
            isLiked: override.isLiked,
          );
  }

  Future<void> reportPost(
    String postId, {
    required String reason,
    String details = '',
  }) async {
    await apiClient.postJson(
      '/community/posts/$postId/report',
      body: {'reason': reason, 'details': details.trim()},
    );
  }

  Future<void> reportComment(
    String commentId, {
    required String reason,
    String details = '',
  }) async {
    await apiClient.postJson(
      '/community/comments/$commentId/report',
      body: {'reason': reason, 'details': details.trim()},
    );
  }

  Future<void> setUserBlocked(int userId, {required bool blocked}) async {
    await apiClient.postJson(
      '/community/users/$userId/block',
      body: {'blocked': blocked},
    );
  }

  Future<List<CommunityBlockedUser>> loadBlockedUsers() async {
    final json = await apiClient.getJson('/community/blocked-users');
    return _readRows(json)
        .whereType<Map>()
        .map((row) => CommunityBlockedUser.fromJson(row))
        .where((user) => user.id > 0)
        .toList(growable: false);
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
    final comment = CommunityCommentSummary.fromJson(_unwrapResult(json));
    if (comment.id.isEmpty || comment.content.isEmpty) {
      throw const FormatException('Comment creation returned invalid data');
    }
    rememberCreatedComment(postId, comment);
    return comment;
  }

  void rememberCreatedComment(String postId, CommunityCommentSummary comment) {
    final comments = _postCommentOverrides.putIfAbsent(
      postId,
      () => <String, CommunityCommentSummary>{},
    );
    comments[comment.id] = comment;
  }

  CommunityPostDetail _applyDetailOverrides(
    String postId,
    CommunityPostDetail detail,
  ) {
    final comments = _mergeCommentOverrides(postId, detail.comments);
    final commentCount = comments.length > detail.post.commentCount
        ? comments.length
        : detail.post.commentCount;
    final likeOverride = _postLikeOverrides[postId];
    var post = detail.post;
    if (commentCount != detail.post.commentCount) {
      post = post.copyWith(commentCount: commentCount);
    }
    if (likeOverride != null) {
      post = post.copyWith(
        likeCount: likeOverride.likeCount,
        isLiked: likeOverride.isLiked,
      );
    }
    if (identical(post, detail.post) && identical(comments, detail.comments)) {
      return detail;
    }
    return detail.copyWith(
      post: post,
      comments: comments,
      isLiked: likeOverride?.isLiked ?? detail.isLiked,
    );
  }

  List<CommunityCommentSummary> _mergeCommentOverrides(
    String postId,
    List<CommunityCommentSummary> comments,
  ) {
    final pending = _postCommentOverrides[postId];
    if (pending == null || pending.isEmpty) return comments;

    final merged = [...comments];
    final knownIds = comments.map((comment) => comment.id).toSet();
    for (final comment in pending.values) {
      if (knownIds.add(comment.id)) {
        merged.add(comment);
      }
    }
    return merged;
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

class CommunityBlockedUser {
  const CommunityBlockedUser({
    required this.id,
    required this.username,
    required this.avatar,
    required this.blockedAt,
  });

  final int id;
  final String username;
  final String avatar;
  final DateTime? blockedAt;

  factory CommunityBlockedUser.fromJson(Map<dynamic, dynamic> json) {
    return CommunityBlockedUser(
      id: _readInt(json['id']),
      username: (json['username'] ?? '').toString().trim(),
      avatar: (json['avatar'] ?? '').toString().trim(),
      blockedAt: DateTime.tryParse(
        (json['blocked_at'] ?? json['blockedAt'] ?? '').toString(),
      ),
    );
  }
}

Map<dynamic, dynamic> _unwrapResult(Map<String, dynamic> json) {
  final result = json['result'];
  return result is Map ? result : json;
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
