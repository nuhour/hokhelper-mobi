enum TeamRecommendType {
  synergy('synergy'),
  counter('counter'),
  balanced('balanced');

  const TeamRecommendType(this.apiValue);

  final String apiValue;
}

class TeamSideWinRates {
  const TeamSideWinRates({required this.blue, required this.red});

  final double blue;
  final double red;

  factory TeamSideWinRates.fromJson(Object? json) {
    final map = json is Map ? json : const <String, Object?>{};
    return TeamSideWinRates(
      blue: _readRate(map['blue']),
      red: _readRate(map['red']),
    );
  }
}

class TeamRecommendationResult {
  const TeamRecommendationResult({
    required this.recommendations,
    this.sideWinRates,
  });

  final List<TeamRecommendation> recommendations;
  final TeamSideWinRates? sideWinRates;
}

class TeamRecommendation {
  const TeamRecommendation({
    required this.heroId,
    required this.externalHeroId,
    required this.name,
    required this.mainJob,
    required this.score,
    required this.reason,
    required this.pickRate,
    required this.banRate,
    required this.synergy,
    required this.counter,
  });

  final int heroId;
  final String externalHeroId;
  final String name;
  final int mainJob;
  final double score;
  final String reason;
  final double pickRate;
  final double banRate;
  final double synergy;
  final double counter;

  factory TeamRecommendation.fromJson(Object? json) {
    final map = json is Map ? json : const <String, Object?>{};
    return TeamRecommendation(
      heroId: _readInt(map['hero_id'] ?? map['id']),
      externalHeroId: _readString(map['heroId'] ?? map['hero_id']),
      name: _readString(
        map['hero_name'] ?? map['heroName'] ?? map['name'],
        fallback: 'Hero',
      ),
      mainJob: _readInt(map['mainJob'] ?? map['main_job']),
      score: _readDouble(map['score']),
      reason: _readString(map['reason']),
      pickRate: _readRate(map['pick_rate']),
      banRate: _readRate(map['ban_rate']),
      synergy: _readRate(map['synergy']),
      counter: _readRate(map['counter']),
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
