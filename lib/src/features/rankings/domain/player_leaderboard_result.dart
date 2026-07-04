import 'player_ranking_entry.dart';

class PlayerLeaderboardResult {
  const PlayerLeaderboardResult({
    required this.players,
    required this.total,
    required this.regionId,
    required this.rankType,
    required this.regionOptions,
  });

  final List<PlayerRankingEntry> players;
  final int total;
  final int regionId;
  final String rankType;
  final List<int> regionOptions;
}
