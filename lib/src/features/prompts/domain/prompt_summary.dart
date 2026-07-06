class PromptSummary {
  const PromptSummary({
    required this.id,
    required this.title,
    required this.content,
    required this.tags,
    required this.imageUrl,
    this.authorId = 0,
    required this.authorName,
    required this.likeCount,
    required this.favoriteCount,
    required this.isPublic,
    this.isFavorited = false,
    this.isLiked = false,
    this.sourceImageUrl = '',
    this.effectImageUrl = '',
  });

  final String id;
  final String title;
  final String content;
  final List<String> tags;
  final String imageUrl;
  final int authorId;
  final String authorName;
  final int likeCount;
  final int favoriteCount;
  final bool isPublic;
  final bool isFavorited;
  final bool isLiked;
  final String sourceImageUrl;
  final String effectImageUrl;

  factory PromptSummary.fromJson(Object? json) {
    final map = json is Map ? json : const <String, Object?>{};
    return PromptSummary(
      id: _readString(map['id']),
      title: _readString(map['title'], fallback: 'Untitled prompt'),
      content: _readString(map['content']),
      tags: _readStringList(map['tags']),
      imageUrl: _readString(
        map['display_image_url'] ??
            map['effect_image_url'] ??
            map['image_url'] ??
            map['source_image_url'],
      ),
      sourceImageUrl: _readString(map['source_image_url']),
      effectImageUrl: _readString(map['effect_image_url'] ?? map['image_url']),
      authorId: _readInt(
        map['author_id'] ??
            map['authorId'] ??
            map['creator_id'] ??
            map['creatorId'],
      ),
      authorName: _readString(
        map['author_name'] ?? map['authorName'],
        fallback: 'Unknown creator',
      ),
      likeCount: _readInt(map['likes'] ?? map['like_count']),
      favoriteCount: _readInt(map['favorites'] ?? map['favorite_count']),
      isPublic: map['is_public'] != false && map['public'] != false,
      isFavorited: _readBool(map['is_favorited']),
      isLiked: _readBool(map['is_liked']),
    );
  }
}

bool _readBool(Object? value) {
  if (value is bool) {
    return value;
  }
  final text = value?.toString().toLowerCase() ?? '';
  return text == 'true' || text == '1';
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
