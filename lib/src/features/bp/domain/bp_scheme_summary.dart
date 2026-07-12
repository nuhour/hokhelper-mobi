class BpDraftState {
  const BpDraftState({
    this.blueBans = const [null, null, null, null, null],
    this.redBans = const [null, null, null, null, null],
    this.bluePicks = const [null, null, null, null, null],
    this.redPicks = const [null, null, null, null, null],
    this.currentStepIndex = 0,
    this.isStarted = false,
    this.isSaved = false,
    this.timeLeft = 45,
    this.gameWinner,
  });

  final List<int?> blueBans;
  final List<int?> redBans;
  final List<int?> bluePicks;
  final List<int?> redPicks;
  final int currentStepIndex;
  final bool isStarted;
  final bool isSaved;
  final int timeLeft;
  final String? gameWinner;

  factory BpDraftState.fromJson(Object? value) {
    final json = value is Map<String, dynamic>
        ? value
        : value is Map
        ? Map<String, dynamic>.from(value)
        : const <String, dynamic>{};
    final blueBans = _readSlots(json['blueBans']);
    final redBans = _readSlots(json['redBans']);
    final bluePicks = _readSlots(json['bluePicks']);
    final redPicks = _readSlots(json['redPicks']);
    final currentStepIndex = _readInt(json['currentStepIndex']);
    final isSaved = json['isSaved'] == true;
    final hasDraftState = [
      ...blueBans,
      ...redBans,
      ...bluePicks,
      ...redPicks,
    ].any((heroId) => heroId != null);
    return BpDraftState(
      blueBans: blueBans,
      redBans: redBans,
      bluePicks: bluePicks,
      redPicks: redPicks,
      currentStepIndex: currentStepIndex,
      // Django 仅保存棋盘与步骤；恢复未完成对局时按 HOKX 的规则继续 BP。
      isStarted: json.containsKey('isStarted')
          ? json['isStarted'] == true
          : json.isNotEmpty &&
                (!isSaved || currentStepIndex > 0 || hasDraftState),
      isSaved: isSaved,
      timeLeft: _readInt(json['timeLeft'], fallback: 45).clamp(1, 45),
      gameWinner: _readWinner(json['gameWinner'] ?? json['winner']),
    );
  }

  Map<String, dynamic> toJson() => {
    'blueBans': blueBans,
    'redBans': redBans,
    'bluePicks': bluePicks,
    'redPicks': redPicks,
    'currentStepIndex': currentStepIndex,
    'isStarted': isStarted,
    'isSaved': isSaved,
    'timeLeft': timeLeft,
    'gameWinner': gameWinner,
  };

  int get blueBanCount => _countHeroes(blueBans);
  int get redBanCount => _countHeroes(redBans);
  int get bluePickCount => _countHeroes(bluePicks);
  int get redPickCount => _countHeroes(redPicks);
}

class BpHistoryGame {
  const BpHistoryGame({
    required this.gameNumber,
    required this.blueTeamId,
    required this.redTeamId,
    this.blueBans = const [null, null, null, null, null],
    this.redBans = const [null, null, null, null, null],
    required this.bluePicks,
    required this.redPicks,
    this.mode = 'standard',
    this.winner,
  });

  final int gameNumber;
  final String blueTeamId;
  final String redTeamId;
  final List<int?> blueBans;
  final List<int?> redBans;
  final List<int?> bluePicks;
  final List<int?> redPicks;
  final String mode;
  final String? winner;

  factory BpHistoryGame.fromJson(Object? value) {
    final json = value is Map<String, dynamic>
        ? value
        : value is Map
        ? Map<String, dynamic>.from(value)
        : const <String, dynamic>{};
    return BpHistoryGame(
      gameNumber: _readInt(json['gameNumber'] ?? json['game_number']),
      blueTeamId: _readString(json['blueTeamId'] ?? json['blue_team_id']),
      redTeamId: _readString(json['redTeamId'] ?? json['red_team_id']),
      blueBans: _readSlots(json['blueBans'] ?? json['blue_bans']),
      redBans: _readSlots(json['redBans'] ?? json['red_bans']),
      bluePicks: _readSlots(json['bluePicks'] ?? json['blue_picks']),
      redPicks: _readSlots(json['redPicks'] ?? json['red_picks']),
      mode: _readString(json['mode'], fallback: 'standard'),
      winner: _readWinner(json['winner'] ?? json['gameWinner']),
    );
  }

  Map<String, dynamic> toJson() => {
    'gameNumber': gameNumber,
    'blueTeamId': blueTeamId,
    'redTeamId': redTeamId,
    'blueBans': _savedSlots(blueBans),
    'redBans': _savedSlots(redBans),
    'bluePicks': _savedSlots(bluePicks),
    'redPicks': _savedSlots(redPicks),
    'mode': mode,
    'winner': winner,
  };
}

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
    this.blueBanHeroIds = const [],
    this.redBanHeroIds = const [],
    this.bluePickHeroIds = const [],
    this.redPickHeroIds = const [],
    this.teamAId = 'team_a',
    this.teamBId = 'team_b',
    this.draftState = const BpDraftState(),
    this.history = const [],
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
  final List<int> blueBanHeroIds;
  final List<int> redBanHeroIds;
  final List<int> bluePickHeroIds;
  final List<int> redPickHeroIds;
  final String teamAId;
  final String teamBId;
  final BpDraftState draftState;
  final List<BpHistoryGame> history;

  bool get hasCurrentBoardHeroes {
    return blueBanHeroIds.isNotEmpty ||
        redBanHeroIds.isNotEmpty ||
        bluePickHeroIds.isNotEmpty ||
        redPickHeroIds.isNotEmpty;
  }

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
    final state = BpDraftState.fromJson(currentState);
    final parsedHistory = history is List
        ? history.map(BpHistoryGame.fromJson).toList(growable: false)
        : const <BpHistoryGame>[];

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
      teamAId: _readString(
        json['teamAId'] ?? json['team_a_id'],
        fallback: 'team_a',
      ),
      teamBId: _readString(
        json['teamBId'] ?? json['team_b_id'],
        fallback: 'team_b',
      ),
      gameNumber: _readInt(
        json['gameNumber'] ?? json['game_number'],
        fallback: 1,
      ),
      historyCount: parsedHistory.length,
      currentStepIndex: state.currentStepIndex,
      blueBanCount: state.blueBanCount,
      redBanCount: state.redBanCount,
      bluePickCount: state.bluePickCount,
      redPickCount: state.redPickCount,
      blueBanHeroIds: _readHeroIds(state.blueBans),
      redBanHeroIds: _readHeroIds(state.redBans),
      bluePickHeroIds: _readHeroIds(state.bluePicks),
      redPickHeroIds: _readHeroIds(state.redPicks),
      draftState: state,
      history: parsedHistory,
    );
  }
}

List<int?> _readSlots(Object? value) {
  final values = value is List ? value : const [];
  final slots = values
      .take(5)
      .map((item) {
        if (item == null) return null;
        if (item is Map) {
          final id = _readInt(
            item['hero_id'] ??
                item['heroId'] ??
                item['id'] ??
                item['hero'] ??
                item['value'],
          );
          return id == 0 ? null : id;
        }
        if (item is String && item.startsWith('mobile-')) return -2;
        final id = _readInt(item);
        return id == 0 ? null : id;
      })
      .toList(growable: true);
  while (slots.length < 5) {
    slots.add(null);
  }
  return List.unmodifiable(slots);
}

int _countHeroes(List<int?> slots) =>
    slots.where((id) => id != null && id != -1).length;

String? _readWinner(Object? value) {
  final winner = value?.toString().trim().toLowerCase();
  return winner == 'blue' || winner == 'red' ? winner : null;
}

List<int> _readHeroIds(Object? value) {
  if (value is! List) {
    return const [];
  }
  return value
      .map((item) {
        if (item is Map) {
          return _readInt(
            item['hero_id'] ??
                item['heroId'] ??
                item['id'] ??
                item['hero'] ??
                item['value'],
          );
        }
        return _readInt(item);
      })
      .where((id) => id > 0)
      .toList(growable: false);
}

List<int> _savedSlots(List<int?> slots) =>
    slots.whereType<int>().toList(growable: false);

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
