import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_section_header.dart';
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
  @override
  void initState() {
    super.initState();
    Future<void>(() {
      if (!mounted) {
        return;
      }
      final initialRankType = widget.initialRankType;
      if (initialRankType != null) {
        ref.read(selectedPlayerLeaderboardRankTypeProvider.notifier).state =
            initialRankType;
      }
      final initialRegionId = widget.initialRegionId;
      if (initialRegionId != null) {
        ref.read(selectedPlayerLeaderboardRegionProvider.notifier).state =
            initialRegionId > 0 ? initialRegionId : 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final leaderboardValue = ref.watch(playerLeaderboardProvider);
    final rankType = ref.watch(selectedPlayerLeaderboardRankTypeProvider);
    final selectedRegion = ref.watch(selectedPlayerLeaderboardRegionProvider);

    return Material(
      color: AppTheme.bg,
      child: AppAsyncView<PlayerLeaderboardResult>(
        value: leaderboardValue,
        retry: () => ref.invalidate(playerLeaderboardProvider),
        data: (result) {
          final players = result.players.take(100).toList(growable: false);
          final regionOptions = <int>{
            if (selectedRegion > 0) selectedRegion,
            ...result.regionOptions,
          }.where((region) => region > 0).toList(growable: false)..sort();

          return RefreshIndicator(
            onRefresh: () => ref.refresh(playerLeaderboardProvider.future),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppSectionHeader(title: 'Player Leaderboard'),
                        const SizedBox(height: 8),
                        Text(
                          'Track top ranked and peak-score players worldwide.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.muted),
                        ),
                        const SizedBox(height: 16),
                        SegmentedButton<PlayerLeaderboardRankType>(
                          segments: PlayerLeaderboardRankType.values
                              .map((type) {
                                return ButtonSegment(
                                  value: type,
                                  label: Text(type.label),
                                );
                              })
                              .toList(growable: false),
                          selected: {rankType},
                          onSelectionChanged: (selection) {
                            final nextRankType = selection.single;
                            ref
                                    .read(
                                      selectedPlayerLeaderboardRankTypeProvider
                                          .notifier,
                                    )
                                    .state =
                                nextRankType;
                            _syncRouteQuery(
                              rankType: nextRankType,
                              regionId: selectedRegion,
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _RegionSelector(
                          selectedRegion: selectedRegion,
                          regionOptions: regionOptions,
                          onChanged: (region) {
                            ref
                                    .read(
                                      selectedPlayerLeaderboardRegionProvider
                                          .notifier,
                                    )
                                    .state =
                                region;
                            _syncRouteQuery(
                              rankType: rankType,
                              regionId: region,
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _LeaderboardSummary(
                          visible: players.length,
                          total: result.total,
                          rankType: rankType,
                          regionId: selectedRegion,
                        ),
                      ],
                    ),
                  ),
                ),
                if (players.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppEmptyState(
                      icon: Icons.emoji_events_outlined,
                      title: 'No players found',
                      message:
                          'Pull to refresh, switch rank type, or choose global.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverList.separated(
                      itemCount: players.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _PlayerLeaderboardCard(
                          player: players[index],
                          rank: index + 1,
                          rankType: rankType,
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _syncRouteQuery({
    required PlayerLeaderboardRankType rankType,
    required int regionId,
  }) {
    final router = GoRouter.maybeOf(context);
    if (router == null) {
      return;
    }

    final currentUri = router.routeInformationProvider.value.uri;
    final queryParameters = Map<String, String>.from(
      currentUri.queryParameters,
    );
    if (rankType == PlayerLeaderboardRankType.peak) {
      queryParameters['rank_type'] = PlayerLeaderboardRankType.peak.apiValue;
    } else {
      queryParameters.remove('rank_type');
    }
    if (regionId > 0) {
      queryParameters['region_id'] = '$regionId';
    } else {
      queryParameters.remove('region_id');
    }

    final nextUri = currentUri.replace(
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
    if (nextUri == currentUri) {
      return;
    }
    router.go(nextUri.toString());
  }
}

class _RegionSelector extends StatelessWidget {
  const _RegionSelector({
    required this.selectedRegion,
    required this.regionOptions,
    required this.onChanged,
  });

  final int selectedRegion;
  final List<int> regionOptions;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = [
      const DropdownMenuItem(value: 0, child: Text('Global')),
      ...regionOptions.map((region) {
        return DropdownMenuItem(value: region, child: Text('Region +$region'));
      }),
    ];

    return DropdownButtonFormField<int>(
      initialValue: selectedRegion,
      items: options,
      onChanged: (value) => onChanged(value ?? 0),
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.public_outlined),
        labelText: 'Region',
      ),
    );
  }
}

class _LeaderboardSummary extends StatelessWidget {
  const _LeaderboardSummary({
    required this.visible,
    required this.total,
    required this.rankType,
    required this.regionId,
  });

  final int visible;
  final int total;
  final PlayerLeaderboardRankType rankType;
  final int regionId;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          _SummaryChip(
            icon: Icons.emoji_events_outlined,
            label: '$visible / ${total <= 0 ? visible : total} players',
          ),
          _SummaryChip(
            icon: Icons.military_tech_outlined,
            label: rankType.label,
          ),
          _SummaryChip(
            icon: Icons.public_outlined,
            label: regionId <= 0 ? 'Global' : 'Region +$regionId',
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppTheme.gold),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.text,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PlayerLeaderboardCard extends StatelessWidget {
  const _PlayerLeaderboardCard({
    required this.player,
    required this.rank,
    required this.rankType,
  });

  final PlayerRankingEntry player;
  final int rank;
  final PlayerLeaderboardRankType rankType;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final noWinRateData = player.winRate <= 0;
    final wins = (player.playCount * player.winRate).round();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _RankBadge(rank: rank),
                const SizedBox(width: 12),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AppImage(
                      url: player.avatarUrl,
                      aspectRatio: 1,
                      width: 48,
                      height: 48,
                      borderRadius: 24,
                      semanticLabel: '${player.playerName} avatar',
                    ),
                    if (player.playerTypeLabel.isNotEmpty)
                      Positioned(
                        right: -6,
                        top: -6,
                        child: _PlayerTypeBadge(label: player.playerTypeLabel),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.playerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium?.copyWith(
                          color: AppTheme.text,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        player.region > 0
                            ? 'Region +${player.region}'
                            : 'Global',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppTheme.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  rankType == PlayerLeaderboardRankType.ranked
                      ? '${player.rankStars} stars'
                      : '${player.peakScore.toStringAsFixed(0)} peak',
                  style: textTheme.titleSmall?.copyWith(
                    color: AppTheme.gold,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetricPill(
                  label: noWinRateData
                      ? '- win'
                      : '${(player.winRate * 100).toStringAsFixed(2)}% win',
                ),
                _MetricPill(
                  label: noWinRateData
                      ? '${player.playCount} games'
                      : '$wins / ${player.playCount}',
                ),
                _MetricPill(label: 'MVP ${player.mvpCount}'),
                if (rankType == PlayerLeaderboardRankType.ranked)
                  _MetricPill(
                    label: 'Grade ${player.grade.toStringAsFixed(2)}',
                  ),
              ],
            ),
            if (player.bestHeroes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: player.bestHeroes
                    .take(3)
                    .map((hero) {
                      return _BestHeroPill(hero: hero);
                    })
                    .toList(growable: false),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    final color = switch (rank) {
      1 => AppTheme.gold,
      2 => AppTheme.cyan,
      3 => const Color(0xFFCD7F32),
      _ => AppTheme.muted,
    };

    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Text(
        '$rank',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PlayerTypeBadge extends StatelessWidget {
  const _PlayerTypeBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.cyan,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.black,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.panelAlt,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppTheme.text,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BestHeroPill extends StatelessWidget {
  const _BestHeroPill({required this.hero});

  final PlayerBestHero hero;

  @override
  Widget build(BuildContext context) {
    final heroLabel = hero.heroName.isEmpty
        ? 'Hero ${hero.heroId}'
        : hero.heroName;
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 5, 10, 5),
      decoration: BoxDecoration(
        color: AppTheme.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppImage(
            url: hero.avatarUrl,
            width: 22,
            height: 22,
            borderRadius: 11,
            semanticLabel: heroLabel,
          ),
          const SizedBox(width: 6),
          Text(
            '$heroLabel · ${hero.score.toStringAsFixed(1)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.gold,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
