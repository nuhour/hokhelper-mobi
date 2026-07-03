enum ContentKind { skin, cg }

class ContentItemSummary {
  const ContentItemSummary({
    required this.id,
    required this.kind,
    required this.title,
    required this.heroName,
    required this.imageUrl,
    required this.subtitle,
    required this.rating,
    required this.ratingCount,
    required this.viewCount,
  });

  final int id;
  final ContentKind kind;
  final String title;
  final String heroName;
  final String imageUrl;
  final String subtitle;
  final double rating;
  final int ratingCount;
  final int viewCount;

  factory ContentItemSummary.skinFromJson(Object? json) {
    final map = json is Map ? json : const <String, Object?>{};
    return ContentItemSummary(
      id: _readInt(map['id']),
      kind: ContentKind.skin,
      title: _readString(map['name'], fallback: 'Skin #${_readInt(map['id'])}'),
      heroName: _readString(map['hero_name'] ?? map['heroName']),
      imageUrl: _readString(
        map['additional_image_url'] ??
            map['portraitUrl'] ??
            map['image_url'] ??
            map['landscapeUrl'],
      ),
      subtitle: _readString(map['series_name'] ?? map['region_name']),
      rating: _readDouble(map['rating']),
      ratingCount: _readInt(map['rating_count'] ?? map['ratingCount']),
      viewCount: 0,
    );
  }

  factory ContentItemSummary.cgFromJson(Object? json) {
    final map = json is Map ? json : const <String, Object?>{};
    return ContentItemSummary(
      id: _readInt(map['id']),
      kind: ContentKind.cg,
      title: _readString(
        map['title1_key'],
        fallback: 'CG #${_readInt(map['id'])}',
      ),
      heroName: _readString(map['hero_name']),
      imageUrl: _readString(map['video_cover'] ?? map['cover_url']),
      subtitle: _readPlayUrl(map['play_url_info_list']).isEmpty
          ? 'Video'
          : 'Playable video',
      rating: _readDouble(map['rating']),
      ratingCount: _readInt(map['rating_count']),
      viewCount: _readInt(map['view_count']),
    );
  }
}

String _readPlayUrl(Object? value) {
  if (value is! List || value.isEmpty) {
    return '';
  }

  final first = value.first;
  if (first is! Map) {
    return '';
  }

  return _readString(first['playURL'] ?? first['url']);
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
