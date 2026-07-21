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
    this.isLiked = false,
    this.isFavorited = false,
    this.slotIndex = 0,
    this.equipmentIds = const [],
    this.runeIds = const [],
    this.summonerSkillId,
    this.authorId = 0,
  });

  final int id;
  final String title;
  final String heroName;
  final String authorName;
  final int authorId;
  final List<String> equipmentIcons;
  final int likeCount;
  final int favoriteCount;
  final int cloneCount;
  final bool isPublic;
  final bool isLiked;
  final bool isFavorited;
  final int slotIndex;
  final List<int> equipmentIds;
  final List<int> runeIds;
  final int? summonerSkillId;

  List<String> get runeIcons => runeIds
      .where((id) => id > 0)
      .map((id) => '/static/game/rune/$id.png')
      .toList(growable: false);

  String get summonerSkillIcon => summonerSkillId == null
      ? ''
      : '/static/game/summoner_skill/$summonerSkillId.png';

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
      authorId: _readInt(
        map['author_id'] ??
            map['authorId'] ??
            map['creator_id'] ??
            (author is Map ? author['id'] : null),
      ),
      equipmentIcons: _readEquipmentIcons(rawEquipment),
      likeCount: _readInt(
        map['like_count'] ?? map['likes_count'] ?? map['likes'],
      ),
      favoriteCount: _readInt(
        map['favorite_count'] ?? map['favorites_count'] ?? map['favorites'],
      ),
      cloneCount: _readInt(
        map['clone_count'] ?? map['clones_count'] ?? map['clones'],
      ),
      isPublic: map['is_public'] != false && map['public'] != false,
      isLiked: _readBool(map['is_liked'] ?? map['isLiked'] ?? map['liked']),
      isFavorited: _readBool(
        map['is_favorited'] ?? map['isFavorited'] ?? map['favorited'],
      ),
      slotIndex: _readInt(map['slot_index'] ?? map['slotIndex']),
      equipmentIds: _readEquipmentIds(rawEquipment),
      runeIds: _readIdList(map['runes'] ?? map['arcana']),
      summonerSkillId: _readOptionalInt(
        map['summoner_skill_id'] ?? map['summonerSkillId'],
      ),
    );
  }
}

List<int> _readIdList(Object? value) {
  if (value is! List) {
    return const [];
  }

  return value
      .map((item) {
        if (item is Map) {
          return _readInt(item['rune_id'] ?? item['id']);
        }
        return _readInt(item);
      })
      .where((id) => id > 0)
      .toList(growable: false);
}

List<String> _readEquipmentIcons(Object? value) {
  if (value is! List) {
    return const [];
  }

  return value
      .map((item) {
        if (item is Map) {
          final icon = _readString(
            item['icon'] ??
                item['icon_url'] ??
                item['iconUrl'] ??
                item['image'] ??
                item['avatar'],
          );
          if (icon.isNotEmpty) {
            return icon;
          }
          final id = _readInt(item['equip_id'] ?? item['id']);
          return id > 0 ? '/static/game/equip/$id.png' : '';
        }
        final id = _readInt(item);
        return id > 0 ? '/static/game/equip/$id.png' : '';
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

bool _readBool(Object? value) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  final text = value?.toString().toLowerCase().trim();
  return text == 'true' || text == '1' || text == 'yes';
}

int? _readOptionalInt(Object? value) {
  final parsed = _readInt(value);
  return parsed > 0 ? parsed : null;
}

String _readString(Object? value, {String fallback = ''}) {
  final text = value?.toString() ?? '';
  return text.isEmpty ? fallback : text;
}
