class HeroSummary {
  const HeroSummary({
    required this.id,
    this.heroId = '',
    required this.name,
    required this.avatar,
    required this.title,
    this.position,
    this.mainJob = '',
    this.minorJob = '',
    this.tier = '',
    this.rating = 0,
    this.ratingCount = 0,
  });

  final String id;
  final String heroId;
  final String name;
  final String avatar;
  final String title;
  final int? position;
  final String mainJob;
  final String minorJob;
  final String tier;
  final double rating;
  final int ratingCount;

  factory HeroSummary.fromJson(Map<String, dynamic> json) {
    return HeroSummary(
      id: _readHeroId(json, const ['id', 'heroId', 'hero_id']),
      heroId: _readHeroId(json, const ['heroId', 'hero_id', 'id']),
      name: _readString(json, const ['heroName', 'name', 'hero_name']),
      avatar: _readString(json, const [
        'avatar_url_large',
        'avatar_url_medium',
        'avatar_url',
        'avatar',
        'icon',
        'image',
      ]),
      title: _readString(json, const ['title', 'heroTitle']),
      position: _readInt(json, const ['position', 'mainJob', 'main_job']),
      mainJob: _readJobLabel(
        json,
        const ['mainJobName', 'main_job_name'],
        const ['mainJob', 'main_job'],
      ),
      minorJob: _readJobLabel(
        json,
        const ['minorJobName', 'minor_job_name'],
        const ['minorJob', 'minor_job'],
      ),
      tier: _readString(json, const ['tier', 'hot']),
      rating: _readDouble(json, const ['rating', 'avg_rating']),
      ratingCount: _readInt(json, const ['rating_count', 'ratingCount']) ?? 0,
    );
  }

  bool get hasValidId => normalizeId(id) != null;

  String? get detailRouteId => normalizeId(id);

  static String? normalizeId(Object? value) {
    if (value == null) {
      return null;
    }

    final rawValue = value.toString().trim();
    final parsedId = int.tryParse(rawValue);
    if (parsedId == null || parsedId <= 0) {
      return null;
    }

    return parsedId.toString();
  }

  static String _readHeroId(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final normalizedId = normalizeId(json[key]);
      if (normalizedId != null) {
        return normalizedId;
      }
    }

    return '';
  }

  static String _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      final stringValue = value?.toString().trim();
      if (stringValue != null && stringValue.isNotEmpty) {
        return stringValue;
      }
    }

    return '';
  }

  static int? _readInt(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is int) {
        return value;
      }
      final parsedValue = int.tryParse(value?.toString().trim() ?? '');
      if (parsedValue != null) {
        return parsedValue;
      }
    }

    return null;
  }

  static double _readDouble(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is num) {
        return value.toDouble();
      }
      final parsedValue = double.tryParse(value?.toString().trim() ?? '');
      if (parsedValue != null) {
        return parsedValue;
      }
    }

    return 0;
  }

  static String _readJobLabel(
    Map<String, dynamic> json,
    List<String> labelKeys,
    List<String> idKeys,
  ) {
    final label = _readString(json, labelKeys);
    if (label.isNotEmpty) {
      return label;
    }
    return switch (_readInt(json, idKeys)) {
      1 => 'Tank',
      2 => 'Fighter',
      3 => 'Assassin',
      4 => 'Mage',
      5 => 'Marksman',
      6 => 'Support',
      _ => '',
    };
  }
}
