class SkinDetail {
  const SkinDetail({
    required this.id,
    required this.title,
    required this.heroName,
    required this.portraitUrl,
    required this.landscapeUrl,
    required this.seriesName,
    required this.regionName,
    required this.rating,
    required this.ratingCount,
    required this.linkUrl,
  });

  final int id;
  final String title;
  final String heroName;
  final String portraitUrl;
  final String landscapeUrl;
  final String seriesName;
  final String regionName;
  final double rating;
  final int ratingCount;
  final String linkUrl;

  factory SkinDetail.fromJson(Object? json) {
    final map = json is Map ? json : const <String, Object?>{};

    return SkinDetail(
      id: _readInt(map['id']),
      title: _readString(map['name'], fallback: 'Skin #${_readInt(map['id'])}'),
      heroName: _readString(map['hero_name'] ?? map['heroName']),
      portraitUrl: _readString(
        map['additional_image_url'] ??
            map['portraitUrl'] ??
            map['image_url'] ??
            map['landscapeUrl'],
      ),
      landscapeUrl: _readString(
        map['image_url'] ??
            map['landscapeUrl'] ??
            map['additional_image_url'] ??
            map['portraitUrl'],
      ),
      seriesName: _readString(map['series_name'] ?? map['seriesName']),
      regionName: _readString(map['region_name'] ?? map['regionName']),
      rating: _readDouble(map['rating']),
      ratingCount: _readInt(map['rating_count'] ?? map['ratingCount']),
      linkUrl: _readString(map['link_url'] ?? map['linkUrl']),
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

String _readString(Object? value, {String fallback = ''}) {
  final text = value?.toString() ?? '';
  return text.isEmpty ? fallback : text;
}
