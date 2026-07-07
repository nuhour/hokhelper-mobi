class EsportsMatchSummary {
  const EsportsMatchSummary({
    required this.id,
    required this.leagueName,
    required this.stageName,
    required this.teamAName,
    required this.teamALogoUrl,
    required this.teamBName,
    required this.teamBLogoUrl,
    required this.scoreA,
    required this.scoreB,
    required this.statusKey,
    required this.startTime,
    this.bestOf = 0,
  });

  final String id;
  final String leagueName;
  final String stageName;
  final String teamAName;
  final String teamALogoUrl;
  final String teamBName;
  final String teamBLogoUrl;
  final int? scoreA;
  final int? scoreB;
  final String statusKey;
  final String startTime;
  final int bestOf;

  String get title {
    if (leagueName.isNotEmpty && stageName.isNotEmpty) {
      return '$leagueName · $stageName';
    }
    return leagueName.isNotEmpty ? leagueName : stageName;
  }

  String get scoreText {
    if (scoreA == null || scoreB == null) {
      return 'vs';
    }
    return '$scoreA - $scoreB';
  }

  String get boText => bestOf > 0 ? 'BO$bestOf' : '';

  String get statusLabel {
    return switch (statusKey.toLowerCase()) {
      'live' => 'Live',
      'upcoming' => 'Upcoming',
      'finished' => 'Finished',
      _ => statusKey.isEmpty ? 'Scheduled' : _titleCase(statusKey),
    };
  }

  factory EsportsMatchSummary.fromJson(Object? json) {
    final map = json is Map ? json : const <String, Object?>{};
    final teamA = map['team_a'] is Map ? map['team_a'] as Map : const {};
    final teamB = map['team_b'] is Map ? map['team_b'] as Map : const {};

    return EsportsMatchSummary(
      id: _readString(map['id']),
      leagueName: _readString(map['league_name']),
      stageName: _readString(map['stage_name']),
      teamAName: _readString(
        teamA['name'] ?? teamA['short_name'],
        fallback: 'Team A',
      ),
      teamALogoUrl: _readString(teamA['logo_url']),
      teamBName: _readString(
        teamB['name'] ?? teamB['short_name'],
        fallback: 'Team B',
      ),
      teamBLogoUrl: _readString(teamB['logo_url']),
      scoreA: _readNullableInt(map['score_a']),
      scoreB: _readNullableInt(map['score_b']),
      statusKey: _readString(map['status_key'] ?? map['status']),
      startTime: _readString(map['start_time'] ?? map['scheduled_at']),
      bestOf: _readInt(map['bo'] ?? map['best_of']),
    );
  }
}

String _titleCase(String value) {
  final normalized = value.replaceAll('_', ' ').trim();
  if (normalized.isEmpty) {
    return '';
  }
  return normalized
      .split(RegExp(r'\s+'))
      .map((word) {
        if (word.isEmpty) {
          return word;
        }
        return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
      })
      .join(' ');
}

int? _readNullableInt(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  return int.tryParse(value.toString());
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
