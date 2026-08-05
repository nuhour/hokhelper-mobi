import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_list_footer.dart';
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
  static const _initialRows = 100;
  static const _rowBatch = 50;

  PlayerLeaderboardResult? _previousResult;
  var _visibleRows = _initialRows;

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
          final allPlayers = result.players;
          final players = allPlayers.take(_visibleRows).toList(growable: false);
          if (players.isEmpty) {
            return Column(
              children: [
                _LeaderboardControls(result: result),
                Expanded(
                  child: AppEmptyState(
                    icon: Icons.emoji_events_outlined,
                    title: AppLocalizations.of(context).noData,
                    message: AppLocalizations.of(context).serviceSlow,
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
                Expanded(
                  child: _LeaderboardTable(
                    players: players,
                    // 短名单不加页脚噪音，长名单滚动加载并提示到底。
                    showFooter: allPlayers.length > 10,
                    hasMore: _visibleRows < allPlayers.length,
                    onLoadMore: () => setState(() => _visibleRows += _rowBatch),
                  ),
                ),
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
            tooltip: AppLocalizations.of(context).translate('statsRefreshData'),
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
  const _LeaderboardTable({
    required this.players,
    this.showFooter = false,
    this.hasMore = false,
    this.onLoadMore,
  });

  final List<PlayerRankingEntry> players;
  final bool showFooter;
  final bool hasMore;
  final VoidCallback? onLoadMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankType = ref.watch(selectedPlayerLeaderboardRankTypeProvider);
    final l10n = AppLocalizations.of(context);
    return AppStatsTable(
      fixedHeader: Text(l10n.translate('statsPlayer')),
      // 首列固定，横向滚动时玩家身份列保持可见。
      fixedColumnWidth: 164,
      rowHeight: 66,
      fixedCells: [
        for (var index = 0; index < players.length; index++)
          _PlayerIdentityCell(player: players[index], rank: index + 1),
        // 页脚借表格末行的固定列单元格挂进纵向滚动区，
        // FittedBox 防止到底提示在窄列内溢出。
        if (showFooter)
          FittedBox(
            fit: BoxFit.scaleDown,
            child: AppListFooter(hasMore: hasMore, onLoadMore: onLoadMore),
          ),
      ],
      columns: [
        AppStatsTableColumn(
          label: rankType == PlayerLeaderboardRankType.ranked
              ? l10n.translate('statsStars')
              : l10n.homePeakScore,
          header: rankType == PlayerLeaderboardRankType.ranked
              ? Tooltip(
                  message: l10n.translate('statsStars'),
                  child: const Icon(Icons.star_rounded, size: 19),
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
            if (showFooter) const SizedBox.shrink(),
          ],
        ),
        AppStatsTableColumn(
          label: l10n.translate('statsWinRate'),
          width: 88,
          cells: [
            for (final player in players)
              _MetricText(
                player.winRate <= 0
                    ? '-'
                    : '${(player.winRate * 100).toStringAsFixed(2)}% win',
              ),
            if (showFooter) const SizedBox.shrink(),
          ],
        ),
        AppStatsTableColumn(
          label:
              '${l10n.translate('statsWins')} / ${l10n.translate('statsMatches')}',
          width: 98,
          cells: [
            for (final player in players)
              _MetricText(
                player.winRate <= 0
                    ? '- / ${player.playCount}'
                    : '${(player.playCount * player.winRate).round()} / ${player.playCount}',
              ),
            if (showFooter) const SizedBox.shrink(),
          ],
        ),
        if (rankType == PlayerLeaderboardRankType.ranked)
          AppStatsTableColumn(
            label: 'Rating',
            cells: [
              for (final player in players)
                _MetricText(player.grade.toStringAsFixed(2)),
              if (showFooter) const SizedBox.shrink(),
            ],
          ),
        AppStatsTableColumn(
          label: 'MVP',
          width: 72,
          cells: [
            for (final player in players) _MetricText('${player.mvpCount}'),
            if (showFooter) const SizedBox.shrink(),
          ],
        ),
        AppStatsTableColumn(
          label: 'Favorite Heroes',
          width: 168,
          cells: [
            for (final player in players)
              _BestHeroesCell(heroes: player.bestHeroes),
            if (showFooter) const SizedBox.shrink(),
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
              SizedBox(
                width: double.infinity,
                height: 18,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    player.playerName,
                    maxLines: 1,
                    softWrap: false,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: _playerNameFontSize(player.playerName),
                      color: colors?.onSurfaceStrong,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
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
          Expanded(
            child: Tooltip(
              message: [
                if (hero.heroName.isNotEmpty) hero.heroName,
                if (hero.topFight case final power? when power > 0)
                  'Power · ${_formatHeroPower(power)}',
              ].join(' · '),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppImage(
                    url: hero.avatarUrl,
                    width: 24,
                    height: 24,
                    borderRadius: 12,
                    semanticLabel: hero.heroName,
                  ),
                  if (hero.topFight case final power? when power > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      _formatHeroPower(power),
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 8,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.primary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

double _playerNameFontSize(String name) {
  final length = name.runes.length;
  if (length <= 10) return 14;
  if (length <= 14) return 13;
  if (length <= 18) return 12;
  if (length <= 24) return 11;
  return 10;
}

String _formatHeroPower(double value) {
  return value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
}
