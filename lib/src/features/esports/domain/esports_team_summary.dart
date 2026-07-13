class EsportsTeamSummary {
  const EsportsTeamSummary({
    required this.id,
    required this.name,
    required this.shortName,
    required this.logoUrl,
    required this.leagueName,
    required this.club,
    required this.wins,
    required this.losses,
    required this.winRate,
  });

  final String id;
  final String name;
  final String shortName;
  final String logoUrl;
  final String leagueName;
  final String club;
  final int wins;
  final int losses;
  final double winRate;

  String get displayName => shortName.isEmpty ? name : '$name · $shortName';

  String get recordText => '${wins}W / ${losses}L';

  String get winRateText => '${(winRate * 100).toStringAsFixed(1)}%';

  factory EsportsTeamSummary.fromJson(Object? json) {
    final map = json is Map ? json : const <String, Object?>{};
    final rankStat = map['rank_stat'] is Map
        ? map['rank_stat'] as Map
        : const {};

    return EsportsTeamSummary(
      id: _readString(map['id']),
      name: _readString(map['name'], fallback: 'Team'),
      shortName: _readString(map['short_name']),
      logoUrl: _readString(map['logo_url']),
      leagueName: _readString(map['league_name']),
      club: _readString(map['club']),
      wins: _readInt(map['wins'] ?? rankStat['victoryBattleCount']),
      losses: _readInt(map['losses'] ?? rankStat['defeatedBattleCount']),
      winRate: _readRate(map['win_rate'] ?? rankStat['winRate']),
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
