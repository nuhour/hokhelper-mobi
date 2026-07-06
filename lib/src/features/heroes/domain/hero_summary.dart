class HeroSummary {
  const HeroSummary({
    required this.id,
    this.heroId = '',
    required this.name,
    required this.avatar,
    required this.title,
    this.position,
  });

  final String id;
  final String heroId;
  final String name;
  final String avatar;
  final String title;
  final int? position;

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
}
