class EsportsStatSummary {
  const EsportsStatSummary({
    required this.id,
    required this.rank,
    required this.objectName,
    required this.subtitle,
    required this.imageUrl,
    required this.leagueName,
    required this.metrics,
    this.teamId = '',
    this.teamName = '',
    this.teamLogoUrl = '',
    this.playerId = '',
    this.playerName = '',
    this.playerAvatarUrl = '',
  });

  final String id;
  final int rank;
  final String objectName;
  final String subtitle;
  final String imageUrl;
  final String leagueName;
  final List<EsportsStatMetric> metrics;
  final String teamId;
  final String teamName;
  final String teamLogoUrl;
  final String playerId;
  final String playerName;
  final String playerAvatarUrl;

  factory EsportsStatSummary.fromJson(Object? json, {int fallbackRank = 0}) {
    final map = json is Map ? json : const <String, Object?>{};
    final hero = map['hero'] is Map ? map['hero'] as Map : const {};
    final player = map['player'] is Map ? map['player'] as Map : const {};
    final team = map['team'] is Map ? map['team'] as Map : const {};
    final stats = _readMap(map['stats'] ?? map['stat_payload']);
    final display = _readMap(map['stats_display']);

    final heroName = _readString(hero['hero_name'] ?? hero['name']);
    final playerName = _readString(player['player_name'] ?? player['name']);
    final teamName = _readString(team['name'] ?? team['short_name']);
    final role = _readString(player['position_desc'] ?? player['position']);

    return EsportsStatSummary(
      id: _readString(map['id'] ?? map['data_key']),
      rank: _readInt(stats['rank'] ?? map['rank'], fallback: fallbackRank),
      objectName: _firstNonEmpty([
        heroName,
        playerName,
        teamName,
        _readString(map['data_key']),
        'Stat',
      ]),
      subtitle: _joinNonEmpty([
        teamName,
        playerName.isNotEmpty && playerName != heroName ? playerName : role,
      ]),
      imageUrl: _firstNonEmpty([
        _readString(hero['hero_icon'] ?? hero['icon_url']),
        _readString(player['player_avatar'] ?? player['avatar_url']),
        _readString(team['logo_url']),
      ]),
      leagueName: _readString(map['league_name']),
      metrics: _readMetrics(map, stats, display),
      teamId: _readString(team['id'] ?? map['team_id']),
      teamName: teamName,
      teamLogoUrl: _readString(team['logo_url']),
      playerId: _readString(player['player_id'] ?? map['player_id']),
      playerName: playerName,
      playerAvatarUrl: _readString(
        player['player_avatar'] ?? player['avatar_url'],
      ),
    );
  }
}

class EsportsStatMetric {
  const EsportsStatMetric({required this.label, required this.value});

  final String label;
  final String value;
}

List<EsportsStatMetric> _readMetrics(
  Map map,
  Map<String, Object?> stats,
  Map<String, Object?> display,
) {
  final keys = <String>[
    ..._readStringList(map['stats_keys']),
    ...display.keys.map((key) => key.toString()),
    ...stats.keys.map((key) => key.toString()),
  ];
  final seen = <String>{};
  final metrics = <EsportsStatMetric>[];
  for (final key in keys) {
    if (key == 'rank' || key == 'rank_num' || !seen.add(key)) {
      continue;
    }
    final raw = display[key] ?? stats[key];
    final value = _formatMetricValue(key, raw);
    if (value.isEmpty) {
      continue;
    }
    metrics.add(EsportsStatMetric(label: _metricLabel(key), value: value));
    if (metrics.length == 4) {
      break;
    }
  }
  return metrics;
}

String _formatMetricValue(String key, Object? value) {
  if (value == null) {
    return '';
  }
  final text = value.toString();
  if (text.isEmpty) {
    return '';
  }
  if (text.endsWith('%')) {
    return text;
  }
  final number = _readDouble(value);
  final normalizedKey = key.toLowerCase();
  if ((normalizedKey.contains('rate') || normalizedKey.contains('ratio')) &&
      number > 0) {
    final rate = number > 1 ? number : number * 100;
    return '${rate.toStringAsFixed(1)}%';
  }
  if (number != 0 || text == '0' || text == '0.0') {
    return number % 1 == 0
        ? number.toInt().toString()
        : number.toStringAsFixed(1);
  }
  return text;
}

String _metricLabel(String key) {
  return switch (key) {
    'winRate' || 'win_rate' => 'Win Rate',
    'kda' || 'avgKda' || 'avg_kda' => 'KDA',
    'pickRate' || 'pick_rate' => 'Pick Rate',
    'banRate' || 'ban_rate' => 'Ban Rate',
    'games' || 'battle_count' => 'Games',
    _ =>
      key
          .replaceAll('_', ' ')
          .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
          .split(RegExp(r'\s+'))
          .where((part) => part.isNotEmpty)
          .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
          .join(' '),
  };
}

Map<String, Object?> _readMap(Object? value) {
  if (value is! Map) {
    return const {};
  }
  return value.map((key, value) => MapEntry(key.toString(), value));
}

List<String> _readStringList(Object? value) {
  if (value is! List) {
    return const [];
  }
  return value
      .map((item) => item.toString())
      .where((item) => item.isNotEmpty)
      .toList();
}

String _joinNonEmpty(List<String> values) {
  return values.where((value) => value.trim().isNotEmpty).join(' · ');
}

String _firstNonEmpty(List<String> values) {
  for (final value in values) {
    if (value.trim().isNotEmpty) {
      return value;
    }
  }
  return '';
}

int _readInt(Object? value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }
  return int.tryParse(value?.toString() ?? '') ?? fallback;
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

String _readString(Object? value) {
  return value?.toString() ?? '';
}
