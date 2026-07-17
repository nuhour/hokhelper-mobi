import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_stats_table.dart';
import '../../../core/widgets/region_country_picker.dart';
import '../domain/player_leaderboard_result.dart';
import '../domain/player_ranking_entry.dart';
import 'hero_ranking_screen.dart';

enum PlayerLeaderboardRankType {
  ranked('rank', 'Ranked'),
  peak('peak', 'Peak');

  const PlayerLeaderboardRankType(this.apiValue, this.label);

  final String apiValue;
  final String label;
}

final selectedPlayerLeaderboardRankTypeProvider =
    StateProvider<PlayerLeaderboardRankType>((ref) {
      return PlayerLeaderboardRankType.ranked;
    });

final selectedPlayerLeaderboardRegionProvider = StateProvider<int>((ref) {
  return 0;
});

final playerLeaderboardProvider = FutureProvider<PlayerLeaderboardResult>((
  ref,
) async {
  final rankType = ref.watch(selectedPlayerLeaderboardRankTypeProvider);
  final regionId = ref.watch(selectedPlayerLeaderboardRegionProvider);
  return ref
      .watch(rankingsRepositoryProvider)
      .loadPlayerLeaderboard(
        regionId: regionId,
        rankType: rankType.apiValue,
        limit: 200,
      );
});

class PlayerLeaderboardScreen extends ConsumerStatefulWidget {
  const PlayerLeaderboardScreen({
    this.initialRankType,
    this.initialRegionId,
    super.key,
  });

  final PlayerLeaderboardRankType? initialRankType;
  final int? initialRegionId;

  @override
  ConsumerState<PlayerLeaderboardScreen> createState() =>
      _PlayerLeaderboardScreenState();
}

class _PlayerLeaderboardScreenState
    extends ConsumerState<PlayerLeaderboardScreen> {
  PlayerLeaderboardResult? _previousResult;

  @override
  void initState() {
    super.initState();
    Future<void>(() {
      if (!mounted) {
        return;
      }
      if (widget.initialRankType case final initialRankType?) {
        ref.read(selectedPlayerLeaderboardRankTypeProvider.notifier).state =
            initialRankType;
      }
      if (widget.initialRegionId case final initialRegionId?) {
        ref.read(selectedPlayerLeaderboardRegionProvider.notifier).state =
            initialRegionId > 0 ? initialRegionId : 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final leaderboardValue = ref.watch(playerLeaderboardProvider);
    final loadedResult = leaderboardValue.valueOrNull;
    if (loadedResult != null) {
      _previousResult = loadedResult;
    }

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: AppAsyncView<PlayerLeaderboardResult>(
        value: leaderboardValue,
        previousData: _previousResult,
        loadingStyle: AppAsyncLoadingStyle.dashboard,
        retry: () => ref.invalidate(playerLeaderboardProvider),
        data: (result) {
          final players = result.players.take(100).toList(growable: false);
          if (players.isEmpty) {
            return Column(
              children: [
                _LeaderboardControls(result: result),
                const Expanded(
                  child: AppEmptyState(
                    icon: Icons.emoji_events_outlined,
                    title: 'No players found',
                    message: 'Switch rank type, region, or retry.',
                  ),
                ),
              ],
            );
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            child: Column(
              children: [
                _LeaderboardControls(result: result),
                const SizedBox(height: 8),
                Expanded(child: _LeaderboardTable(players: players)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LeaderboardControls extends ConsumerWidget {
  const _LeaderboardControls({required this.result});

  final PlayerLeaderboardResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedType = ref.watch(selectedPlayerLeaderboardRankTypeProvider);
    final selectedRegion = ref.watch(selectedPlayerLeaderboardRegionProvider);
    final regions = <int>{
      if (selectedRegion > 0) selectedRegion,
      ...result.regionOptions,
    }.where((region) => region > 0).toList(growable: false)..sort();

    return SizedBox(
      height: 44,
      child: Row(
        children: [
          Expanded(
            child: SegmentedButton<PlayerLeaderboardRankType>(
              segments: PlayerLeaderboardRankType.values
                  .map(
                    (type) =>
                        ButtonSegment(value: type, label: Text(type.label)),
                  )
                  .toList(growable: false),
              selected: {selectedType},
              showSelectedIcon: false,
              onSelectionChanged: (selection) {
                final nextType = selection.single;
                ref
                        .read(
                          selectedPlayerLeaderboardRankTypeProvider.notifier,
                        )
                        .state =
                    nextType;
                _syncLeaderboardRoute(
                  context,
                  rankType: nextType,
                  regionId: selectedRegion,
                );
              },
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          const SizedBox(width: 8),
          RegionCountryPicker(
            value: selectedRegion,
            options: regions,
            onChanged: (nextRegion) {
              ref.read(selectedPlayerLeaderboardRegionProvider.notifier).state =
                  nextRegion;
              _syncLeaderboardRoute(
                context,
                rankType: selectedType,
                regionId: nextRegion,
              );
            },
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(playerLeaderboardProvider),
            icon: const Icon(Icons.refresh_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}

void _syncLeaderboardRoute(
  BuildContext context, {
  required PlayerLeaderboardRankType rankType,
  required int regionId,
}) {
  final router = GoRouter.maybeOf(context);
  if (router == null) {
    return;
  }
  final currentUri = router.routeInformationProvider.value.uri;
  final query = Map<String, String>.from(currentUri.queryParameters);
  if (rankType == PlayerLeaderboardRankType.peak) {
    query['rank_type'] = rankType.apiValue;
  } else {
    query.remove('rank_type');
  }
  if (regionId > 0) {
    query['region_id'] = '$regionId';
  } else {
    query.remove('region_id');
  }
  final nextUri = currentUri.replace(
    queryParameters: query.isEmpty ? null : query,
  );
  if (nextUri != currentUri) {
    router.go(nextUri.toString());
  }
}

class _LeaderboardTable extends ConsumerWidget {
  const _LeaderboardTable({required this.players});

  final List<PlayerRankingEntry> players;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankType = ref.watch(selectedPlayerLeaderboardRankTypeProvider);
    return AppStatsTable(
      fixedHeader: const Text('Player'),
      fixedColumnWidth: 164,
      rowHeight: 66,
      fixedCells: [
        for (var index = 0; index < players.length; index++)
          _PlayerIdentityCell(player: players[index], rank: index + 1),
      ],
      columns: [
        AppStatsTableColumn(
          label: rankType == PlayerLeaderboardRankType.ranked
              ? 'Stars'
              : 'Peak Score',
          header: rankType == PlayerLeaderboardRankType.ranked
              ? const Tooltip(
                  message: 'Stars',
                  child: Icon(Icons.star_rounded, size: 19),
                )
              : null,
          width: 92,
          cells: [
            for (final player in players)
              rankType == PlayerLeaderboardRankType.ranked
                  ? _StarsMetric(value: player.rankStars)
                  : _MetricText(
                      player.peakScore.toStringAsFixed(0),
                      highlight: true,
                    ),
          ],
        ),
        AppStatsTableColumn(
          label: 'Win Rate',
          width: 88,
          cells: [
            for (final player in players)
              _MetricText(
                player.winRate <= 0
                    ? '-'
                    : '${(player.winRate * 100).toStringAsFixed(2)}% win',
              ),
          ],
        ),
        AppStatsTableColumn(
          label: 'Wins / Games',
          width: 98,
          cells: [
            for (final player in players)
              _MetricText(
                player.winRate <= 0
                    ? '- / ${player.playCount}'
                    : '${(player.playCount * player.winRate).round()} / ${player.playCount}',
              ),
          ],
        ),
        if (rankType == PlayerLeaderboardRankType.ranked)
          AppStatsTableColumn(
            label: 'Rating',
            cells: [
              for (final player in players)
                _MetricText(player.grade.toStringAsFixed(2)),
            ],
          ),
        AppStatsTableColumn(
          label: 'MVP',
          width: 72,
          cells: [
            for (final player in players) _MetricText('${player.mvpCount}'),
          ],
        ),
        AppStatsTableColumn(
          label: 'KDA',
          width: 72,
          cells: [
            for (final player in players)
              _MetricText(player.avgKda.toStringAsFixed(1)),
          ],
        ),
        AppStatsTableColumn(
          label: 'Favorite Heroes',
          width: 168,
          cells: [
            for (final player in players)
              _BestHeroesCell(heroes: player.bestHeroes),
          ],
        ),
      ],
    );
  }
}

class _PlayerIdentityCell extends StatelessWidget {
  const _PlayerIdentityCell({required this.player, required this.rank});

  final PlayerRankingEntry player;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<HokThemeColors>();
    return Row(
      children: [
        SizedBox(
          width: 24,
          child: Text(
            '$rank',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: rank <= 3
                  ? Theme.of(context).colorScheme.primary
                  : colors?.onSurfaceMuted,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            AppImage(
              url: player.avatarUrl,
              width: 36,
              height: 36,
              borderRadius: 18,
              semanticLabel: '${player.playerName} avatar',
            ),
            if (player.playerTypeLabel.isNotEmpty)
              Positioned(
                right: -4,
                bottom: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    player.playerTypeLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                player.playerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colors?.onSurfaceStrong,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Row(
                children: [
                  RegionFlag(regionCode: player.region, width: 17),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      RegionCountry.fromRegionCode(player.region)?.isoCode ??
                          'Global',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors?.onSurfaceMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricText extends StatelessWidget {
  const _MetricText(this.value, {this.highlight = false});

  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<HokThemeColors>();
    return Text(
      value,
      maxLines: 1,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: highlight
            ? Theme.of(context).colorScheme.primary
            : colors?.onSurfaceStrong,
        fontFeatures: const [FontFeature.tabularFigures()],
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _StarsMetric extends StatelessWidget {
  const _StarsMetric({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, size: 17, color: Color(0xFFF2B705)),
        const SizedBox(width: 3),
        _MetricText('$value', highlight: true),
      ],
    );
  }
}

class _BestHeroesCell extends StatelessWidget {
  const _BestHeroesCell({required this.heroes});

  final List<PlayerBestHero> heroes;

  @override
  Widget build(BuildContext context) {
    if (heroes.isEmpty) {
      return const Text('-');
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final hero in heroes.take(3))
          Tooltip(
            message: hero.score > 0
                ? '${hero.heroName} · ${hero.score.toStringAsFixed(1)}'
                : hero.heroName,
            child: AppImage(
              url: hero.avatarUrl,
              width: 34,
              height: 34,
              borderRadius: 17,
              semanticLabel: hero.heroName,
            ),
          ),
      ],
    );
  }
}
