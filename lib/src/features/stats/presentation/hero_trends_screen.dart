import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../settings/presentation/settings_controller.dart';
import '../domain/hero_trend_row.dart';
import 'stats_screen.dart';

enum HeroTrendSort {
  score('Score'),
  winRate('Win Rate'),
  mvpRate('MVP Rate'),
  damage('Damage'),
  takenDamage('Taken'),
  economy('Economy');

  const HeroTrendSort(this.label);

  final String label;

  double valueOf(HeroTrendRow row) {
    return switch (this) {
      HeroTrendSort.score => row.mvpScore,
      HeroTrendSort.winRate => row.winRate,
      HeroTrendSort.mvpRate => row.mvpRate,
      HeroTrendSort.damage => row.dmgShare,
      HeroTrendSort.takenDamage => row.takeDmgShare,
      HeroTrendSort.economy => row.ecoShare,
    };
  }
}

final selectedHeroTrendSortProvider = StateProvider<HeroTrendSort>((ref) {
  return HeroTrendSort.score;
});

final heroTrendsProvider = FutureProvider<List<HeroTrendRow>>((ref) async {
  final settings = await ref.watch(appSettingsControllerProvider.future);
  return ref
      .watch(statsRepositoryProvider)
      .loadHeroTrends(regionCode: settings.region.languageCode);
});

class HeroTrendsScreen extends ConsumerWidget {
  const HeroTrendsScreen({this.initialHeroId, super.key});

  final int? initialHeroId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendsValue = ref.watch(heroTrendsProvider);
    final sort = ref.watch(selectedHeroTrendSortProvider);

    return Material(
      color: AppTheme.bg,
      child: AppAsyncView<List<HeroTrendRow>>(
        value: trendsValue,
        retry: () => ref.invalidate(heroTrendsProvider),
        data: (rows) {
          final sortedRows = [...rows]
            ..sort((a, b) => sort.valueOf(b).compareTo(sort.valueOf(a)));
          final focusedHeroId = initialHeroId;
          if (focusedHeroId != null && focusedHeroId > 0) {
            final focusedIndex = sortedRows.indexWhere(
              (row) => row.id == focusedHeroId,
            );
            if (focusedIndex > 0) {
              final focusedRow = sortedRows.removeAt(focusedIndex);
              sortedRows.insert(0, focusedRow);
            }
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(heroTrendsProvider.future),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppSectionHeader(title: 'Hero Trends'),
                        const SizedBox(height: 8),
                        Text(
                          'Deep dive into hero performance metrics across the current season.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.muted),
                        ),
                        const SizedBox(height: 16),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SegmentedButton<HeroTrendSort>(
                            segments: HeroTrendSort.values
                                .map((metric) {
                                  return ButtonSegment(
                                    value: metric,
                                    label: Text(metric.label),
                                  );
                                })
                                .toList(growable: false),
                            selected: {sort},
                            onSelectionChanged: (selection) {
                              ref
                                  .read(selectedHeroTrendSortProvider.notifier)
                                  .state = selection
                                  .single;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (sortedRows.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppEmptyState(
                      icon: Icons.trending_up_outlined,
                      title: 'No trend data',
                      message: 'Pull to refresh or switch region in settings.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    sliver: SliverList.separated(
                      itemCount: sortedRows.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _HeroTrendCard(
                          hero: sortedRows[index],
                          rank: index + 1,
                          isFocused: sortedRows[index].id == focusedHeroId,
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
}

class _HeroTrendCard extends StatelessWidget {
  const _HeroTrendCard({
    required this.hero,
    required this.rank,
    required this.isFocused,
  });

  final HeroTrendRow hero;
  final int rank;
  final bool isFocused;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/heroes/${hero.id}'),
        child: DecoratedBox(
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
                    AppImage(
                      url: hero.avatarUrl,
                      width: 48,
                      height: 48,
                      borderRadius: 14,
                      aspectRatio: 1,
                      semanticLabel: hero.name,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hero.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleMedium?.copyWith(
                              color: AppTheme.text,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (isFocused)
                                const _MetricPill(
                                  label: 'Focused hero',
                                  color: AppTheme.gold,
                                ),
                              _MetricPill(label: 'Score ${hero.mvpScoreText}'),
                              _MetricPill(label: '${hero.winRateText} win'),
                              _MetricPill(label: '${hero.mvpRateText} MVP'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _ShareBar(
                  label: '${hero.dmgShareText} damage',
                  value: hero.dmgShare,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 8),
                _ShareBar(
                  label: '${hero.takeDmgShareText} taken',
                  value: hero.takeDmgShare,
                  color: Colors.lightBlueAccent,
                ),
                const SizedBox(height: 8),
                _ShareBar(
                  label: '${hero.ecoShareText} economy',
                  value: hero.ecoShare,
                  color: AppTheme.gold,
                ),
              ],
            ),
          ),
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
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppTheme.gold.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(17),
      ),
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

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: tint?.withValues(alpha: 0.14) ?? AppTheme.panelAlt,
        borderRadius: BorderRadius.circular(999),
        border: tint == null
            ? null
            : Border.all(color: tint.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: tint ?? AppTheme.text,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ShareBar extends StatelessWidget {
  const _ShareBar({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final normalized = value.clamp(0, 100) / 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: normalized.toDouble(),
            minHeight: 7,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
