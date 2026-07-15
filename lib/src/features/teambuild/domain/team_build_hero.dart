class TeamBuildHero {
  const TeamBuildHero({
    required this.id,
    required this.externalHeroId,
    required this.name,
    required this.mainJob,
    required this.avatarUrl,
    this.position = '',
  });

  final int id;
  final String externalHeroId;
  final String name;
  final int mainJob;
  final String avatarUrl;
  final String position;

  factory TeamBuildHero.fromJson(Object? json) {
    final map = json is Map ? json : const <String, Object?>{};
    return TeamBuildHero(
      id: _readInt(map['id'] ?? map['hero_id']),
      externalHeroId: _readString(map['heroId'] ?? map['hero_id']),
      name: _readString(
        map['name'] ?? map['hero_name'] ?? map['heroName'],
        fallback: 'Hero',
      ),
      mainJob: _readInt(
        map['mainJob'] ?? map['main_job'] ?? map['main_job_id'],
      ),
      avatarUrl: _readString(
        map['avatar_url'] ??
            map['avatar_url_medium'] ??
            map['avatar_url_large'] ??
            map['avatar'],
      ),
      position: _readString(
        map['position'] ?? map['postion'] ?? map['lane_position'],
      ),
    );
  }

  bool matchesLane(int lane) {
    final tokens = position
        .replaceAll(RegExp(r'[|/，、;；]'), ',')
        .split(',')
        .map((token) => token.trim().toLowerCase())
        .where((token) => token.isNotEmpty);
    const tokenMap = {
      '0': 0,
      'clash': 0,
      'solo': 0,
      'top': 0,
      '1': 1,
      'mid': 1,
      'middle': 1,
      '2': 2,
      'farm': 2,
      'adc': 2,
      'bot': 2,
      '3': 3,
      'jungle': 3,
      'jg': 3,
      '4': 4,
      'support': 4,
      'sup': 4,
      'roam': 4,
    };
    return tokens.any((token) => tokenMap[token] == lane);
  }
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
