class RankFortuneRecord {
  const RankFortuneRecord({
    required this.id,
    required this.date,
    required this.typeId,
    required this.score,
    this.createdAt,
  });

  factory RankFortuneRecord.fromJson(Object? json) {
    final map = json is Map ? json : const <String, Object?>{};
    return RankFortuneRecord(
      id: _readInt(map['id']),
      date: map['date']?.toString() ?? '',
      typeId: map['typeId']?.toString() ?? map['type_id']?.toString() ?? '',
      score: _readInt(map['score']),
      createdAt: map['created_at']?.toString(),
    );
  }

  final int id;
  final String date;
  final String typeId;
  final int score;
  final String? createdAt;
}

class RankFortuneCatalogEntry {
  const RankFortuneCatalogEntry({required this.typeId, required this.score});

  factory RankFortuneCatalogEntry.fromJson(Object? json) {
    final map = json is Map ? json : const <String, Object?>{};
    return RankFortuneCatalogEntry(
      typeId: map['typeId']?.toString() ?? map['type_id']?.toString() ?? '',
      score: _readInt(map['score']),
    );
  }

  final String typeId;
  final int score;
}

class RankFortuneHistory {
  const RankFortuneHistory({
    required this.rows,
    required this.today,
    required this.canDraw,
    required this.days,
    required this.catalog,
  });

  factory RankFortuneHistory.fromJson(Object? json) {
    final map = json is Map ? json : const <String, Object?>{};
    final rows = map['rows'];
    final catalog = map['fortune_catalog'];
    final today = map['today'];
    return RankFortuneHistory(
      rows: rows is List
          ? rows.map(RankFortuneRecord.fromJson).toList(growable: false)
          : const [],
      today: today is Map ? RankFortuneRecord.fromJson(today) : null,
      canDraw: map['can_draw'] == true,
      days: _readInt(map['days'], fallback: 30),
      catalog: catalog is List
          ? catalog
                .map(RankFortuneCatalogEntry.fromJson)
                .toList(growable: false)
          : const [],
    );
  }

  final List<RankFortuneRecord> rows;
  final RankFortuneRecord? today;
  final bool canDraw;
  final int days;
  final List<RankFortuneCatalogEntry> catalog;
}

class RankFortuneDraw {
  const RankFortuneDraw({
    required this.record,
    required this.alreadyDrawn,
    required this.canDraw,
    required this.catalog,
  });

  factory RankFortuneDraw.fromJson(Object? json) {
    final map = json is Map ? json : const <String, Object?>{};
    return RankFortuneDraw(
      record: RankFortuneRecord.fromJson(map),
      alreadyDrawn: map['already_drawn'] == true,
      canDraw: map['can_draw'] == true,
      catalog: map['fortune_catalog'] is List
          ? (map['fortune_catalog'] as List)
                .map(RankFortuneCatalogEntry.fromJson)
                .toList(growable: false)
          : const [],
    );
  }

  final RankFortuneRecord record;
  final bool alreadyDrawn;
  final bool canDraw;
  final List<RankFortuneCatalogEntry> catalog;
}

int _readInt(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
