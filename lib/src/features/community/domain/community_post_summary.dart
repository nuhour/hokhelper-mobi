class CommunityPostSummary {
  const CommunityPostSummary({
    required this.id,
    required this.title,
    required this.preview,
    this.authorId = 0,
    required this.authorName,
    required this.authorAvatarUrl,
    required this.tags,
    required this.createdAt,
    required this.viewCount,
    required this.likeCount,
    required this.commentCount,
  });

  final String id;
  final String title;
  final String preview;
  final int authorId;
  final String authorName;
  final String authorAvatarUrl;
  final List<String> tags;
  final String createdAt;
  final int viewCount;
  final int likeCount;
  final int commentCount;

  String get metricText => '$likeCount likes · $commentCount comments';

  factory CommunityPostSummary.fromJson(Object? json) {
    final map = json is Map ? json : const <String, Object?>{};

    return CommunityPostSummary(
      id: _readString(map['id']),
      title: _readString(map['title'], fallback: 'Community Post'),
      preview: _readString(map['content_preview'] ?? map['content']),
      authorId: _readInt(map['author_id']),
      authorName: _readString(map['author_name'], fallback: 'Player'),
      authorAvatarUrl: _readString(map['author_avatar']),
      tags: _readStringList(map['tags']),
      createdAt: _readString(map['created_at'] ?? map['date']),
      viewCount: _readInt(map['view_count']),
      likeCount: _readInt(map['like_count']),
      commentCount: _readInt(map['comment_count']),
    );
  }
}

List<String> _readStringList(Object? value) {
  if (value is! List) {
    return const [];
  }
  return value
      .map((item) => item?.toString() ?? '')
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
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
