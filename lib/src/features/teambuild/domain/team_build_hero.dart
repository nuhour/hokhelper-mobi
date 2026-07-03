class TeamBuildHero {
  const TeamBuildHero({
    required this.id,
    required this.externalHeroId,
    required this.name,
    required this.mainJob,
    required this.avatarUrl,
  });

  final int id;
  final String externalHeroId;
  final String name;
  final int mainJob;
  final String avatarUrl;

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
    );
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
