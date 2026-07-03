class EsportsPlayerSummary {
  const EsportsPlayerSummary({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.teamName,
    required this.teamLogoUrl,
    required this.role,
    required this.grade,
    required this.kda,
    required this.winRate,
  });

  final String id;
  final String name;
  final String avatarUrl;
  final String teamName;
  final String teamLogoUrl;
  final String role;
  final double grade;
  final double kda;
  final double winRate;

  String get gradeText => grade.toStringAsFixed(1);

  String get kdaText => kda.toStringAsFixed(1);

  String get winRateText => '${(winRate * 100).toStringAsFixed(1)}%';

  factory EsportsPlayerSummary.fromJson(Object? json) {
    final map = json is Map ? json : const <String, Object?>{};
    final stats = map['stats_json'] is Map ? map['stats_json'] as Map : map;

    return EsportsPlayerSummary(
      id: _readString(map['id']),
      name: _readString(map['name'], fallback: 'Player'),
      avatarUrl: _readString(map['avatar_url']),
      teamName: _readString(map['team_name']),
      teamLogoUrl: _readString(map['team_logo_url']),
      role: _readString(map['role'] ?? map['role_key']),
      grade: _readDouble(stats['grade'] ?? stats['avg_grade']),
      kda: _readDouble(stats['kda']),
      winRate: _readRate(stats['win_rate']),
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

String _readString(Object? value, {String fallback = ''}) {
  final text = value?.toString() ?? '';
  return text.isEmpty ? fallback : text;
}
