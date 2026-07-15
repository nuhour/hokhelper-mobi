class TierListEntry {
  const TierListEntry({
    required this.heroId,
    required this.externalHeroId,
    required this.name,
    this.avatarUrl = '',
    required this.mainJob,
    required this.tier,
    required this.position,
    required this.score,
    required this.winRate,
  });

  final int heroId;
  final String externalHeroId;
  final String name;
  final String avatarUrl;
  final String mainJob;
  final String tier;
  final int position;
  final double score;
  final double winRate;

  TierListEntry withAvatarUrl(String value) {
    return TierListEntry(
      heroId: heroId,
      externalHeroId: externalHeroId,
      name: name,
      avatarUrl: value,
      mainJob: mainJob,
      tier: tier,
      position: position,
      score: score,
      winRate: winRate,
    );
  }

  factory TierListEntry.fromJson(Object? json) {
    final map = json is Map ? json : const <String, Object?>{};

    return TierListEntry(
      heroId: _readInt(map['hero_id'] ?? map['id']),
      externalHeroId: _readString(map['heroId'] ?? map['hero_id']),
      name: _readString(map['name'], fallback: 'Hero'),
      avatarUrl: _readString(
        map['avatar_url_large'] ??
            map['avatar_url_medium'] ??
            map['avatar_url'] ??
            map['avatar'],
      ),
      mainJob: _readString(map['mainJob'] ?? map['main_job']),
      tier: _readString(map['tier'], fallback: 'T?').toUpperCase(),
      position: _readInt(map['position']),
      score: _readDouble(map['score']),
      winRate: _readRate(map['win_rate']),
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
