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
    this.fitRecommendations = const [],
    this.counterRecommendations = const [],
    this.sideWinRates,
    this.phase,
    this.modelVersion,
    this.statsSnapshot,
    this.hasOwnPickContext = false,
    this.hasEnemyPickContext = false,
    this.counterContextAvailable = false,
  });

  /// 兼容旧接口的主列表；Draft v2 下等同于适配/保护推荐。
  final List<TeamRecommendation> recommendations;
  final List<TeamRecommendation> fitRecommendations;
  final List<TeamRecommendation> counterRecommendations;
  final TeamSideWinRates? sideWinRates;
  final String? phase;
  final String? modelVersion;
  final String? statsSnapshot;
  final bool hasOwnPickContext;
  final bool hasEnemyPickContext;
  final bool counterContextAvailable;
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
    this.synergyAvailable = true,
    this.counterAvailable = true,
    this.protect = 0,
    this.deny = 0,
    this.roleFit = 0,
    this.confidence = 0,
    this.minorJob = 0,
    this.components = const {},
    this.reasonCodes = const [],
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
  final bool synergyAvailable;
  final bool counterAvailable;
  final double protect;
  final double deny;
  final double roleFit;
  final double confidence;
  final int minorJob;
  final Map<String, double> components;
  final List<String> reasonCodes;

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
      synergyAvailable: _readBool(map['synergy_available'], defaultValue: true),
      counterAvailable: _readBool(map['counter_available'], defaultValue: true),
      protect: _readRate(map['protect']),
      deny: _readRate(map['deny']),
      roleFit: _readRate(map['role_fit'] ?? map['roleFit']),
      confidence: _readRate(map['confidence']),
      minorJob: _readInt(map['minorJob'] ?? map['minor_job']),
      components: _readComponents(map['components']),
      reasonCodes: _readReasonCodes(map['reason_codes'] ?? map['reasonCodes']),
    );
  }
}

Map<String, double> _readComponents(Object? value) {
  if (value is! Map) return const {};
  return Map<String, double>.fromEntries(
    value.entries.map(
      (entry) => MapEntry(entry.key.toString(), _readRate(entry.value)),
    ),
  );
}

List<String> _readReasonCodes(Object? value) {
  if (value is! List) return const [];
  return value
      .map((item) => item.toString())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
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

bool _readBool(Object? value, {required bool defaultValue}) {
  if (value is bool) return value;
  final text = value?.toString().trim().toLowerCase();
  if (text == 'true' || text == '1') return true;
  if (text == 'false' || text == '0') return false;
  return defaultValue;
}

String _readString(Object? value, {String fallback = ''}) {
  final text = value?.toString() ?? '';
  return text.isEmpty ? fallback : text;
}
