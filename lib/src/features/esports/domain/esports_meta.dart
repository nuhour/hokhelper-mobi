class EsportsMeta {
  const EsportsMeta({required this.leagues, required this.rankTypes});

  final List<EsportsLeague> leagues;
  final List<EsportsRankType> rankTypes;

  factory EsportsMeta.fromJson(Object? json) {
    final map = json is Map ? json : const <String, Object?>{};
    final leagues = map['leagues'] is List ? map['leagues'] as List : const [];
    final rankTypes = map['rank_types'] is List
        ? map['rank_types'] as List
        : const [];
    return EsportsMeta(
      leagues: leagues.map(EsportsLeague.fromJson).toList(),
      rankTypes: rankTypes.map(EsportsRankType.fromJson).toList(),
    );
  }
}

class EsportsLeague {
  const EsportsLeague({
    required this.id,
    required this.name,
    this.sourceId = '',
    this.sourceName = '',
    this.startTime = '',
  });

  final String id;
  final String name;
  final String sourceId;
  final String sourceName;
  final String startTime;

  /// 与 HOKX 一致，接口筛选优先使用上游联赛 ID，没有上游 ID 时回退到本地 ID。
  String get value {
    final upstreamId = sourceId.trim();
    return upstreamId.isNotEmpty ? upstreamId : id.trim();
  }

  String get displayName {
    final trimmedName = name.trim();
    return trimmedName.isNotEmpty ? trimmedName : value;
  }

  factory EsportsLeague.fromJson(Object? json) {
    final map = json is Map ? json : const <String, Object?>{};
    return EsportsLeague(
      id: (map['id'] ?? '').toString(),
      name: (map['name_edit'] ?? map['name'] ?? '').toString(),
      sourceId: (map['source_id'] ?? '').toString(),
      sourceName: (map['name'] ?? map['name_edit'] ?? '').toString(),
      startTime: (map['start_time'] ?? '').toString(),
    );
  }
}

class EsportsRankType {
  const EsportsRankType({required this.value, required this.label});

  final int value;
  final String label;

  factory EsportsRankType.fromJson(Object? json) {
    final map = json is Map ? json : const <String, Object?>{};
    return EsportsRankType(
      value: int.tryParse((map['value'] ?? 1).toString()) ?? 1,
      label: (map['label'] ?? map['key'] ?? 'Ranking').toString(),
    );
  }
}
