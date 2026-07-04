class BpSchemeSummary {
  const BpSchemeSummary({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.boMode,
    required this.teamAName,
    required this.teamBName,
    required this.sideSelectionRule,
    required this.gameNumber,
    required this.historyCount,
    required this.currentStepIndex,
    required this.blueBanCount,
    required this.redBanCount,
    required this.bluePickCount,
    required this.redPickCount,
  });

  final String id;
  final String name;
  final String createdAt;
  final int boMode;
  final String teamAName;
  final String teamBName;
  final String sideSelectionRule;
  final int gameNumber;
  final int historyCount;
  final int currentStepIndex;
  final int blueBanCount;
  final int redBanCount;
  final int bluePickCount;
  final int redPickCount;

  String get matchupText {
    final left = teamAName.isEmpty ? 'Team A' : teamAName;
    final right = teamBName.isEmpty ? 'Team B' : teamBName;
    return '$left vs $right';
  }

  String get boModeText => 'BO$boMode';

  String get progressText {
    if (currentStepIndex <= 0) {
      return 'Game $gameNumber';
    }
    return 'Game $gameNumber · Step $currentStepIndex';
  }

  String get historyCountText {
    if (historyCount == 1) {
      return '1 game';
    }
    return '$historyCount games';
  }

  String get phaseSummaryText {
    final bans = blueBanCount + redBanCount;
    final picks = bluePickCount + redPickCount;
    return '$bans bans · $picks picks';
  }

  factory BpSchemeSummary.fromJson(Object? value) {
    final json = value is Map<String, dynamic>
        ? value
        : value is Map
        ? Map<String, dynamic>.from(value)
        : const <String, dynamic>{};
    final history = json['history'];
    final currentState = json['currentState'];
    final state = currentState is Map ? currentState : const {};

    return BpSchemeSummary(
      id: _readString(json['id'] ?? json['scheme_id']),
      name: _readString(json['name'], fallback: 'Untitled BP Scheme'),
      createdAt: _readString(json['createdAt'] ?? json['created_at']),
      boMode: _readInt(json['boMode'] ?? json['bo_mode'], fallback: 7),
      teamAName: _readString(json['teamAName'] ?? json['team_a_name']),
      teamBName: _readString(json['teamBName'] ?? json['team_b_name']),
      sideSelectionRule: _readString(
        json['sideSelectionRule'] ?? json['side_selection_rule'],
        fallback: 'loser_selects',
      ),
      gameNumber: _readInt(
        json['gameNumber'] ?? json['game_number'],
        fallback: 1,
      ),
      historyCount: history is List ? history.length : 0,
      currentStepIndex: _readInt(state['currentStepIndex']),
      blueBanCount: _readListLength(state['blueBans']),
      redBanCount: _readListLength(state['redBans']),
      bluePickCount: _readListLength(state['bluePicks']),
      redPickCount: _readListLength(state['redPicks']),
    );
  }
}

int _readListLength(Object? value) {
  if (value is List) {
    return value.length;
  }
  return 0;
}

int _readInt(Object? value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

String _readString(Object? value, {String fallback = ''}) {
  final text = value?.toString() ?? '';
  return text.trim().isEmpty ? fallback : text;
}
