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
  const EsportsLeague({required this.id, required this.name});

  final String id;
  final String name;

  factory EsportsLeague.fromJson(Object? json) {
    final map = json is Map ? json : const <String, Object?>{};
    return EsportsLeague(
      id: (map['id'] ?? '').toString(),
      name: (map['name_edit'] ?? map['name'] ?? '').toString(),
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
