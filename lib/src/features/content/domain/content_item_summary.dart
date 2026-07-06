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
    this.landscapeImageUrl = '',
    this.heroId,
    this.heroPosition,
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
  final String landscapeImageUrl;
  final int? heroId;
  final int? heroPosition;

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
      landscapeImageUrl: _readString(
        map['image_url'] ?? map['landscapeUrl'] ?? map['landscape_image_url'],
      ),
      subtitle: _readString(map['series_name'] ?? map['region_name']),
      rating: _readDouble(map['rating']),
      ratingCount: _readInt(map['rating_count'] ?? map['ratingCount']),
      viewCount: 0,
      heroId: _readOptionalInt(map['hero_id'] ?? map['heroId']),
      heroPosition: _readOptionalInt(
        map['hero_position'] ?? map['heroPosition'] ?? map['position'],
      ),
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
      landscapeImageUrl: '',
      subtitle: _readPlayUrl(map['play_url_info_list']).isEmpty
          ? 'Video'
          : 'Playable video',
      rating: _readDouble(map['rating']),
      ratingCount: _readInt(map['rating_count']),
      viewCount: _readInt(map['view_count']),
      heroId: _readOptionalInt(map['hero_id'] ?? map['heroId']),
      heroPosition: null,
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

int? _readOptionalInt(Object? value) {
  if (value == null) {
    return null;
  }
  final text = value.toString().trim();
  if (text.isEmpty) {
    return null;
  }
  return int.tryParse(text);
}

String _readString(Object? value, {String fallback = ''}) {
  final text = value?.toString() ?? '';
  return text.isEmpty ? fallback : text;
}
