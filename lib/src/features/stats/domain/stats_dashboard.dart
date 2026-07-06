class StatsDashboard {
  const StatsDashboard({
    this.heroes = const [],
    this.equips = const [],
    this.combos = const [],
  });

  final List<StatsHeroRow> heroes;
  final List<StatsEquipRow> equips;
  final List<StatsComboRow> combos;

  bool get isEmpty => heroes.isEmpty && equips.isEmpty && combos.isEmpty;
}

enum StatsDashboardEntry { overview, homeCore, tierRank, powerRank, equipRank }

class StatsHeroRow {
  const StatsHeroRow({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.winRate,
    required this.pickRate,
    required this.banRate,
    required this.score,
  });

  final String id;
  final String name;
  final String avatarUrl;
  final double winRate;
  final double pickRate;
  final double banRate;
  final double score;

  String get winRateText => _formatPercent(winRate);
  String get pickRateText => _formatPercent(pickRate);
  String get banRateText => _formatPercent(banRate);
  String get scoreText => score <= 0 ? '-' : score.toStringAsFixed(1);

  factory StatsHeroRow.fromJson(Object? value) {
    final json = _asMap(value);
    return StatsHeroRow(
      id: _readString(json, const ['hero_id', 'id', 'external_hero_id']),
      name: _readString(json, const ['hero_name', 'name', 'cname']),
      avatarUrl: _readString(json, const [
        'hero_avatar_url',
        'avatar_url',
        'image_url',
        'icon_url',
      ]),
      winRate: _readRate(json, const ['win_rate', 'winRate']),
      pickRate: _readRate(json, const ['pick_rate', 'pickRate']),
      banRate: _readRate(json, const ['ban_rate', 'banRate']),
      score: _readDouble(json, const ['score', 'power_score', 'rank_score']),
    );
  }
}

class StatsEquipRow {
  const StatsEquipRow({
    required this.id,
    required this.name,
    required this.iconUrl,
    required this.pickRate,
    required this.winRate,
  });

  final String id;
  final String name;
  final String iconUrl;
  final double pickRate;
  final double winRate;

  String get pickRateText => _formatPercent(pickRate);
  String get winRateText => _formatPercent(winRate);

  factory StatsEquipRow.fromJson(Object? value) {
    final json = _asMap(value);
    return StatsEquipRow(
      id: _readString(json, const ['equip_id', 'id', 'item_id']),
      name: _readString(json, const ['equip_name', 'name', 'item_name']),
      iconUrl: _readString(json, const [
        'equip_icon_url',
        'icon_url',
        'image_url',
      ]),
      pickRate: _readRate(json, const ['pick_rate', 'pickRate']),
      winRate: _readRate(json, const ['win_rate', 'winRate']),
    );
  }
}

class StatsComboRow {
  const StatsComboRow({
    required this.heroAName,
    required this.heroBName,
    required this.matches,
    required this.winRate,
    required this.score,
  });

  final String heroAName;
  final String heroBName;
  final int matches;
  final double winRate;
  final double score;

  String get title {
    if (heroAName.isEmpty && heroBName.isEmpty) {
      return 'Hero Combo';
    }
    if (heroAName.isEmpty) {
      return heroBName;
    }
    if (heroBName.isEmpty) {
      return heroAName;
    }
    return '$heroAName + $heroBName';
  }

  String get matchesText => '$matches matches';
  String get winRateText => _formatPercent(winRate);
  String get scoreText => score <= 0 ? '-' : score.toStringAsFixed(1);

  factory StatsComboRow.fromJson(Object? value) {
    final json = _asMap(value);
    return StatsComboRow(
      heroAName: _readString(json, const [
        'hero_a_name',
        'hero1_name',
        'hero_name',
      ]),
      heroBName: _readString(json, const [
        'hero_b_name',
        'hero2_name',
        'partner_name',
      ]),
      matches: _readInt(json, const ['combo_matches', 'matches', 'sample']),
      winRate: _readRate(json, const ['win_rate', 'winRate']),
      score: _readDouble(json, const ['synergy_score', 'score', 'combo_score']),
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
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString();
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
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
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
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }
  }
  return 0;
}

double _readRate(Map<String, dynamic> json, List<String> keys) {
  final value = _readDouble(json, keys);
  if (value > 1) {
    return value / 100;
  }
  return value;
}

String _formatPercent(double value) {
  final normalized = value > 1 ? value / 100 : value;
  return '${(normalized * 100).toStringAsFixed(1)}%';
}
