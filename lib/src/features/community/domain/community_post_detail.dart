import 'community_post_summary.dart';

class CommunityPostDetail {
  const CommunityPostDetail({
    required this.post,
    required this.content,
    required this.isLiked,
    required this.comments,
  });

  final CommunityPostSummary post;
  final String content;
  final bool isLiked;
  final List<CommunityCommentSummary> comments;

  factory CommunityPostDetail.fromJson(Object? json) {
    final map = json is Map ? json : const <String, Object?>{};
    final postJson = map['post'];
    final postMap = postJson is Map ? postJson : map;
    final comments = map['comments'];

    return CommunityPostDetail(
      post: CommunityPostSummary.fromJson(postMap),
      content: _readString(postMap['content'] ?? map['content']),
      isLiked: _readBool(postMap['is_liked'] ?? postMap['isLiked']),
      comments: comments is List
          ? comments
                .map(CommunityCommentSummary.fromJson)
                .toList(growable: false)
          : const [],
    );
  }
}

class CommunityCommentSummary {
  const CommunityCommentSummary({
    required this.id,
    required this.content,
    this.authorId = 0,
    required this.authorName,
    required this.authorAvatarUrl,
    required this.createdAt,
    required this.likeCount,
    required this.parentId,
    required this.parentAuthorName,
  });

  final String id;
  final String content;
  final int authorId;
  final String authorName;
  final String authorAvatarUrl;
  final String createdAt;
  final int likeCount;
  final String parentId;
  final String parentAuthorName;

  factory CommunityCommentSummary.fromJson(Object? json) {
    final map = json is Map ? json : const <String, Object?>{};

    return CommunityCommentSummary(
      id: _readString(map['id']),
      content: _readString(map['content']),
      authorId: _readInt(map['author_id'] ?? map['authorId']),
      authorName: _readString(map['author_name'], fallback: 'Player'),
      authorAvatarUrl: _readString(map['author_avatar']),
      createdAt: _readString(map['created_at']),
      likeCount: _readInt(map['like_count']),
      parentId: _readString(map['parent_id'] ?? map['parent']),
      parentAuthorName: _readString(map['parent_author_name']),
    );
  }
}

bool _readBool(Object? value) {
  if (value is bool) {
    return value;
  }
  final normalized = value?.toString().toLowerCase() ?? '';
  return normalized == '1' || normalized == 'true' || normalized == 'yes';
}

int _readInt(Object? value) {
  if (value is int) {
    return value;
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _readString(Object? value, {String fallback = ''}) {
  final text = value?.toString() ?? '';
  return text.isEmpty ? fallback : text;
}
