import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_stats_table.dart';
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

class HeroTrendsScreen extends ConsumerStatefulWidget {
  const HeroTrendsScreen({this.initialHeroId, super.key});

  final int? initialHeroId;

  @override
  ConsumerState<HeroTrendsScreen> createState() => _HeroTrendsScreenState();
}

class _HeroTrendsScreenState extends ConsumerState<HeroTrendsScreen> {
  List<HeroTrendRow>? _previousRows;

  @override
  Widget build(BuildContext context) {
    final trendsValue = ref.watch(heroTrendsProvider);
    final loadedRows = trendsValue.valueOrNull;
    if (loadedRows != null) {
      _previousRows = loadedRows;
    }

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: AppAsyncView<List<HeroTrendRow>>(
        value: trendsValue,
        previousData: _previousRows,
        loadingStyle: AppAsyncLoadingStyle.dashboard,
        retry: () => ref.invalidate(heroTrendsProvider),
        data: (rows) {
          if (rows.isEmpty) {
            return const AppEmptyState(
              icon: Icons.trending_up_outlined,
              title: 'No trend data',
              message: 'Pull to refresh or switch region in settings.',
            );
          }

          final sort = ref.watch(selectedHeroTrendSortProvider);
          final sortedRows = [...rows]
            ..sort((a, b) => sort.valueOf(b).compareTo(sort.valueOf(a)));
          final focusedHeroId = widget.initialHeroId;
          if (focusedHeroId != null && focusedHeroId > 0) {
            final focusedIndex = sortedRows.indexWhere(
              (row) => row.id == focusedHeroId,
            );
            if (focusedIndex > 0) {
              final focusedRow = sortedRows.removeAt(focusedIndex);
              sortedRows.insert(0, focusedRow);
            }
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            child: Column(
              children: [
                _TableToolbar(
                  title: 'Hero Trends',
                  count: sortedRows.length,
                  onRefresh: () => ref.invalidate(heroTrendsProvider),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: AppStatsTable(
                    fixedHeader: const Text('Hero'),
                    fixedColumnWidth: 144,
                    fixedCells: [
                      for (var index = 0; index < sortedRows.length; index++)
                        _HeroIdentityCell(
                          hero: sortedRows[index],
                          rank: index + 1,
                          focused: sortedRows[index].id == focusedHeroId,
                        ),
                    ],
                    columns: [
                      _metricColumn(
                        metric: HeroTrendSort.score,
                        selected: sort,
                        rows: sortedRows,
                        value: (row) => row.mvpScoreText,
                      ),
                      _metricColumn(
                        metric: HeroTrendSort.winRate,
                        selected: sort,
                        rows: sortedRows,
                        value: (row) => row.winRateText,
                      ),
                      _metricColumn(
                        metric: HeroTrendSort.mvpRate,
                        selected: sort,
                        rows: sortedRows,
                        value: (row) => row.mvpRateText,
                      ),
                      _metricColumn(
                        metric: HeroTrendSort.damage,
                        selected: sort,
                        rows: sortedRows,
                        value: (row) => row.dmgShareText,
                      ),
                      _metricColumn(
                        metric: HeroTrendSort.takenDamage,
                        selected: sort,
                        rows: sortedRows,
                        value: (row) => row.takeDmgShareText,
                      ),
                      _metricColumn(
                        metric: HeroTrendSort.economy,
                        selected: sort,
                        rows: sortedRows,
                        value: (row) => row.ecoShareText,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  AppStatsTableColumn _metricColumn({
    required HeroTrendSort metric,
    required HeroTrendSort selected,
    required List<HeroTrendRow> rows,
    required String Function(HeroTrendRow row) value,
  }) {
    return AppStatsTableColumn(
      label: metric.label,
      selected: metric == selected,
      onHeaderTap: () {
        ref.read(selectedHeroTrendSortProvider.notifier).state = metric;
      },
      cells: [for (final row in rows) _MetricValue(value: value(row))],
    );
  }
}

class _TableToolbar extends StatelessWidget {
  const _TableToolbar({
    required this.title,
    required this.count,
    required this.onRefresh,
  });

  final String title;
  final int count;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<HokThemeColors>();
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          Icon(
            Icons.query_stats_rounded,
            size: 19,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: colors?.onSurfaceStrong,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colors?.onSurfaceMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Refresh',
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}

class _HeroIdentityCell extends StatelessWidget {
  const _HeroIdentityCell({
    required this.hero,
    required this.rank,
    required this.focused,
  });

  final HeroTrendRow hero;
  final int rank;
  final bool focused;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<HokThemeColors>();
    return SizedBox.expand(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: hero.id > 0 ? () => context.go('/heroes/${hero.id}') : null,
        child: Row(
          children: [
            SizedBox(
              width: 22,
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
            AppImage(
              url: hero.avatarUrl,
              width: 34,
              height: 34,
              borderRadius: 17,
              semanticLabel: hero.name,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton(
                    onPressed: hero.id > 0
                        ? () => context.go('/heroes/${hero.id}')
                        : null,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 28),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      alignment: Alignment.centerLeft,
                    ),
                    child: Text(
                      hero.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colors?.onSurfaceStrong,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (focused)
                    Text(
                      'Focused hero',
                      maxLines: 1,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricValue extends StatelessWidget {
  const _MetricValue({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<HokThemeColors>();
    return Text(
      value,
      maxLines: 1,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: colors?.onSurfaceStrong,
        fontFeatures: const [FontFeature.tabularFigures()],
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
