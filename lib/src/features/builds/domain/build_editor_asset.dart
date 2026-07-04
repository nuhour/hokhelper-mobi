class BuildEditorCatalog {
  const BuildEditorCatalog({
    required this.equips,
    required this.summonerSkills,
  });

  final List<BuildEquipSummary> equips;
  final List<BuildSummonerSkillSummary> summonerSkills;
}

class BuildEquipSummary {
  const BuildEquipSummary({
    required this.id,
    required this.name,
    required this.iconUrl,
  });

  final int id;
  final String name;
  final String iconUrl;

  factory BuildEquipSummary.fromJson(Object? json) {
    final map = json is Map ? json : const <String, Object?>{};
    return BuildEquipSummary(
      id: _readInt(map['equip_id'] ?? map['id']),
      name: _readString(map['name'] ?? map['equip_name']),
      iconUrl: _readString(map['icon'] ?? map['image'] ?? map['avatar']),
    );
  }
}

class BuildSummonerSkillSummary {
  const BuildSummonerSkillSummary({
    required this.id,
    required this.name,
    required this.iconUrl,
  });

  final int id;
  final String name;
  final String iconUrl;

  factory BuildSummonerSkillSummary.fromJson(Object? json) {
    final map = json is Map ? json : const <String, Object?>{};
    return BuildSummonerSkillSummary(
      id: _readInt(map['skill_id'] ?? map['id']),
      name: _readString(map['name'] ?? map['skill_name']),
      iconUrl: _readString(map['icon'] ?? map['image'] ?? map['avatar']),
    );
  }
}

class BuildSchemeDraft {
  const BuildSchemeDraft({
    this.schemeId,
    required this.heroId,
    required this.slotIndex,
    required this.title,
    required this.isPublic,
    required this.equipIds,
    required this.summonerSkillId,
    required this.regionCode,
  });

  final int? schemeId;
  final int heroId;
  final int slotIndex;
  final String title;
  final bool isPublic;
  final List<int> equipIds;
  final int? summonerSkillId;
  final String regionCode;

  Map<String, dynamic> toJson() {
    return {
      'hero_id': heroId,
      'slot_index': slotIndex,
      'region_code': regionCode,
      'name': title,
      'description': '',
      'is_public': isPublic,
      'equips': equipIds,
      'runes': <int>[],
      'summoner_skill_id': summonerSkillId,
    };
  }
}

int _readInt(Object? value) {
  if (value is int) {
    return value;
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _readString(Object? value) {
  return value?.toString().trim() ?? '';
}
