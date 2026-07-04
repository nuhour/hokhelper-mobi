class BuildSchemeSummary {
  const BuildSchemeSummary({
    required this.id,
    required this.title,
    required this.heroName,
    required this.authorName,
    required this.equipmentIcons,
    required this.likeCount,
    required this.favoriteCount,
    required this.cloneCount,
    required this.isPublic,
    this.slotIndex = 0,
    this.equipmentIds = const [],
    this.summonerSkillId,
  });

  final int id;
  final String title;
  final String heroName;
  final String authorName;
  final List<String> equipmentIcons;
  final int likeCount;
  final int favoriteCount;
  final int cloneCount;
  final bool isPublic;
  final int slotIndex;
  final List<int> equipmentIds;
  final int? summonerSkillId;

  factory BuildSchemeSummary.fromJson(Object? json) {
    final map = json is Map ? json : const <String, Object?>{};
    final author = map['author'] is Map ? map['author'] as Map : map['user'];
    final hero = map['hero'] is Map ? map['hero'] as Map : null;
    final rawEquipment =
        map['equipment'] ?? map['equips'] ?? map['equipments'] ?? map['items'];

    return BuildSchemeSummary(
      id: _readInt(map['id'] ?? map['scheme_id']),
      title: _readString(
        map['title'] ?? map['name'] ?? map['scheme_name'],
        fallback: 'Untitled build',
      ),
      heroName: _readString(
        map['hero_name'] ??
            map['heroName'] ??
            map['hero'] ??
            (hero is Map ? hero['name'] ?? hero['heroName'] : null),
      ),
      authorName: _readString(
        map['author_name'] ??
            map['authorName'] ??
            map['creator_name'] ??
            (author is Map ? author['first_name'] ?? author['username'] : null),
        fallback: 'Unknown player',
      ),
      equipmentIcons: _readEquipmentIcons(rawEquipment),
      likeCount: _readInt(map['like_count'] ?? map['likes']),
      favoriteCount: _readInt(map['favorite_count'] ?? map['favorites']),
      cloneCount: _readInt(map['clone_count'] ?? map['clones']),
      isPublic: map['is_public'] != false && map['public'] != false,
      slotIndex: _readInt(map['slot_index'] ?? map['slotIndex']),
      equipmentIds: _readEquipmentIds(rawEquipment),
      summonerSkillId: _readOptionalInt(
        map['summoner_skill_id'] ?? map['summonerSkillId'],
      ),
    );
  }
}

List<String> _readEquipmentIcons(Object? value) {
  if (value is! List) {
    return const [];
  }

  return value
      .map((item) {
        if (item is Map) {
          return _readString(item['icon'] ?? item['image'] ?? item['avatar']);
        }
        return '';
      })
      .where((icon) => icon.isNotEmpty)
      .toList(growable: false);
}

List<int> _readEquipmentIds(Object? value) {
  if (value is! List) {
    return const [];
  }

  return value
      .map((item) {
        if (item is Map) {
          return _readInt(item['equip_id'] ?? item['id']);
        }
        return _readInt(item);
      })
      .where((id) => id > 0)
      .toList(growable: false);
}

int _readInt(Object? value) {
  if (value is int) {
    return value;
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _readOptionalInt(Object? value) {
  final parsed = _readInt(value);
  return parsed > 0 ? parsed : null;
}

String _readString(Object? value, {String fallback = ''}) {
  final text = value?.toString() ?? '';
  return text.isEmpty ? fallback : text;
}
