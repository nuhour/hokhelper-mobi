class CgDetail {
  const CgDetail({
    required this.id,
    required this.title,
    required this.heroName,
    required this.coverUrl,
    required this.playUrl,
    required this.viewCount,
    required this.rating,
    required this.ratingCount,
  });

  final int id;
  final String title;
  final String heroName;
  final String coverUrl;
  final String playUrl;
  final int viewCount;
  final double rating;
  final int ratingCount;

  factory CgDetail.fromJson(Object? json) {
    final map = json is Map ? json : const <String, Object?>{};
    final id = _readInt(map['id']);

    return CgDetail(
      id: id,
      title: _readString(map['title1_key'], fallback: 'CG #$id'),
      heroName: _readString(map['hero_name'] ?? map['heroName']),
      coverUrl: _readString(map['video_cover'] ?? map['cover_url']),
      playUrl: _readPlayUrl(map['play_url_info_list']),
      viewCount: _readInt(map['view_count'] ?? map['viewCount']),
      rating: _readDouble(map['rating']),
      ratingCount: _readInt(map['rating_count'] ?? map['ratingCount']),
    );
  }
}

class CgCommentSummary {
  const CgCommentSummary({
    required this.id,
    required this.authorName,
    required this.authorAvatarUrl,
    required this.content,
    required this.createdAt,
  });

  final int id;
  final String authorName;
  final String authorAvatarUrl;
  final String content;
  final String createdAt;

  factory CgCommentSummary.fromJson(Object? json) {
    final map = json is Map ? json : const <String, Object?>{};

    return CgCommentSummary(
      id: _readInt(map['id']),
      authorName: _readString(map['author_name'], fallback: 'Player'),
      authorAvatarUrl: _readString(map['author_avatar']),
      content: _readString(map['content']),
      createdAt: _readString(map['created_at']),
    );
  }
}

String _readPlayUrl(Object? value) {
  if (value is! List || value.isEmpty) {
    return '';
  }
  for (final item in value) {
    if (item is Map) {
      final url = _readString(item['playURL'] ?? item['url']);
      if (url.isNotEmpty) {
        return url;
      }
    }
  }
  return '';
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

String _readString(Object? value, {String fallback = ''}) {
  final text = value?.toString() ?? '';
  return text.isEmpty ? fallback : text;
}
