class LeakPostSummary {
  const LeakPostSummary({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.platform,
    required this.authorName,
    required this.authorHandle,
    required this.authorAvatarUrl,
    required this.mediaUrl,
    required this.mediaType,
    this.videoUrl = '',
    this.sourceUrl = '',
    required this.publishedAt,
    required this.likeCount,
    required this.viewCount,
    required this.keywords,
  });

  final String id;
  final String title;
  final String content;
  final String category;
  final String platform;
  final String authorName;
  final String authorHandle;
  final String authorAvatarUrl;
  final String mediaUrl;
  final String mediaType;
  final String videoUrl;
  final String sourceUrl;
  final String publishedAt;
  final int likeCount;
  final int viewCount;
  final List<String> keywords;

  String get authorLabel {
    if (authorName.isNotEmpty && authorHandle.isNotEmpty) {
      if (authorName.toLowerCase() == authorHandle.toLowerCase()) {
        return authorName;
      }
      return '$authorName · $authorHandle';
    }
    return authorName.isNotEmpty ? authorName : authorHandle;
  }

  String get metricText => '$likeCount likes · $viewCount views';

  factory LeakPostSummary.fromJson(Object? json) {
    final map = json is Map ? json : const <String, Object?>{};
    final title = _readString(map['title']);

    return LeakPostSummary(
      id: _readString(map['id']),
      title: title.isEmpty
          ? _readString(map['content_text'], fallback: 'Leak Post')
          : title,
      content: _readString(map['content_text']),
      category: _readString(map['category'], fallback: 'all'),
      platform: _readString(map['platform']),
      authorName: _readString(map['author_name']),
      authorHandle: _readString(map['author_handle']),
      authorAvatarUrl: _readString(map['author_avatar_url']),
      mediaUrl: _readString(map['media_url']),
      mediaType: _readString(map['media_type']),
      videoUrl: _readString(map['video_url']),
      sourceUrl: _readString(map['source_url']),
      publishedAt: _readString(map['published_at'] ?? map['created_at']),
      likeCount: _readInt(map['like_count']),
      viewCount: _readInt(map['view_count']),
      keywords: _readStringList(map['matched_keywords']),
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
