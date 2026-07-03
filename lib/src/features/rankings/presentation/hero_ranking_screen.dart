import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../settings/presentation/settings_controller.dart';
import '../data/rankings_repository.dart';
import '../domain/hero_ranking_entry.dart';

enum HeroRankingSort {
  winRate('win_rate', 'Win'),
  pickRate('pick_rate', 'Pick'),
  banRate('ban_rate', 'Ban'),
  mvpRate('mvp_rate', 'MVP');

  const HeroRankingSort(this.apiValue, this.label);

  final String apiValue;
  final String label;
}

final rankingsRepositoryProvider = Provider<RankingsRepository>((ref) {
  return RankingsRepository(apiClient: ref.watch(apiClientProvider));
});

final selectedHeroRankingSortProvider = StateProvider<HeroRankingSort>((ref) {
  return HeroRankingSort.winRate;
});

final heroRankingProvider = FutureProvider<List<HeroRankingEntry>>((ref) async {
  final settings = await ref.watch(appSettingsControllerProvider.future);
  final sort = ref.watch(selectedHeroRankingSortProvider);
  return ref
      .watch(rankingsRepositoryProvider)
      .loadHeroRanking(settings.region.regionId, sortBy: sort.apiValue);
});

class HeroRankingScreen extends ConsumerWidget {
  const HeroRankingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingValue = ref.watch(heroRankingProvider);
    final selectedSort = ref.watch(selectedHeroRankingSortProvider);

    return AppAsyncView<List<HeroRankingEntry>>(
      value: rankingValue,
      retry: () => ref.invalidate(heroRankingProvider),
      data: (entries) {
        return RefreshIndicator(
          onRefresh: () => ref.refresh(heroRankingProvider.future),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppSectionHeader(title: 'Hero Rankings'),
                      const SizedBox(height: 8),
                      Text(
                        'Compare heroes by live performance metrics.',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
                      ),
                      const SizedBox(height: 16),
                      _SortSelector(selectedSort: selectedSort),
                    ],
                  ),
                ),
              ),
              if (entries.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppEmptyState(
                    icon: Icons.leaderboard_outlined,
                    title: 'No rankings found',
                    message: 'Pull to refresh or switch region in settings.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  sliver: SliverList.separated(
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      return _HeroRankingCard(
                        entry: entries[index],
                        rank: index + 1,
                      );
                    },
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SortSelector extends ConsumerWidget {
  const _SortSelector({required this.selectedSort});

  final HeroRankingSort selectedSort;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SegmentedButton<HeroRankingSort>(
      segments: HeroRankingSort.values
          .map(
            (sort) => ButtonSegment<HeroRankingSort>(
              value: sort,
              label: Text(sort.label),
            ),
          )
          .toList(growable: false),
      selected: {selectedSort},
      onSelectionChanged: (selection) {
        ref.read(selectedHeroRankingSortProvider.notifier).state =
            selection.single;
      },
      showSelectedIcon: false,
    );
  }
}

class _HeroRankingCard extends StatelessWidget {
  const _HeroRankingCard({required this.entry, required this.rank});

  final HeroRankingEntry entry;
  final int rank;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panel,
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _RankBadge(rank: rank),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        entry.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppTheme.text,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.mainJob.isEmpty ? 'Hero' : entry.mainJob,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                      ),
                    ],
                  ),
                ),
                _PrimaryRate(value: entry.winRate),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetricChip(
                  label: 'Pick',
                  value: _formatPercent(entry.pickRate),
                ),
                _MetricChip(label: 'Ban', value: _formatPercent(entry.banRate)),
                _MetricChip(label: 'MVP', value: _formatPercent(entry.mvpRate)),
                _MetricChip(
                  label: 'K',
                  value: entry.avgKills.toStringAsFixed(1),
                ),
                _MetricChip(
                  label: 'A',
                  value: entry.avgAssists.toStringAsFixed(1),
                ),
                _MetricChip(
                  label: 'Grade',
                  value: entry.avgGrade.toStringAsFixed(1),
                ),
              ],
            ),
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
    return CircleAvatar(
      radius: 22,
      backgroundColor: AppTheme.gold.withValues(alpha: 0.16),
      child: Text(
        '#$rank',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: AppTheme.gold,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PrimaryRate extends StatelessWidget {
  const _PrimaryRate({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatPercent(value),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.gold,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          'Win rate',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
        ),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panelAlt,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Text(
          '$label $value',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppTheme.text,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

String _formatPercent(double value) {
  return '${(value * 100).toStringAsFixed(1)}%';
}
