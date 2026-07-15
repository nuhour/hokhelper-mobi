class HeroRelationship {
  const HeroRelationship({
    required this.id,
    required this.sourceHeroId,
    required this.sourceHeroName,
    required this.targetHeroId,
    required this.targetHeroName,
    required this.title,
    required this.weight,
    required this.description,
  });

  final String id;
  final String sourceHeroId;
  final String sourceHeroName;
  final String targetHeroId;
  final String targetHeroName;
  final String title;
  final int weight;
  final String description;

  HeroRelationship withHeroNames({
    String? sourceHeroName,
    String? targetHeroName,
  }) {
    return HeroRelationship(
      id: id,
      sourceHeroId: sourceHeroId,
      sourceHeroName: sourceHeroName ?? this.sourceHeroName,
      targetHeroId: targetHeroId,
      targetHeroName: targetHeroName ?? this.targetHeroName,
      title: title,
      weight: weight,
      description: description,
    );
  }

  factory HeroRelationship.fromJson(Map<String, dynamic> json) {
    return HeroRelationship(
      id: _readString(json, const ['id', 'relationship_id']),
      sourceHeroId: _readString(json, const [
        'hero1_id',
        'sourceHeroId',
        'source_hero_id',
        'source',
      ]),
      sourceHeroName: _readString(json, const [
        'hero1_name',
        'sourceHeroName',
        'source_hero_name',
        'source_name',
      ]),
      targetHeroId: _readString(json, const [
        'hero2_id',
        'targetHeroId',
        'target_hero_id',
        'target',
      ]),
      targetHeroName: _readString(json, const [
        'hero2_name',
        'targetHeroName',
        'target_hero_name',
        'target_name',
      ]),
      title: _readString(json, const ['title', 'relationship_title', 'name']),
      weight: _readInt(json, const ['weight', 'score', 'strength']),
      description: _readString(json, const ['description', 'desc', 'content']),
    );
  }

  bool involves(String heroNameOrId) {
    final needle = heroNameOrId.trim().toLowerCase();
    if (needle.isEmpty) {
      return false;
    }

    return sourceHeroName.toLowerCase() == needle ||
        targetHeroName.toLowerCase() == needle ||
        sourceHeroId.toLowerCase() == needle ||
        targetHeroId.toLowerCase() == needle;
  }

  String otherHeroName(String heroNameOrId) {
    final needle = heroNameOrId.trim().toLowerCase();
    final sourceMatches =
        sourceHeroName.toLowerCase() == needle ||
        sourceHeroId.toLowerCase() == needle;
    return sourceMatches
        ? (targetHeroName.isEmpty ? targetHeroId : targetHeroName)
        : (sourceHeroName.isEmpty ? sourceHeroId : sourceHeroName);
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

  static int _readInt(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is num) {
        return value.round();
      }

      final parsed = int.tryParse(value?.toString() ?? '');
      if (parsed != null) {
        return parsed;
      }
    }

    return 0;
  }
}
