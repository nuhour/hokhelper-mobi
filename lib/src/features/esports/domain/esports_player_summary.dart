class EsportsPlayerSummary {
  const EsportsPlayerSummary({
    required this.id,
    this.sourceId = '',
    required this.name,
    required this.avatarUrl,
    required this.teamName,
    required this.teamLogoUrl,
    this.leagueName = '',
    this.teamId = '',
    required this.role,
    this.roleKey = '',
    required this.grade,
    required this.kda,
    required this.winRate,
    this.stats = const {},
  });

  final String id;
  final String sourceId;
  final String name;
  final String avatarUrl;
  final String teamName;
  final String teamLogoUrl;
  final String leagueName;
  final String teamId;
  final String role;
  final String roleKey;
  final double grade;
  final double kda;
  final double winRate;
  final Map<String, Object?> stats;

  String get roleLabel => esportsRoleLabel(roleKey, fallback: role);

  double metric(String key) => _readDouble(stats[key]);

  String get gradeText => grade.toStringAsFixed(1);

  String get kdaText => kda.toStringAsFixed(1);

  String get winRateText => '${(winRate * 100).toStringAsFixed(1)}%';

  factory EsportsPlayerSummary.fromJson(Object? json) {
    final map = json is Map ? json : const <String, Object?>{};
    final stats = map['stats_json'] is Map ? map['stats_json'] as Map : map;

    return EsportsPlayerSummary(
      id: _readString(map['id']),
      sourceId: _readString(map['source_id']),
      name: _readString(map['name'], fallback: 'Player'),
      avatarUrl: _readString(map['avatar_url']),
      teamName: _readString(map['team_name']),
      teamLogoUrl: _readString(map['team_logo_url']),
      leagueName: _readString(map['league_name']),
      teamId: _readString(map['team_id']),
      role: _readString(map['role'] ?? map['role_key']),
      roleKey: _readString(map['role_key']),
      grade: _readDouble(
        stats['grade'] ?? stats['avg_grade'] ?? stats['avgScore'],
      ),
      kda: _readDouble(stats['kda'] ?? stats['avgKda']),
      winRate: _readRate(stats['win_rate'] ?? stats['winRate']),
      stats: _readMap(stats),
    );
  }
}

String esportsRoleLabel(String key, {String fallback = ''}) {
  return switch (key.trim().toLowerCase()) {
    'clash' => 'Clash',
    'mid' => 'Mid',
    'jungle' => 'Jungle',
    'farm' => 'Farm',
    'support' => 'Support',
    _ => fallback.trim().isEmpty ? '--' : fallback,
  };
}

Map<String, Object?> _readMap(Map<dynamic, dynamic> value) {
  return value.map((key, value) => MapEntry(key.toString(), value));
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

String _readString(Object? value, {String fallback = ''}) {
  final text = value?.toString() ?? '';
  return text.isEmpty ? fallback : text;
}
