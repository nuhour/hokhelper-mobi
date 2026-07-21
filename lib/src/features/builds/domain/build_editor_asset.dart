class BuildEditorCatalog {
  const BuildEditorCatalog({
    required this.equips,
    this.runes = const [],
    required this.summonerSkills,
  });

  final List<BuildEquipSummary> equips;
  final List<BuildRuneSummary> runes;
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
    final id = _readInt(map['equip_id'] ?? map['id']);
    return BuildEquipSummary(
      id: id,
      name: _readString(map['name'] ?? map['equip_name']),
      iconUrl: _assetUrl(
        explicit:
            map['icon'] ?? map['icon_url'] ?? map['image'] ?? map['avatar'],
        kind: 'equip',
        id: id,
      ),
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
    final id = _readInt(map['skill_id'] ?? map['id']);
    return BuildSummonerSkillSummary(
      id: id,
      name: _readString(map['name'] ?? map['skill_name']),
      iconUrl: _assetUrl(
        explicit:
            map['icon'] ?? map['icon_url'] ?? map['image'] ?? map['avatar'],
        kind: 'summoner_skill',
        id: id,
      ),
    );
  }
}

class BuildRuneSummary {
  const BuildRuneSummary({
    required this.id,
    required this.name,
    required this.color,
    this.iconUrl = '',
  });

  final int id;
  final String name;
  final int color;
  final String iconUrl;

  String get colorName {
    return switch (color) {
      1 => 'Red',
      2 => 'Blue',
      3 => 'Green',
      _ => 'Arcana',
    };
  }

  factory BuildRuneSummary.fromJson(Object? json) {
    final map = json is Map ? json : const <String, Object?>{};
    final id = _readInt(map['rune_id'] ?? map['id']);
    return BuildRuneSummary(
      id: id,
      name: _readString(map['name'] ?? map['rune_name']),
      color: _readInt(map['color']),
      iconUrl: _assetUrl(
        explicit:
            map['icon'] ?? map['icon_url'] ?? map['image'] ?? map['avatar'],
        kind: 'rune',
        id: id,
      ),
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
    this.runeIds = const [],
    required this.summonerSkillId,
    required this.regionCode,
  });

  final int? schemeId;
  final int heroId;
  final int slotIndex;
  final String title;
  final bool isPublic;
  final List<int> equipIds;
  final List<int> runeIds;
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
      'runes': runeIds,
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

String _assetUrl({
  required Object? explicit,
  required String kind,
  required int id,
}) {
  final value = _readString(explicit);
  if (value.isNotEmpty) {
    return value;
  }
  return id > 0 ? '/static/game/$kind/$id.png' : '';
}
