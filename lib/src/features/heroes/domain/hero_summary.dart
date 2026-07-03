class HeroSummary {
  const HeroSummary({
    required this.id,
    required this.name,
    required this.avatar,
    required this.title,
  });

  final String id;
  final String name;
  final String avatar;
  final String title;

  factory HeroSummary.fromJson(Map<String, dynamic> json) {
    return HeroSummary(
      id: _readHeroId(json, const ['id', 'heroId', 'hero_id']),
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
}
