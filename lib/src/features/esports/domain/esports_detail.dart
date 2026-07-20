import 'esports_match_summary.dart';
import 'esports_player_summary.dart';
import 'esports_team_summary.dart';

class EsportsTeamDetail {
  const EsportsTeamDetail({
    required this.team,
    required this.nation,
    required this.description,
    required this.groupImageUrl,
    required this.battleCount,
    required this.stats,
    required this.honors,
    required this.members,
    required this.recentMatches,
  });

  final EsportsTeamSummary team;
  final String nation;
  final String description;
  final String groupImageUrl;
  final int battleCount;
  final Map<String, Object?> stats;
  final List<EsportsHonor> honors;
  final List<EsportsTeamMember> members;
  final List<EsportsMatchSummary> recentMatches;

  factory EsportsTeamDetail.fromJson(Object? json) {
    final map = _readMap(json);
    final profile = _readMap(map['team_profile']);
    final eventStats = _readMap(map['event_stats']);
    final rankStats = _readMap(
      eventStats['team_rank_stat'] ?? map['rank_stat'],
    );
    final memberRows = _readList(map['members'] ?? map['players']);
    final honorRows = _readList(profile['honor_list']);
    final matchRows = _readList(map['recent_matches']);
    return EsportsTeamDetail(
      team: EsportsTeamSummary.fromJson(map),
      nation: _readString(profile['team_nation']),
      description: _readString(profile['team_desc']),
      groupImageUrl: _readString(profile['team_group_pic']),
      battleCount: _readInt(map['battle_count'] ?? rankStats['battleCount']),
      stats: rankStats,
      honors: honorRows.map(EsportsHonor.fromJson).toList(growable: false),
      members: memberRows
          .map(EsportsTeamMember.fromJson)
          .toList(growable: false),
      recentMatches: matchRows
          .map(EsportsMatchSummary.fromJson)
          .toList(growable: false),
    );
  }
}

class EsportsPlayerDetail {
  const EsportsPlayerDetail({
    required this.player,
    required this.eventStats,
    required this.commonHeroes,
    required this.recentMatches,
  });

  final EsportsPlayerSummary player;
  final List<EsportsMetricItem> eventStats;
  final List<EsportsCommonHero> commonHeroes;
  final List<EsportsMatchSummary> recentMatches;

  factory EsportsPlayerDetail.fromJson(Object? json) {
    final map = _readMap(json);
    return EsportsPlayerDetail(
      player: EsportsPlayerSummary.fromJson(map),
      eventStats: _readList(
        map['event_stats'],
      ).map(EsportsMetricItem.fromJson).toList(growable: false),
      commonHeroes: _readList(
        map['common_heroes'],
      ).map(EsportsCommonHero.fromJson).toList(growable: false),
      recentMatches: _readList(
        map['recent_matches'],
      ).map(EsportsMatchSummary.fromJson).toList(growable: false),
    );
  }
}

class EsportsHonor {
  const EsportsHonor({required this.name, required this.title});

  final String name;
  final String title;

  factory EsportsHonor.fromJson(Object? json) {
    final map = _readMap(json);
    return EsportsHonor(
      name: _readString(map['name'], fallback: '--'),
      title: _readString(map['title_name'] ?? map['title_key'], fallback: '--'),
    );
  }
}

class EsportsTeamMember {
  const EsportsTeamMember({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.role,
    required this.roleKey,
  });

  final String id;
  final String name;
  final String avatarUrl;
  final String role;
  final String roleKey;

  String get roleLabel => esportsRoleLabel(roleKey, fallback: role);

  factory EsportsTeamMember.fromJson(Object? json) {
    final map = _readMap(json);
    return EsportsTeamMember(
      id: _readString(map['source_id'] ?? map['id']),
      name: _readString(map['name'], fallback: 'Player'),
      avatarUrl: _readString(map['avatar_url']),
      role: _readString(map['role']),
      roleKey: _readString(map['role_key']),
    );
  }
}

class EsportsMetricItem {
  const EsportsMetricItem({
    required this.key,
    required this.label,
    required this.value,
  });

  final String key;
  final String label;
  final String value;

  factory EsportsMetricItem.fromJson(Object? json) {
    final map = _readMap(json);
    return EsportsMetricItem(
      key: _readString(map['dimension']),
      label: _readString(map['dimension_desc']),
      value: _readString(map['display_value'] ?? map['value']),
    );
  }
}

class EsportsCommonHero {
  const EsportsCommonHero({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.matches,
    required this.winRate,
    required this.kda,
    required this.participationRate,
  });

  final String id;
  final String name;
  final String imageUrl;
  final int matches;
  final double winRate;
  final double kda;
  final double participationRate;

  factory EsportsCommonHero.fromJson(Object? json) {
    final map = _readMap(json);
    final hero = _readMap(map['hero']);
    return EsportsCommonHero(
      id: _readString(hero['id'] ?? hero['hero_id']),
      name: _readString(hero['hero_name'], fallback: 'Hero'),
      imageUrl: _readString(hero['hero_icon']),
      matches: _readInt(map['battle_count']),
      winRate: _readRate(map['win_rate']),
      kda: _readDouble(map['avg_kda']),
      participationRate: _readRate(map['avg_participation_rate']),
    );
  }
}

Map<String, Object?> _readMap(Object? value) {
  if (value is! Map) {
    return const {};
  }
  return value.map((key, value) => MapEntry(key.toString(), value));
}

List<Object?> _readList(Object? value) {
  return value is List ? value : const [];
}

String _readString(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

int _readInt(Object? value) {
  if (value is int) {
    return value;
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _readDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

double _readRate(Object? value) {
  final rate = _readDouble(value);
  return rate > 1 ? rate / 100 : rate;
}
