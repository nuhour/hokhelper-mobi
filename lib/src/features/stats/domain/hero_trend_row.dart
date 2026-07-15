class HeroTrendRow {
  const HeroTrendRow({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.winRate,
    required this.mvpScore,
    required this.mvpRate,
    required this.dmgShare,
    required this.takeDmgShare,
    required this.ecoShare,
  });

  final int id;
  final String name;
  final String avatarUrl;
  final double winRate;
  final double mvpScore;
  final double mvpRate;
  final double dmgShare;
  final double takeDmgShare;
  final double ecoShare;

  String get winRateText => '${winRate.toStringAsFixed(2)}%';
  String get mvpScoreText => mvpScore.toStringAsFixed(2);
  String get mvpRateText => '${mvpRate.toStringAsFixed(2)}%';
  String get dmgShareText => '${dmgShare.toStringAsFixed(2)}%';
  String get takeDmgShareText => '${takeDmgShare.toStringAsFixed(2)}%';
  String get ecoShareText => '${ecoShare.toStringAsFixed(2)}%';

  factory HeroTrendRow.fromJson(Object? value) {
    final json = _asMap(value);
    final hero = _asMap(json['hero'] ?? json['object']);
    final id = _readInt(hero, const ['id']);

    return HeroTrendRow(
      id: id > 0 ? id : _readInt(json, const ['hero_id', 'id']),
      name: _readString(hero, const ['name', 'hero_name']).isNotEmpty
          ? _readString(hero, const ['name', 'hero_name'])
          : _readString(json, const ['hero_name', 'name']),
      avatarUrl:
          _readString(hero, const [
            'avatar_url',
            'avatar_url_large',
            'avatar_url_medium',
            'image_url',
          ]).isNotEmpty
          ? _readString(hero, const [
              'avatar_url',
              'avatar_url_large',
              'avatar_url_medium',
              'image_url',
            ])
          : _readString(json, const ['avatar_url', 'hero_avatar_url']),
      winRate: _readPercent(json, const ['win_rate', 'wr', 'winRate']),
      mvpScore: _readDouble(json, const [
        'avg_grade_game',
        'score',
        'grade',
        'mvp_score',
      ]),
      mvpRate: _readPercent(json, const ['mvp_rate', 'mvpRate']),
      dmgShare: _readPercent(json, const [
        'hurt_rate',
        'dmg_share',
        'dmgShare',
      ]),
      takeDmgShare: _readPercent(json, const [
        'be_hurt_rate',
        'take_dmg_share',
        'takeDmgShare',
      ]),
      ecoShare: _readPercent(json, const [
        'money_share',
        'gold_rate',
        'eco_share',
        'ecoShare',
      ]),
    );
  }
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return const {};
}

String _readString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    final text = value?.toString().trim();
    if (text != null && text.isNotEmpty) {
      return text;
    }
  }
  return '';
}

int _readInt(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    final parsed = int.tryParse(value?.toString() ?? '');
    if (parsed != null) {
      return parsed;
    }
  }
  return 0;
}

double _readDouble(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is num) {
      return value.toDouble();
    }
    final parsed = double.tryParse(value?.toString() ?? '');
    if (parsed != null) {
      return parsed;
    }
  }
  return 0;
}

double _readPercent(Map<String, dynamic> json, List<String> keys) {
  final value = _readDouble(json, keys);
  return value > 1 ? value : value * 100;
}
