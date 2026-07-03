class PlayerBestHero {
  const PlayerBestHero({
    required this.heroId,
    required this.playCount,
    required this.score,
  });

  final int heroId;
  final int playCount;
  final double score;

  factory PlayerBestHero.fromJson(Object? json) {
    final map = json is Map ? json : const <String, Object?>{};
    return PlayerBestHero(
      heroId: _readInt(map['hero_id'] ?? map['id']),
      playCount: _readInt(map['play_cnt'] ?? map['playCount']),
      score: _readDouble(map['score']),
    );
  }
}

class PlayerRankingEntry {
  const PlayerRankingEntry({
    required this.playerId,
    required this.playerName,
    required this.avatarUrl,
    required this.peakScore,
    required this.rankStars,
    required this.winRate,
    required this.avgKda,
    required this.playCount,
    required this.grade,
    required this.mvpCount,
    required this.region,
    required this.playerTypeLabel,
    required this.bestHeroes,
  });

  final String playerId;
  final String playerName;
  final String avatarUrl;
  final double peakScore;
  final int rankStars;
  final double winRate;
  final double avgKda;
  final int playCount;
  final double grade;
  final int mvpCount;
  final int region;
  final String playerTypeLabel;
  final List<PlayerBestHero> bestHeroes;

  factory PlayerRankingEntry.fromJson(Object? json) {
    final map = json is Map ? json : const <String, Object?>{};
    final bestHeroes = map['best_heroes'];

    return PlayerRankingEntry(
      playerId: _readString(map['player_id']),
      playerName: _readString(map['player_name'], fallback: 'Player'),
      avatarUrl: _readString(map['avatar_url']),
      peakScore: _readDouble(map['peak_score']),
      rankStars: _readInt(map['rank_stars']),
      winRate: _readRate(map['win_rate']),
      avgKda: _readDouble(map['avg_kda']),
      playCount: _readInt(map['play_cnt'] ?? map['playCount']),
      grade: _readDouble(map['grade']),
      mvpCount: _readInt(map['mvp']),
      region: _readInt(map['region']),
      playerTypeLabel: _readString(map['player_type_label']),
      bestHeroes: bestHeroes is List
          ? bestHeroes.map(PlayerBestHero.fromJson).toList(growable: false)
          : const [],
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
