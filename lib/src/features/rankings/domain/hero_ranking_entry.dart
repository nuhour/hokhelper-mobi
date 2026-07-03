class HeroRankingEntry {
  const HeroRankingEntry({
    required this.heroId,
    required this.externalHeroId,
    required this.name,
    required this.mainJob,
    required this.winRate,
    required this.pickRate,
    required this.banRate,
    required this.mvpRate,
    required this.avgKills,
    required this.avgAssists,
    required this.avgGrade,
  });

  final int heroId;
  final String externalHeroId;
  final String name;
  final String mainJob;
  final double winRate;
  final double pickRate;
  final double banRate;
  final double mvpRate;
  final double avgKills;
  final double avgAssists;
  final double avgGrade;

  factory HeroRankingEntry.fromJson(Object? json) {
    final map = json is Map ? json : const <String, Object?>{};
    final stats = map['stats'] is Map ? map['stats'] as Map : map;

    return HeroRankingEntry(
      heroId: _readInt(map['hero_id'] ?? map['id']),
      externalHeroId: _readString(map['heroId'] ?? map['hero_id']),
      name: _readString(map['name'], fallback: 'Hero'),
      mainJob: _readString(map['mainJob'] ?? map['main_job']),
      winRate: _readRate(stats['win_rate']),
      pickRate: _readRate(stats['pick_rate']),
      banRate: _readRate(stats['ban_rate']),
      mvpRate: _readRate(stats['mvp_rate']),
      avgKills: _readDouble(stats['avg_kills']),
      avgAssists: _readDouble(stats['avg_assists']),
      avgGrade: _readDouble(stats['avg_grade_game']),
    );
  }
}

double _readRate(Object? value) {
  final rate = _readDouble(value);
  return rate > 1 ? rate / 100 : rate;
}

double _readDouble(Object? value) {
  if (value is double) {
    return value;
  }
  if (value is int) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _readInt(Object? value) {
  if (value is int) {
    return value;
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _readString(Object? value, {String fallback = ''}) {
  final text = value?.toString() ?? '';
  return text.isEmpty ? fallback : text;
}
