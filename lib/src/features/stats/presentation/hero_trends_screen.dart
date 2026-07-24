import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_lane_icon.dart';
import '../../../core/widgets/app_stats_table.dart';
import '../../../core/widgets/region_country_picker.dart';
import '../../settings/presentation/settings_controller.dart';
import '../domain/stats_trends.dart';
import 'stats_screen.dart';

final heroTrendTableProvider =
    FutureProvider.family<StatsTrendTable, StatsTrendQuery>((ref, query) async {
      final settings = await ref.watch(appSettingsControllerProvider.future);
      return ref
          .watch(statsRepositoryProvider)
          .loadTrendTable(
            query: query,
            regionCode: settings.region.languageCode,
          );
    });

final heroTrendDetailProvider =
    FutureProvider.family<StatsTrendDetail, StatsTrendDetailRequest>((
      ref,
      request,
    ) async {
      final settings = await ref.watch(appSettingsControllerProvider.future);
      return ref
          .watch(statsRepositoryProvider)
          .loadTrendDetail(
            request: request,
            regionCode: settings.region.languageCode,
          );
    });

class HeroTrendsScreen extends ConsumerStatefulWidget {
  const HeroTrendsScreen({this.initialHeroId, super.key});

  final int? initialHeroId;

  @override
  ConsumerState<HeroTrendsScreen> createState() => _HeroTrendsScreenState();
}

class _HeroTrendsScreenState extends ConsumerState<HeroTrendsScreen> {
  final _searchController = TextEditingController();
  StatsTrendQuery _query = const StatsTrendQuery();
  StatsTrendTable? _previousTable;
  StatsTrendTable? _previousSignalTable;
  String _sortColumn = '';
  bool _sortAscending = false;
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _setQuery(StatsTrendQuery query) {
    setState(() {
      _query = query;
      _sortColumn = '';
      _sortAscending = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(heroTrendTableProvider(_query));
    final signalQuery = _query.copyWith(windowDays: 30);
    final signalValue = ref.watch(heroTrendTableProvider(signalQuery));
    final loaded = value.valueOrNull;
    final loadedSignals = signalValue.valueOrNull;
    if (loaded != null) _previousTable = loaded;
    if (loadedSignals != null) _previousSignalTable = loadedSignals;

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: AppAsyncView<StatsTrendTable>(
        value: value,
        previousData: _previousTable,
        loadingStyle: AppAsyncLoadingStyle.dashboard,
        retry: () {
          ref.invalidate(heroTrendTableProvider(_query));
          ref.invalidate(heroTrendTableProvider(signalQuery));
        },
        data: (table) =>
            _buildTable(table, loadedSignals ?? _previousSignalTable),
      ),
    );
  }

  Widget _buildTable(StatsTrendTable table, StatsTrendTable? signalTable) {
    final signalRows =
        signalTable?.dimension == table.dimension &&
            signalTable?.view == table.view &&
            signalTable?.baseline == table.baseline
        ? signalTable!.rows
        : table.rows;
    final signalRowsByKey = {
      for (final row in signalRows) _trendRowKey(row): row,
    };
    final trendBadges = _rankSevenDayTrendBadges(signalRows);
    final monthDirections = _monthTrendDirections(signalRows);
    final search = _searchController.text.trim().toLowerCase();
    var rows = table.rows
        .where((row) {
          if (_query.lanePosition != null &&
              row.lanePosition != _query.lanePosition) {
            return false;
          }
          return search.isEmpty || row.name.toLowerCase().contains(search);
        })
        .toList(growable: true);

    if (_sortColumn.isNotEmpty) {
      rows.sort((a, b) {
        final result = _compareValues(
          a.value(_sortColumn),
          b.value(_sortColumn),
        );
        return _sortAscending ? result : -result;
      });
    }

    final focusedHeroId = widget.initialHeroId;
    if (focusedHeroId != null) {
      final index = rows.indexWhere(
        (row) => row.kind == 'hero' && int.tryParse(row.id) == focusedHeroId,
      );
      if (index > 0) rows.insert(0, rows.removeAt(index));
    }

    final identityColumn = table.columns.cast<StatsTrendColumn?>().firstWhere(
      (column) => column?.isIdentity == true,
      orElse: () => null,
    );
    final columns = table.columns
        .where((column) => !column.isIdentity && !column.isSparkline)
        .toList(growable: false);
    final hasSparkline = table.columns.any((column) => column.isSparkline);
    final fixedWidth = table.dimension == 'player_rank' ? 174.0 : 164.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 12),
      child: Column(
        children: [
          _DimensionStrip(
            selected: _query.dimension,
            onChanged: (dimension) {
              _setQuery(
                _query.copyWith(
                  dimension: dimension.id,
                  view: dimension.defaultView,
                  baseline:
                      _query.baseline == 'all' && dimension.id != 'hero_rank'
                      ? 'peak_1000'
                      : _query.baseline,
                  equipType: '',
                  lanePosition: null,
                ),
              );
            },
          ),
          const SizedBox(height: 7),
          _FilterSummaryBar(
            query: _query,
            table: table,
            rowCount: rows.length,
            onOpenFilters: () => _openFilters(table),
            onSearch: () => setState(() => _showSearch = !_showSearch),
            onRefresh: () {
              ref.invalidate(heroTrendTableProvider(_query));
              ref.invalidate(
                heroTrendTableProvider(_query.copyWith(windowDays: 30)),
              );
            },
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: !_showSearch
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: SizedBox(
                      height: 40,
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Filter ${identityColumn?.label ?? 'rows'}',
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            size: 19,
                          ),
                          suffixIcon: _searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Clear filter',
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                  ),
                                ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 7),
          Expanded(
            child: rows.isEmpty
                ? const AppEmptyState(
                    icon: Icons.query_stats_rounded,
                    title: 'No matching data',
                    message: 'Adjust the current filters and try again.',
                  )
                : AppStatsTable(
                    fixedHeader: Text(
                      _columnLabel(
                        context,
                        identityColumn?.id ?? 'object',
                        identityColumn?.label ?? 'Object',
                      ),
                    ),
                    fixedColumnWidth: fixedWidth,
                    rowHeight: 60,
                    fixedCells: [
                      for (var index = 0; index < rows.length; index++)
                        _TrendIdentityCell(
                          row: rows[index],
                          rank: index + 1,
                          showSparkline: hasSparkline,
                          trendBadge:
                              trendBadges[_trendRowKey(rows[index])] ??
                              _TrendBadge.none,
                          monthDirection:
                              monthDirections[_trendRowKey(rows[index])] ??
                              _resolveTrendDirection(
                                signalRowsByKey[_trendRowKey(rows[index])]
                                        ?.sparkline ??
                                    rows[index].sparkline,
                              ),
                          focused:
                              int.tryParse(rows[index].id) == focusedHeroId,
                          onAvatarTap: rows[index].kind == 'hero'
                              ? () => _openHeroPreparation(rows[index], table)
                              : rows[index].kind == 'equip'
                              ? () => _openTrendDetail(rows[index], table)
                              : null,
                          onTrendTap:
                              hasSparkline &&
                                  (rows[index].kind == 'hero' ||
                                      rows[index].kind == 'equip')
                              ? () => _openTrendDetail(rows[index], table)
                              : null,
                        ),
                    ],
                    columns: [
                      for (final column in columns)
                        AppStatsTableColumn(
                          label: _columnLabel(context, column.id, column.label),
                          groupLabel: column.group.isEmpty
                              ? 'Metrics'
                              : _metricGroupLabel(context, column.group),
                          width: _columnWidth(column),
                          selected: _sortColumn == column.id,
                          sortAscending: _sortColumn == column.id
                              ? _sortAscending
                              : null,
                          onHeaderTap: column.sortable
                              ? () => setState(() {
                                  if (_sortColumn == column.id) {
                                    _sortAscending = !_sortAscending;
                                  } else {
                                    _sortColumn = column.id;
                                    _sortAscending = false;
                                  }
                                })
                              : null,
                          cells: [
                            for (final row in rows)
                              _TrendValueCell(
                                column: column,
                                value: row.value(column.id),
                              ),
                          ],
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _openFilters(StatsTrendTable table) async {
    final result = await showModalBottomSheet<StatsTrendQuery>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TrendFilterSheet(query: _query, table: table),
    );
    if (result != null) _setQuery(result);
  }

  StatsTrendDetailRequest _detailRequest(
    StatsTrendRow row,
    StatsTrendTable table,
  ) {
    final effectiveQuery =
        _query.snapshotDate.isEmpty && table.latestSnapshotDate.isNotEmpty
        ? _query.copyWith(snapshotDate: table.latestSnapshotDate)
        : _query;
    return StatsTrendDetailRequest(row: row, query: effectiveQuery);
  }

  void _openHeroPreparation(StatsTrendRow row, StatsTrendTable table) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _HeroPreparationSheet(
        request: _detailRequest(row, table),
        showOverview: _query.dimension != 'power_rank',
      ),
    );
  }

  void _openTrendDetail(StatsTrendRow row, StatsTrendTable table) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _TrendDetailSheet(request: _detailRequest(row, table)),
    );
  }
}

enum _TrendDimension {
  hero('hero_rank', 'Hero', 'base', Icons.sports_martial_arts_rounded),
  power('power_rank', 'Power', 'main', Icons.bolt_rounded),
  player('player_rank', 'Player', 'peak', Icons.groups_rounded),
  equipment('equip_rank', 'Equipment', 'main', Icons.shield_outlined),
  tier('tier_rank', 'Tier', 'main', Icons.local_fire_department_outlined);

  const _TrendDimension(this.id, this.label, this.defaultView, this.icon);

  final String id;
  final String label;
  final String defaultView;
  final IconData icon;
}

class _DimensionStrip extends StatelessWidget {
  const _DimensionStrip({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<_TrendDimension> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _TrendDimension.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final dimension = _TrendDimension.values[index];
          final active = selected == dimension.id;
          return Tooltip(
            message: '${dimension.label} rank',
            child: ChoiceChip(
              selected: active,
              showCheckmark: false,
              avatar: Icon(dimension.icon, size: 17),
              label: Text(_dimensionLabel(context, dimension)),
              onSelected: (_) => onChanged(dimension),
            ),
          );
        },
      ),
    );
  }
}

class _FilterSummaryBar extends StatelessWidget {
  const _FilterSummaryBar({
    required this.query,
    required this.table,
    required this.rowCount,
    required this.onOpenFilters,
    required this.onSearch,
    required this.onRefresh,
  });

  final StatsTrendQuery query;
  final StatsTrendTable table;
  final int rowCount;
  final VoidCallback onOpenFilters;
  final VoidCallback onSearch;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<HokThemeColors>();
    final snapshot = query.snapshotDate.isNotEmpty
        ? query.snapshotDate
        : table.latestSnapshotDate;
    final shortSnapshot = snapshot.length >= 10
        ? snapshot.substring(5)
        : snapshot;
    return Container(
      height: 42,
      padding: const EdgeInsets.only(left: 10, right: 2),
      decoration: BoxDecoration(
        color: colors?.surfaceSlate ?? context.hokTheme.surfaceSlate,
        border: Border.all(
          color: colors?.outlineSoft ?? context.hokTheme.outlineSoft,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onOpenFilters,
              child: Row(
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      '${_baselineShortLabel(query.baseline)} · ${_windowShortLabel(query.windowDays)}${shortSnapshot.isEmpty ? '' : ' · $shortSnapshot'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colors?.onSurfaceStrong,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$rowCount',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors?.onSurfaceMuted,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Search table',
            onPressed: onSearch,
            icon: const Icon(Icons.search_rounded, size: 19),
          ),
          IconButton(
            tooltip: 'Refresh data',
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded, size: 19),
          ),
        ],
      ),
    );
  }
}

class _TrendIdentityCell extends StatelessWidget {
  const _TrendIdentityCell({
    required this.row,
    required this.rank,
    required this.showSparkline,
    required this.trendBadge,
    required this.monthDirection,
    required this.focused,
    required this.onAvatarTap,
    required this.onTrendTap,
  });

  final StatsTrendRow row;
  final int rank;
  final bool showSparkline;
  final _TrendBadge trendBadge;
  final _TrendDirection monthDirection;
  final bool focused;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onTrendTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<HokThemeColors>();
    return Semantics(
      label: [if (focused) 'Focused', row.name].join(' '),
      child: Row(
        key: ValueKey('trend-row-${row.kind}-${row.id}'),
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rank <= 3
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$rank',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: rank <= 3 ? Colors.white : colors?.onSurfaceMuted,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Semantics(
            button: onAvatarTap != null,
            label: onAvatarTap == null
                ? row.name
                : 'Open ${row.name} preparation details',
            child: InkResponse(
              key: ValueKey('trend-avatar-${row.kind}-${row.id}'),
              onTap: onAvatarTap,
              radius: 24,
              child: _TrendAvatarCluster(row: row, focused: focused),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Semantics(
              button: onTrendTap != null,
              label: onTrendTap == null
                  ? null
                  : 'Open ${row.name} trend details',
              child: InkWell(
                key: ValueKey('trend-curve-${row.kind}-${row.id}'),
                onTap: onTrendTap,
                child: showSparkline && row.sparkline.length > 1
                    ? _MiniSparkline(
                        key: ValueKey('trend-signal-${row.kind}-${row.id}'),
                        values: row.sparkline,
                        badge: trendBadge,
                        direction: monthDirection,
                        showSignal: true,
                      )
                    : Text(
                        row.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: colors?.onSurfaceStrong,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendAvatarCluster extends StatelessWidget {
  const _TrendAvatarCluster({required this.row, required this.focused});

  final StatsTrendRow row;
  final bool focused;

  @override
  Widget build(BuildContext context) {
    final skill = _map(row.raw['best_skill']);
    final equipValues = row.raw['best_equip'];
    final equip = equipValues is List && equipValues.isNotEmpty
        ? _map(equipValues.first)
        : _map(equipValues);
    final skillUrl = _trendAssetUrl(skill, 'summoner_skill');
    final equipUrl = _trendAssetUrl(equip, 'equip');
    return SizedBox(
      width: 42,
      height: 38,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 5,
            top: 0,
            child: AppImage(
              url: row.imageUrl,
              width: 32,
              height: 32,
              borderRadius: row.kind == 'equip' ? 8 : 16,
              semanticLabel: row.name,
            ),
          ),
          if (skillUrl.isNotEmpty)
            Positioned(
              left: 0,
              bottom: 0,
              child: _TrendLoadoutIcon(
                key: ValueKey('trend-best-skill-${row.id}'),
                url: skillUrl,
                label: _trendAssetName(skill, 'Summoner skill'),
              ),
            ),
          if (equipUrl.isNotEmpty)
            Positioned(
              right: 0,
              bottom: 0,
              child: _TrendLoadoutIcon(
                key: ValueKey('trend-best-equip-${row.id}'),
                url: equipUrl,
                label: _trendAssetName(equip, 'Equipment'),
              ),
            ),
          if (focused)
            Positioned(
              right: 3,
              top: -2,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 1.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TrendLoadoutIcon extends StatelessWidget {
  const _TrendLoadoutIcon({required this.url, required this.label, super.key});

  final String url;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Container(
        width: 17,
        height: 17,
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color:
                Theme.of(context).extension<HokThemeColors>()?.outlineSoft ??
                context.hokTheme.outlineSoft,
          ),
        ),
        child: AppImage(
          url: url,
          width: 15,
          height: 15,
          borderRadius: 4,
          semanticLabel: label,
        ),
      ),
    );
  }
}

String _trendAssetUrl(Map<String, dynamic> item, String kind) {
  final explicit = [item['icon_url'], item['image_url'], item['avatar_url']]
      .map((value) => value?.toString().trim() ?? '')
      .firstWhere((value) => value.isNotEmpty, orElse: () => '');
  if (explicit.isNotEmpty) return explicit;
  final id = (item['id'] ?? item['skill_id'] ?? item['equip_id'])
      ?.toString()
      .trim();
  return id == null || id.isEmpty
      ? ''
      : 'https://hokhelper.com/static/game/$kind/$id.png';
}

String _trendAssetName(Map<String, dynamic> item, String fallback) {
  final name = item['name']?.toString().trim() ?? '';
  return name.isEmpty ? fallback : name;
}

class _TrendValueCell extends StatelessWidget {
  const _TrendValueCell({required this.column, required this.value});

  final StatsTrendColumn column;
  final Object? value;

  @override
  Widget build(BuildContext context) {
    if (column.type == 'hero_list') {
      final rows = value is List ? List<Object?>.from(value as List) : const [];
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final item in rows.take(3))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: AppImage(
                url: _trendHeroListImageUrl(item),
                width: 24,
                height: 24,
                borderRadius: 12,
              ),
            ),
        ],
      );
    }
    return Text(
      _formatTableValue(value, column.type),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).extension<HokThemeColors>()?.onSurfaceStrong,
        fontWeight: FontWeight.w700,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

String _trendHeroListImageUrl(Object? value) {
  final item = _map(value);
  final hero = _map(item['hero']);
  for (final source in [item, hero]) {
    for (final key in const [
      'avatar_url',
      'icon_url',
      'image_url',
      'avatar',
      'icon',
    ]) {
      final url = source[key]?.toString().trim() ?? '';
      if (url.isNotEmpty) return url;
    }
  }
  final heroId =
      (item['heroId'] ??
              item['hero_id'] ??
              hero['heroId'] ??
              hero['hero_id'] ??
              item['id'] ??
              hero['id'])
          ?.toString()
          .trim() ??
      '';
  return heroId.isEmpty ? '' : 'https://img.nourhr.cc/heroes/$heroId.png';
}

class _TrendFilterSheet extends StatefulWidget {
  const _TrendFilterSheet({required this.query, required this.table});

  final StatsTrendQuery query;
  final StatsTrendTable table;

  @override
  State<_TrendFilterSheet> createState() => _TrendFilterSheetState();
}

class _TrendFilterSheetState extends State<_TrendFilterSheet> {
  late StatsTrendQuery _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.query;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<HokThemeColors>();
    final baselines = widget.table.availableBaselines.isEmpty
        ? const ['all', 'peak_base', 'top_rank', 'peak_1000', 'tournament']
        : widget.table.availableBaselines;
    final windows = widget.table.availableWindowDays.isEmpty
        ? const [1, 7, 30, 999]
        : widget.table.availableWindowDays;
    final snapshots = widget.table.availableSnapshotDates.reversed.toList();
    final canFilterLane = const {
      'hero_rank',
      'power_rank',
      'tier_rank',
    }.contains(_draft.dimension);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.84,
      ),
      decoration: BoxDecoration(
        color: colors?.surfaceSlate ?? context.hokTheme.surfaceSlate,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 8),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors?.outlineSoft,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => setState(() {
                      _draft = StatsTrendQuery(
                        dimension: widget.query.dimension,
                        view: widget.query.view,
                      );
                    }),
                    icon: const Icon(Icons.restart_alt_rounded, size: 18),
                    label: const Text('Reset'),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trend scope',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _FilterLabel(label: 'Baseline'),
                    DropdownButtonFormField<String>(
                      initialValue: baselines.contains(_draft.baseline)
                          ? _draft.baseline
                          : baselines.first,
                      items: [
                        for (final baseline in baselines)
                          DropdownMenuItem(
                            value: baseline,
                            child: Text(_baselineLabel(baseline)),
                          ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _draft = _draft.copyWith(
                            baseline: value,
                            dimension: value == 'all'
                                ? 'hero_rank'
                                : _draft.dimension,
                            view: value == 'all' ? 'base' : _draft.view,
                            windowDays: value == 'all'
                                ? 999
                                : _draft.windowDays,
                            snapshotDate: '',
                          );
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    _FilterLabel(label: 'Snapshot'),
                    DropdownButtonFormField<String>(
                      initialValue: _draft.snapshotDate.isEmpty
                          ? ''
                          : _draft.snapshotDate,
                      items: [
                        DropdownMenuItem(
                          value: '',
                          child: Text(
                            widget.table.latestSnapshotDate.isEmpty
                                ? 'Latest available'
                                : 'Latest · ${widget.table.latestSnapshotDate}',
                          ),
                        ),
                        for (final snapshot in snapshots) ...[
                          if (snapshot != widget.table.latestSnapshotDate)
                            DropdownMenuItem(
                              value: snapshot,
                              child: Text(snapshot),
                            ),
                        ],
                      ],
                      onChanged: (value) => setState(() {
                        _draft = _draft.copyWith(snapshotDate: value ?? '');
                      }),
                    ),
                    const SizedBox(height: 14),
                    _FilterLabel(label: 'Window'),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        for (final window in windows)
                          ChoiceChip(
                            selected: _draft.windowDays == window,
                            showCheckmark: false,
                            label: Text(_windowLabel(window)),
                            onSelected: (_) => setState(() {
                              _draft = _draft.copyWith(windowDays: window);
                            }),
                          ),
                      ],
                    ),
                    if (canFilterLane) ...[
                      const SizedBox(height: 14),
                      _FilterLabel(label: 'Lane'),
                      _LaneFilter(
                        selected: _draft.lanePosition,
                        onChanged: (lane) => setState(() {
                          _draft = _draft.copyWith(lanePosition: lane);
                        }),
                      ),
                    ],
                    if (_draft.dimension == 'equip_rank') ...[
                      const SizedBox(height: 14),
                      _FilterLabel(label: 'Equipment category'),
                      DropdownButtonFormField<String>(
                        initialValue: _draft.equipType,
                        items: const [
                          DropdownMenuItem(value: '', child: Text('All')),
                          DropdownMenuItem(value: '1', child: Text('Physical')),
                          DropdownMenuItem(value: '2', child: Text('Magic')),
                          DropdownMenuItem(value: '3', child: Text('Defense')),
                          DropdownMenuItem(value: '4', child: Text('Movement')),
                          DropdownMenuItem(value: '5', child: Text('Jungle')),
                          DropdownMenuItem(value: '7', child: Text('Support')),
                        ],
                        onChanged: (value) => setState(() {
                          _draft = _draft.copyWith(equipType: value ?? '');
                        }),
                      ),
                    ],
                    if (const {
                      'player_rank',
                      'power_rank',
                    }.contains(_draft.dimension)) ...[
                      const SizedBox(height: 14),
                      _FilterLabel(label: 'Region'),
                      RegionCountryPicker(
                        value: int.tryParse(_draft.region) ?? 0,
                        options: widget.table.availableRegions,
                        expanded: true,
                        onChanged: (value) => setState(() {
                          _draft = _draft.copyWith(
                            region: value > 0 ? '$value' : '',
                          );
                        }),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(context, _draft),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Apply filters'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterLabel extends StatelessWidget {
  const _FilterLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).extension<HokThemeColors>()?.onSurfaceMuted,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _LaneFilter extends StatelessWidget {
  const _LaneFilter({required this.selected, required this.onChanged});

  final int? selected;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    const lanes = <(int?, String, String?)>[
      (null, 'All lanes', null),
      (0, 'Clash lane', 'clash'),
      (1, 'Mid lane', 'mid'),
      (2, 'Farm lane', 'adc'),
      (3, 'Jungle', 'jungle'),
      (4, 'Support', 'support'),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final lane in lanes)
          Tooltip(
            message: lane.$2,
            child: InkWell(
              onTap: () => onChanged(lane.$1),
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: selected == lane.$1
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(
                          context,
                        ).extension<HokThemeColors>()?.surfaceMuted,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: lane.$3 == null
                    ? const Icon(Icons.grid_view_rounded, size: 19)
                    : AppLaneIcon(
                        assetName: lane.$3!,
                        size: 22,
                        color: selected == lane.$1
                            ? Colors.white
                            : context.hokTheme.onSurfaceMuted,
                      ),
              ),
            ),
          ),
      ],
    );
  }
}

class _HeroPreparationSheet extends ConsumerStatefulWidget {
  const _HeroPreparationSheet({
    required this.request,
    required this.showOverview,
  });

  final StatsTrendDetailRequest request;
  final bool showOverview;

  @override
  ConsumerState<_HeroPreparationSheet> createState() =>
      _HeroPreparationSheetState();
}

class _HeroPreparationSheetState extends ConsumerState<_HeroPreparationSheet> {
  late String _tab = widget.showOverview ? 'overview' : 'power';

  @override
  Widget build(BuildContext context) {
    final row = widget.request.row;
    final colors = Theme.of(context).extension<HokThemeColors>();
    final tabs = <(String, String, IconData)>[
      if (widget.showOverview)
        ('overview', 'Overview', Icons.dashboard_outlined),
      ('power', 'Power', Icons.bolt_rounded),
      ('hero_equip', 'Single Equip', Icons.shield_outlined),
      ('skill_equip', 'Builds', Icons.view_carousel_outlined),
      ('master_build', 'Pro Builds', Icons.workspace_premium_outlined),
      ('playstyle', 'Skill Flow', Icons.route_rounded),
      ('bp', 'BP', Icons.compare_arrows_rounded),
    ];
    final value = ref.watch(heroTrendDetailProvider(widget.request));
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.92,
      decoration: BoxDecoration(
        color: colors?.surfaceSlate ?? context.hokTheme.surfaceSlate,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Column(
        children: [
          _StatsDetailHeader(
            row: row,
            subtitle: 'Hero preparation',
            onClose: () => Navigator.pop(context),
          ),
          SizedBox(
            height: 42,
            child: ListView.separated(
              key: const ValueKey('hero-preparation-tabs'),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              itemCount: tabs.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final tab = tabs[index];
                return ChoiceChip(
                  selected: _tab == tab.$1,
                  showCheckmark: false,
                  avatar: Icon(tab.$3, size: 16),
                  label: Text(tab.$2),
                  onSelected: (_) => setState(() => _tab = tab.$1),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: AppAsyncView<StatsTrendDetail>(
              value: value,
              loadingStyle: AppAsyncLoadingStyle.dashboard,
              retry: () =>
                  ref.invalidate(heroTrendDetailProvider(widget.request)),
              data: (detail) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 2, 12, 24),
                child: _HeroPreparationBody(
                  tab: _tab,
                  row: row,
                  detail: detail,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsDetailHeader extends StatelessWidget {
  const _StatsDetailHeader({
    required this.row,
    required this.subtitle,
    required this.onClose,
  });

  final StatsTrendRow row;
  final String subtitle;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<HokThemeColors>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 8),
      child: Row(
        children: [
          AppImage(
            url: row.imageUrl,
            width: 40,
            height: 40,
            borderRadius: row.kind == 'equip' ? 9 : 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors?.onSurfaceMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Close details',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _HeroPreparationBody extends StatelessWidget {
  const _HeroPreparationBody({
    required this.tab,
    required this.row,
    required this.detail,
  });

  final String tab;
  final StatsTrendRow row;
  final StatsTrendDetail detail;

  @override
  Widget build(BuildContext context) {
    return switch (tab) {
      'power' => _PowerDetail(detail: detail),
      'hero_equip' => _PreparationEntityList(
        title: 'Single equipment performance',
        rows: detail.list('hero_equip_stats'),
        identityKey: 'equip',
      ),
      'skill_equip' => _BuildPreparationList(
        title: 'Completed builds',
        rows: detail.list('hero_skill_equip_stats'),
      ),
      'master_build' => _BuildPreparationList(
        title: 'Pro player builds',
        rows: detail.list('hero_master_builds'),
        showPlayer: true,
      ),
      'playstyle' => _PreparationEntityList(
        title: 'Skill and lane performance',
        rows: detail.list('hero_skill_position_stats'),
        identityKey: 'skill',
        showLane: true,
      ),
      'bp' => _BpPreparation(detail: detail),
      _ => _PreparationOverview(row: row, detail: detail),
    };
  }
}

class _PreparationOverview extends StatelessWidget {
  const _PreparationOverview({required this.row, required this.detail});

  final StatsTrendRow row;
  final StatsTrendDetail detail;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _DetailSection(
          title: 'Current performance',
          child: _MetricGrid(
            items: [
              ('Win Rate', _percent(row.raw['wr'])),
              ('Pick Rate', _percent(row.raw['pick_rate'])),
              ('Ban Rate', _percent(row.raw['ban_rate'])),
              ('BP Rate', _percent(row.raw['bp_rate'])),
              ('Average Rating', _compactNumber(row.raw['avg_grade_game'])),
              ('MVP Rate', _percent(row.raw['mvp_rate'])),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _DetailSection(
          title: 'Matchup summary',
          child: _MetricGrid(
            items: [
              ('Synergy', _percent(detail.raw['synergy_rank'])),
              ('Counter', _percent(detail.raw['counter_rank'])),
              ('Combo Matches', _compactNumber(detail.raw['combo_matches'])),
              ('Early Win', _percent(row.raw['early_win_rate'])),
            ],
          ),
        ),
      ],
    );
  }
}

class _PreparationEntityList extends StatelessWidget {
  const _PreparationEntityList({
    required this.title,
    required this.rows,
    required this.identityKey,
    this.showLane = false,
  });

  final String title;
  final List<Map<String, dynamic>> rows;
  final String identityKey;
  final bool showLane;

  @override
  Widget build(BuildContext context) {
    return _DetailSection(
      title: title,
      child: rows.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 22),
              child: Center(child: Text('No data')),
            )
          : Column(
              children: [
                for (var index = 0; index < math.min(rows.length, 30); index++)
                  _PreparationEntityRow(
                    row: rows[index],
                    identityKey: identityKey,
                    showLane: showLane,
                  ),
              ],
            ),
    );
  }
}

class _PreparationEntityRow extends StatelessWidget {
  const _PreparationEntityRow({
    required this.row,
    required this.identityKey,
    required this.showLane,
  });

  final Map<String, dynamic> row;
  final String identityKey;
  final bool showLane;

  @override
  Widget build(BuildContext context) {
    final entity = _map(row[identityKey]);
    final url = _trendAssetUrl(
      entity,
      identityKey == 'skill' ? 'summoner_skill' : 'equip',
    );
    final name = entity['name']?.toString().trim();
    final lane = (row['position_label'] ?? row['position_desc'])
        ?.toString()
        .trim();
    final count = row['match_count'] ?? row['quantity'];
    return Container(
      constraints: const BoxConstraints(minHeight: 54),
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color:
                Theme.of(context).extension<HokThemeColors>()?.outlineSoft ??
                context.hokTheme.outlineSoft,
          ),
        ),
      ),
      child: Row(
        children: [
          AppImage(url: url, width: 34, height: 34, borderRadius: 17),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name == null || name.isEmpty ? '-' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  [
                    if (showLane && lane != null && lane.isNotEmpty) lane,
                    if (count != null) '${_compactNumber(count)} matches',
                  ].join(' · '),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).extension<HokThemeColors>()?.onSurfaceMuted,
                  ),
                ),
              ],
            ),
          ),
          _CompactRate(
            label: 'Pick',
            value: row['pick_rate'] ?? row['style_share'],
          ),
          const SizedBox(width: 10),
          _CompactRate(label: 'Win', value: row['win_rate']),
        ],
      ),
    );
  }
}

class _CompactRate extends StatelessWidget {
  const _CompactRate({required this.label, required this.value});

  final String label;
  final Object? value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(
                context,
              ).extension<HokThemeColors>()?.onSurfaceMuted,
            ),
          ),
          Text(
            _percent(value),
            maxLines: 1,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w900,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _BuildPreparationList extends StatelessWidget {
  const _BuildPreparationList({
    required this.title,
    required this.rows,
    this.showPlayer = false,
  });

  final String title;
  final List<Map<String, dynamic>> rows;
  final bool showPlayer;

  @override
  Widget build(BuildContext context) {
    return _DetailSection(
      title: title,
      child: rows.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 22),
              child: Center(child: Text('No data')),
            )
          : Column(
              children: [
                for (var index = 0; index < math.min(rows.length, 30); index++)
                  _BuildPreparationRow(
                    row: rows[index],
                    showPlayer: showPlayer,
                  ),
              ],
            ),
    );
  }
}

class _BuildPreparationRow extends StatelessWidget {
  const _BuildPreparationRow({required this.row, required this.showPlayer});

  final Map<String, dynamic> row;
  final bool showPlayer;

  @override
  Widget build(BuildContext context) {
    final skill = _map(row['skill']);
    final equips = _listOfMaps(row['equips']);
    final player = row['player_name']?.toString().trim() ?? '';
    final description = row['desc']?.toString().trim() ?? '';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color:
                Theme.of(context).extension<HokThemeColors>()?.outlineSoft ??
                context.hokTheme.outlineSoft,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppImage(
                url: _trendAssetUrl(skill, 'summoner_skill'),
                width: 28,
                height: 28,
                borderRadius: 14,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  showPlayer
                      ? (player.isEmpty ? 'Pro build' : player)
                      : (skill['name']?.toString() ?? 'Build'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '${_compactNumber(row['match_count'])} · ${_percent(row['win_rate'])}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
          const SizedBox(height: 7),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final equip in equips.take(12)) ...[
                  AppImage(
                    url: _trendAssetUrl(equip, 'equip'),
                    width: 30,
                    height: 30,
                    borderRadius: 15,
                  ),
                  const SizedBox(width: 5),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BpPreparation extends StatelessWidget {
  const _BpPreparation({required this.detail});

  final StatsTrendDetail detail;

  @override
  Widget build(BuildContext context) {
    final bp = detail.map('hero_bp_stats');
    return _DetailSection(
      title: 'Ban / Pick position',
      child: bp.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 22),
              child: Center(child: Text('No data')),
            )
          : Column(
              children: [
                _BpSideSummary(
                  label: 'Blue side',
                  color: const Color(0xFF3B82F6),
                  data: bp,
                  prefix: 'blue',
                ),
                const SizedBox(height: 12),
                _BpSideSummary(
                  label: 'Red side',
                  color: const Color(0xFFEF4444),
                  data: bp,
                  prefix: 'red',
                ),
              ],
            ),
    );
  }
}

class _BpSideSummary extends StatelessWidget {
  const _BpSideSummary({
    required this.label,
    required this.color,
    required this.data,
    required this.prefix,
  });

  final String label;
  final Color color;
  final Map<String, dynamic> data;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.36)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                'Pick ${_percent(data['${prefix}_pick_share'])} · Win ${_percent(data['${prefix}_win_rate'])}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (var slot = 1; slot <= 5; slot++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  SizedBox(width: 28, child: Text('P$slot')),
                  Expanded(
                    child: LinearProgressIndicator(
                      value:
                          (_double(data['${prefix}_slot${slot}_share']) / 100)
                              .clamp(0.0, 1.0),
                      minHeight: 5,
                      color: color,
                      backgroundColor: color.withValues(alpha: 0.12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 92,
                    child: Text(
                      '${_percent(data['${prefix}_slot${slot}_share'])} / ${_percent(data['${prefix}_slot${slot}_win_rate'])}',
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TrendDetailSheet extends ConsumerStatefulWidget {
  const _TrendDetailSheet({required this.request});

  final StatsTrendDetailRequest request;

  @override
  ConsumerState<_TrendDetailSheet> createState() => _TrendDetailSheetState();
}

class _TrendDetailSheetState extends ConsumerState<_TrendDetailSheet> {
  String _tab = 'overview';

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(heroTrendDetailProvider(widget.request));
    final row = widget.request.row;
    final colors = Theme.of(context).extension<HokThemeColors>();
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.92,
      decoration: BoxDecoration(
        color: colors?.surfaceSlate ?? context.hokTheme.surfaceSlate,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 6, 8),
            child: Row(
              children: [
                AppImage(
                  url: row.imageUrl,
                  width: 40,
                  height: 40,
                  borderRadius: row.kind == 'equip' ? 9 : 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        '${_baselineLabel(widget.request.query.baseline)} · ${_windowLabel(widget.request.query.windowDays)}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors?.onSurfaceMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close details',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Expanded(
            child: AppAsyncView<StatsTrendDetail>(
              value: value,
              loadingStyle: AppAsyncLoadingStyle.dashboard,
              retry: () =>
                  ref.invalidate(heroTrendDetailProvider(widget.request)),
              data: (detail) {
                final tabs = row.kind == 'equip'
                    ? const [
                        ('overview', 'Trend', Icons.show_chart_rounded),
                        ('heroes', 'Heroes', Icons.groups_rounded),
                      ]
                    : const [
                        ('overview', 'Overview', Icons.show_chart_rounded),
                        ('power', 'Power', Icons.bolt_rounded),
                        ('playstyle', 'Playstyle', Icons.route_rounded),
                        ('equipment', 'Equipment', Icons.shield_outlined),
                        ('matchups', 'Matchups', Icons.compare_arrows_rounded),
                      ];
                return Column(
                  children: [
                    SizedBox(
                      height: 42,
                      child: ListView.separated(
                        key: const ValueKey('trend-detail-tabs'),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        scrollDirection: Axis.horizontal,
                        itemCount: tabs.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 6),
                        itemBuilder: (context, index) {
                          final tab = tabs[index];
                          return ChoiceChip(
                            selected: _tab == tab.$1,
                            showCheckmark: false,
                            avatar: Icon(tab.$3, size: 16),
                            label: Text(tab.$2),
                            onSelected: (_) => setState(() => _tab = tab.$1),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(12, 2, 12, 24),
                        child: _DetailTabBody(
                          tab: _tab,
                          row: row,
                          detail: detail,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailTabBody extends StatelessWidget {
  const _DetailTabBody({
    required this.tab,
    required this.row,
    required this.detail,
  });

  final String tab;
  final StatsTrendRow row;
  final StatsTrendDetail detail;

  @override
  Widget build(BuildContext context) {
    return switch (tab) {
      'power' => _PowerDetail(detail: detail),
      'playstyle' => _SeriesListDetail(
        title: 'Skill and lane trends',
        rows: detail.list('playstyle_trend_series'),
        identityKey: 'skill',
      ),
      'equipment' => _SeriesListDetail(
        title: 'Equipment trends',
        rows: detail.list('equip_trend_series'),
        identityKey: 'equip',
      ),
      'matchups' => _MatchupDetail(detail: detail),
      'heroes' => _EquipHeroDetail(detail: detail),
      _ => _OverviewDetail(row: row, detail: detail),
    };
  }
}

class _OverviewDetail extends StatelessWidget {
  const _OverviewDetail({required this.row, required this.detail});

  final StatsTrendRow row;
  final StatsTrendDetail detail;

  @override
  Widget build(BuildContext context) {
    if (row.kind == 'equip') {
      final points = detail.list('trend_points');
      final source = points.isEmpty
          ? row.sparkline.asMap().entries.map((entry) {
              return <String, dynamic>{
                'snapshot_date': '${entry.key + 1}',
                'score': entry.value,
              };
            }).toList()
          : points;
      return _DetailSection(
        title: 'Equipment performance',
        child: _TrendChart(
          series: [
            _seriesFromMaps('Score', const Color(0xFF60A5FA), source, 'score'),
          ],
        ),
      );
    }

    final points = row.coreTrendPoints;
    final latest = points.isNotEmpty ? points.last : row.raw;
    return Column(
      children: [
        _DetailSection(
          title: 'Core trend',
          child: _TrendChart(
            series: [
              _seriesFromMaps('Win', const Color(0xFF60A5FA), points, 'wr'),
              _seriesFromMaps(
                'Pick',
                const Color(0xFFFBBF24),
                points,
                'pick_rate',
              ),
              _seriesFromMaps(
                'Ban',
                const Color(0xFF34D399),
                points,
                'ban_rate',
              ),
              _seriesFromMaps('BP', const Color(0xFFF472B6), points, 'bp_rate'),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _MetricGrid(
          items: [
            ('Win Rate', _percent(latest['wr'] ?? row.raw['wr'])),
            (
              'Pick Rate',
              _percent(latest['pick_rate'] ?? row.raw['pick_rate']),
            ),
            ('Ban Rate', _percent(latest['ban_rate'] ?? row.raw['ban_rate'])),
            ('BP Rate', _percent(latest['bp_rate'] ?? row.raw['bp_rate'])),
            ('Synergy', _percent(detail.raw['synergy_rank'])),
            ('Counter', _percent(detail.raw['counter_rank'])),
          ],
        ),
      ],
    );
  }
}

class _PowerDetail extends StatelessWidget {
  const _PowerDetail({required this.detail});

  final StatsTrendDetail detail;

  @override
  Widget build(BuildContext context) {
    final points = detail.list('power_trend_points');
    final latest = points.isEmpty ? const <String, dynamic>{} : points.last;
    return Column(
      children: [
        _DetailSection(
          title: 'Power rank history',
          child: _TrendChart(
            series: [
              _seriesFromMaps('Top 1', const Color(0xFFEF4444), points, 'top1'),
              _seriesFromMaps(
                'Top 10',
                const Color(0xFFF59E0B),
                points,
                'top10',
              ),
              _seriesFromMaps(
                'Top 50',
                const Color(0xFF22C55E),
                points,
                'top50',
              ),
              _seriesFromMaps(
                'Top 100',
                const Color(0xFF3B82F6),
                points,
                'top100',
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _MetricGrid(
          items: [
            ('Top 1', _compactNumber(latest['top1'])),
            ('Top 10', _compactNumber(latest['top10'])),
            ('Top 50', _compactNumber(latest['top50'])),
            ('Top 100', _compactNumber(latest['top100'])),
          ],
        ),
      ],
    );
  }
}

class _SeriesListDetail extends StatelessWidget {
  const _SeriesListDetail({
    required this.title,
    required this.rows,
    required this.identityKey,
  });

  final String title;
  final List<Map<String, dynamic>> rows;
  final String identityKey;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const AppEmptyState(
        icon: Icons.show_chart_rounded,
        title: 'No trend history',
        message: 'This dataset does not contain detail series.',
      );
    }
    return _DetailSection(
      title: title,
      child: Column(
        children: [
          for (var index = 0; index < math.min(rows.length, 8); index++) ...[
            _SeriesRow(
              row: rows[index],
              identityKey: identityKey,
              color: _chartColors[index % _chartColors.length],
            ),
            if (index < math.min(rows.length, 8) - 1) const Divider(height: 16),
          ],
        ],
      ),
    );
  }
}

class _SeriesRow extends StatelessWidget {
  const _SeriesRow({
    required this.row,
    required this.identityKey,
    required this.color,
  });

  final Map<String, dynamic> row;
  final String identityKey;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final identity = _map(row[identityKey]);
    final name = identity['name']?.toString() ?? '-';
    final points = _listOfMaps(row['points']);
    final latest = points.isNotEmpty ? points.last : row;
    final id = identity['id']?.toString() ?? '';
    final imageUrl = identityKey == 'equip' && id.isNotEmpty
        ? 'https://hokhelper.com/static/game/equip/$id.png'
        : '';
    return Row(
      children: [
        if (imageUrl.isNotEmpty) ...[
          AppImage(url: imageUrl, width: 34, height: 34, borderRadius: 8),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 5),
              SizedBox(
                height: 34,
                child: _MiniSparkline(
                  values: points
                      .map((point) => _double(point['win_rate']))
                      .where((value) => value.isFinite)
                      .toList(),
                  color: color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _percent(latest['win_rate']),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            Text(
              'Pick ${_percent(latest['pick_rate'])}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(
                  context,
                ).extension<HokThemeColors>()?.onSurfaceMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MatchupDetail extends StatelessWidget {
  const _MatchupDetail({required this.detail});

  final StatsTrendDetail detail;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MatchupList(
          title: 'Synergy heroes',
          rows: detail.list('synergy_list'),
        ),
        const SizedBox(height: 10),
        _MatchupList(
          title: 'Counter heroes',
          rows: detail.list('counter_list'),
        ),
      ],
    );
  }
}

class _MatchupList extends StatelessWidget {
  const _MatchupList({required this.title, required this.rows});

  final String title;
  final List<Map<String, dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    return _DetailSection(
      title: title,
      child: Column(
        children: [
          for (var index = 0; index < math.min(rows.length, 10); index++)
            _CompactHeroStat(row: rows[index], rank: index + 1),
          if (rows.isEmpty)
            const Padding(padding: EdgeInsets.all(20), child: Text('No data')),
        ],
      ),
    );
  }
}

class _CompactHeroStat extends StatelessWidget {
  const _CompactHeroStat({required this.row, required this.rank});

  final Map<String, dynamic> row;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final hero = _map(row['hero']);
    final id = hero['id'] ?? hero['heroId'] ?? '';
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          SizedBox(width: 22, child: Text('$rank')),
          AppImage(
            url: 'https://hokhelper.com/static/game/hero/$id.png',
            width: 32,
            height: 32,
            borderRadius: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hero['name']?.toString() ?? '-',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            '${_compactNumber(row['matches'])} · ${_percent(row['score'] ?? row['win_rate'])}',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _EquipHeroDetail extends StatelessWidget {
  const _EquipHeroDetail({required this.detail});

  final StatsTrendDetail detail;

  @override
  Widget build(BuildContext context) {
    return _DetailSection(
      title: 'Hero performance with this equipment',
      child: Column(
        children: [
          for (
            var index = 0;
            index < math.min(detail.list('hero_equip_stats').length, 20);
            index++
          )
            _CompactHeroStat(
              row: detail.list('hero_equip_stats')[index],
              rank: index + 1,
            ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<HokThemeColors>();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors?.surfaceMuted ?? context.hokTheme.surfaceRaised,
        border: Border.all(
          color: colors?.outlineSoft ?? context.hokTheme.outlineSoft,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.items});

  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 8) / 2;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in items)
              Container(
                width: width,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.$1,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).extension<HokThemeColors>()?.onSurfaceMuted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.$2,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ChartSeries {
  const _ChartSeries(this.label, this.color, this.values);

  final String label;
  final Color color;
  final List<double> values;
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.series});

  final List<_ChartSeries> series;

  @override
  Widget build(BuildContext context) {
    final visible = series.where((item) => item.values.length > 1).toList();
    if (visible.isEmpty) {
      return const SizedBox(
        height: 170,
        child: Center(child: Text('No trend history')),
      );
    }
    return Column(
      children: [
        SizedBox(
          height: 190,
          width: double.infinity,
          child: CustomPaint(
            painter: _TrendChartPainter(
              series: visible,
              gridColor:
                  Theme.of(context).extension<HokThemeColors>()?.outlineSoft ??
                  context.hokTheme.outlineSoft,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            for (final item in visible)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: item.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    item.label,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  const _TrendChartPainter({required this.series, required this.gridColor});

  final List<_ChartSeries> series;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final chart = Rect.fromLTWH(4, 6, size.width - 8, size.height - 12);
    final grid = Paint()
      ..color = gridColor.withValues(alpha: 0.55)
      ..strokeWidth = 1;
    for (var index = 0; index <= 3; index++) {
      final y = chart.top + chart.height * index / 3;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), grid);
    }
    for (final item in series) {
      final values = item.values.where((value) => value.isFinite).toList();
      if (values.length < 2) continue;
      final minValue = values.reduce(math.min);
      final maxValue = values.reduce(math.max);
      final spread = math.max(maxValue - minValue, 0.0001);
      final path = Path();
      for (var index = 0; index < values.length; index++) {
        final x = chart.left + chart.width * index / (values.length - 1);
        final normalized = (values[index] - minValue) / spread;
        final y = chart.bottom - normalized * chart.height;
        if (index == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = item.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(_TrendChartPainter oldDelegate) {
    return oldDelegate.series != series || oldDelegate.gridColor != gridColor;
  }
}

class _MiniSparkline extends StatelessWidget {
  const _MiniSparkline({
    required this.values,
    this.color,
    this.badge = _TrendBadge.none,
    this.direction,
    this.showSignal = false,
    super.key,
  });

  final List<double> values;
  final Color? color;
  final _TrendBadge badge;
  final _TrendDirection? direction;
  final bool showSignal;

  @override
  Widget build(BuildContext context) {
    final signal = _TrendSignal.resolve(
      values: values,
      badge: badge,
      direction: direction ?? _resolveTrendDirection(values),
      fallbackColor: color ?? Theme.of(context).colorScheme.primary,
      useSignalPalette: showSignal,
    );
    return Semantics(
      label: signal.semanticLabel,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                0,
                showSignal ? 5 : 1,
                showSignal ? 9 : 0,
                1,
              ),
              child: CustomPaint(
                painter: _MiniSparklinePainter(
                  values: values,
                  color: signal.color,
                  baselineColor:
                      Theme.of(
                        context,
                      ).extension<HokThemeColors>()?.onSurfaceMuted ??
                      context.hokTheme.onSurfaceMuted,
                ),
                size: const Size(double.infinity, double.infinity),
              ),
            ),
          ),
          if (showSignal && signal.direction != _TrendDirection.steady)
            Positioned(
              top: -4,
              right: -4,
              child: Icon(
                signal.direction == _TrendDirection.up
                    ? Icons.arrow_drop_up_rounded
                    : Icons.arrow_drop_down_rounded,
                size: 19,
                color: signal.color,
              ),
            ),
          if (showSignal && badge != _TrendBadge.none)
            Positioned.fill(
              child: IgnorePointer(
                child: Align(
                  alignment: const Alignment(-0.96, 0.12),
                  child: Text(
                    badge.emoji,
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(fontSize: 11, height: 1),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

enum _TrendDirection { up, steady, down }

enum _TrendBadge {
  none(''),
  hot('🔥'),
  cold('🧊');

  const _TrendBadge(this.emoji);

  final String emoji;
}

String _trendRowKey(StatsTrendRow row) => '${row.kind}:${row.id}';

Map<String, _TrendBadge> _rankSevenDayTrendBadges(List<StatsTrendRow> rows) {
  final changes = <(StatsTrendRow, double)>[];
  for (final row in rows) {
    final values = row.sparkline.where((value) => value.isFinite).toList();
    if (values.length < 2) continue;
    final recent = values.skip(math.max(0, values.length - 7)).toList();
    final start = recent.first;
    final end = recent.last;
    final denominator = math.max(start.abs(), 0.0001);
    final changeRate = (end - start) / denominator;
    if (changeRate.abs() > 0.000001) changes.add((row, changeRate));
  }

  final risers = changes.where((item) => item.$2 > 0).toList()
    ..sort((a, b) => b.$2.compareTo(a.$2));
  final fallers = changes.where((item) => item.$2 < 0).toList()
    ..sort((a, b) => a.$2.compareTo(b.$2));
  return {
    for (final item in risers.take(2)) _trendRowKey(item.$1): _TrendBadge.hot,
    for (final item in fallers.take(2)) _trendRowKey(item.$1): _TrendBadge.cold,
  };
}

Map<String, _TrendDirection> _monthTrendDirections(List<StatsTrendRow> rows) {
  return {
    for (final row in rows)
      _trendRowKey(row): _resolveTrendDirection(
        row.sparkline.skip(math.max(0, row.sparkline.length - 30)).toList(),
      ),
  };
}

_TrendDirection _resolveTrendDirection(List<double> values) {
  final valid = values.where((value) => value.isFinite).toList();
  if (valid.length < 2) return _TrendDirection.steady;
  final delta = valid.last - valid.first;
  final threshold = math.max(valid.first.abs() * 0.0001, 0.000001);
  if (delta > threshold) return _TrendDirection.up;
  if (delta < -threshold) return _TrendDirection.down;
  return _TrendDirection.steady;
}

class _TrendSignal {
  const _TrendSignal({
    required this.color,
    required this.direction,
    required this.badge,
  });

  static const _cold = Color(0xFF2997FF);
  static const _warm = Color(0xFFFBBF24);
  static const _hot = Color(0xFFFF2D2D);

  final Color color;
  final _TrendDirection direction;
  final _TrendBadge badge;

  String get semanticLabel {
    final rankLabel = switch (badge) {
      _TrendBadge.hot => 'Top seven-day riser',
      _TrendBadge.cold => 'Top seven-day faller',
      _TrendBadge.none => 'One-month trend',
    };
    final directionLabel = switch (direction) {
      _TrendDirection.up => 'rising',
      _TrendDirection.steady => 'steady',
      _TrendDirection.down => 'falling',
    };
    return '$rankLabel, $directionLabel';
  }

  factory _TrendSignal.resolve({
    required List<double> values,
    required _TrendBadge badge,
    required _TrendDirection direction,
    required Color fallbackColor,
    required bool useSignalPalette,
  }) {
    final color = useSignalPalette
        ? switch (direction) {
            _TrendDirection.up => _hot,
            _TrendDirection.down => _warm,
            _TrendDirection.steady => _cold,
          }
        : fallbackColor;
    return _TrendSignal(color: color, direction: direction, badge: badge);
  }
}

class _MiniSparklinePainter extends CustomPainter {
  const _MiniSparklinePainter({
    required this.values,
    required this.color,
    required this.baselineColor,
  });

  final List<double> values;
  final Color color;
  final Color baselineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final valid = values.where((value) => value.isFinite).toList();
    if (valid.length < 2 || size.width <= 0 || size.height <= 0) return;
    final minValue = valid.reduce(math.min);
    final maxValue = valid.reduce(math.max);
    final spread = math.max(maxValue - minValue, 0.0001);
    final verticalPadding = math.max(1.5, size.height * 0.08);
    final baseline = valid.reduce((a, b) => a + b) / valid.length;
    final baselineY =
        size.height -
        verticalPadding -
        ((baseline - minValue) / spread) * (size.height - verticalPadding * 2);
    final baselinePaint = Paint()
      ..color = baselineColor.withValues(alpha: 0.7)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 7) {
      canvas.drawLine(
        Offset(x, baselineY),
        Offset(math.min(x + 4, size.width), baselineY),
        baselinePaint,
      );
    }

    final points = <Offset>[];
    for (var index = 0; index < valid.length; index++) {
      final x = size.width * index / (valid.length - 1);
      final y =
          size.height -
          verticalPadding -
          ((valid[index] - minValue) / spread) *
              (size.height - verticalPadding * 2);
      points.add(Offset(x, y));
    }

    final path = _smoothPath(points);
    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.24),
            color.withValues(alpha: 0.02),
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  Path _smoothPath(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var index = 1; index < points.length; index++) {
      final previous = points[index - 1];
      final current = points[index];
      final midpoint = Offset(
        (previous.dx + current.dx) / 2,
        (previous.dy + current.dy) / 2,
      );
      path.quadraticBezierTo(
        previous.dx,
        previous.dy,
        midpoint.dx,
        midpoint.dy,
      );
    }
    final previous = points[points.length - 2];
    final current = points.last;
    path.quadraticBezierTo(previous.dx, previous.dy, current.dx, current.dy);
    return path;
  }

  @override
  bool shouldRepaint(_MiniSparklinePainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.color != color ||
        oldDelegate.baselineColor != baselineColor;
  }
}

const _chartColors = [
  Color(0xFF60A5FA),
  Color(0xFFFBBF24),
  Color(0xFF34D399),
  Color(0xFFF472B6),
  Color(0xFFA78BFA),
  Color(0xFFFB7185),
];

_ChartSeries _seriesFromMaps(
  String label,
  Color color,
  List<Map<String, dynamic>> points,
  String key,
) {
  return _ChartSeries(
    label,
    color,
    points
        .map((point) => _double(point[key]))
        .where((value) => value.isFinite)
        .toList(growable: false),
  );
}

int _compareValues(Object? a, Object? b) {
  final an = _double(a);
  final bn = _double(b);
  if (an.isFinite && bn.isFinite) return an.compareTo(bn);
  return (a?.toString() ?? '').compareTo(b?.toString() ?? '');
}

double _columnWidth(StatsTrendColumn column) {
  if (column.type == 'hero_list') return 112;
  if (column.type == 'text') return 86;
  return math.max(82, math.min(116, 50 + column.label.length * 7)).toDouble();
}

String _formatTableValue(Object? value, String type) {
  if (value == null || value == '') return '-';
  if (type == 'percent') return _percent(value);
  if (type == 'number') return _compactNumber(value);
  return value.toString();
}

String _dimensionLabel(BuildContext context, _TrendDimension dimension) {
  if (Localizations.localeOf(context).languageCode != 'zh') {
    return dimension.label;
  }
  return switch (dimension) {
    _TrendDimension.hero => '英雄',
    _TrendDimension.power => '战力',
    _TrendDimension.player => '玩家',
    _TrendDimension.equipment => '装备',
    _TrendDimension.tier => '梯度',
  };
}

String _metricGroupLabel(BuildContext context, String group) {
  if (Localizations.localeOf(context).languageCode == 'zh') return group;
  return const {
        '核心': 'Core',
        '时段': 'Phases',
        '时段(胜率/占比)': 'Phases (Win/Share)',
        '评分': 'Rating',
        '输出': 'Damage',
        '承伤': 'Taken',
        '经济': 'Economy',
        '团队': 'Team',
        '趋势': 'Trend',
        '梯度': 'Tier',
      }[group] ??
      group;
}

String _columnLabel(BuildContext context, String id, String fallback) {
  if (Localizations.localeOf(context).languageCode == 'zh') return fallback;
  final byId = const {
    'hero': 'Hero',
    'player': 'Player',
    'equip': 'Equipment',
    'team': 'Team',
    'wr': 'Win Rate',
    'win_rate': 'Win Rate',
    'pick_rate': 'Pick Rate',
    'ban_rate': 'Ban Rate',
    'bp_rate': 'BP Rate',
    'phase_early_wr': 'Early Win',
    'phase_early_share': 'Early Share',
    'phase_mid_wr': 'Mid Win',
    'phase_mid_share': 'Mid Share',
    'phase_late_wr': 'Late Win',
    'phase_late_share': 'Late Share',
    'avg_grade_all': 'Avg Rating',
    'avg_grade_win': 'Win Rating',
    'avg_grade_lose': 'Loss Rating',
    'avg_kills': 'Kills',
    'avg_deaths': 'Deaths',
    'avg_assists': 'Assists',
    'avg_total_hero_hurt_cnt': 'Hero Damage',
    'avg_total_hurt_cnt': 'Total Damage',
    'avg_hurt_trans_rate': 'Damage Conversion',
    'dmg_share': 'Damage Share',
    'avg_total_behurt_cnt_per_min': 'Taken / Min',
    'avg_behurt_per_death': 'Taken / Death',
    'avg_total_behurt_cnt': 'Total Taken',
    'take_dmg_share': 'Taken Share',
    'avg_money_per_min': 'Gold / Min',
    'avg_money': 'Total Gold',
    'avg_monster_coin': 'Jungle Gold',
    'money_share': 'Economy Share',
    'avg_join_game_percent': 'Participation',
    'avg_heal_cnt': 'Healing',
    'avg_ctrl_time': 'Control Time',
    'avg_kill_soldier': 'Last Hits',
    'mvp_rate': 'MVP Rate',
    'mvp_rate_win': 'Win MVP',
    'mvp_rate_lose': 'Loss MVP',
    'synergy_rank': 'Synergy',
    'counter_rank': 'Counter',
    'combo_matches': 'Samples',
    'top1': 'Top 1',
    'top10': 'Top 10',
    'top50': 'Top 50',
    'top100': 'Top 100',
    'peak_score': 'Peak Score',
    'rank_stars': 'Stars',
    'win_cnt': 'Wins',
    'play_cnt': 'Matches',
    'avg_kda': 'KDA',
    'grade': 'Damage / Min',
    'grade_score': 'Rating',
    'grade_rank': 'Rank',
    'mvp': 'MVP',
    'best_heroes': 'Main Heroes',
    'weighted_score': 'Weighted Score',
    'most_common_slot': 'Common Slot',
    'avg_slot': 'Avg Slot',
    'quantity': 'Quantity',
    'tier': 'Tier',
    'score': 'Score',
    'position': 'Position',
  }[id];
  if (byId != null) return byId;
  return const {
        '英雄': 'Hero',
        '玩家': 'Player',
        '装备': 'Equipment',
        '战队': 'Team',
        '当前胜率': 'Current Win Rate',
        '当前出场率': 'Current Pick Rate',
        '当前BP率': 'Current BP Rate',
        '胜率': 'Win Rate',
        '出场率': 'Pick Rate',
        '禁用率': 'Ban Rate',
        'BP率': 'BP Rate',
        '搭配强度': 'Synergy',
        '克制强度': 'Counter',
        '样本场次': 'Samples',
        '前期胜率': 'Early Win',
        '前期占比': 'Early Share',
        '中期胜率': 'Mid Win',
        '中期占比': 'Mid Share',
        '后期胜率': 'Late Win',
        '后期占比': 'Late Share',
        '平均评分': 'Avg Rating',
        '胜方平均评分': 'Win Rating',
        '败方平均评分': 'Loss Rating',
        '击杀': 'Kills',
        '死亡': 'Deaths',
        '助攻': 'Assists',
        '对人伤害': 'Hero Damage',
        '全部伤害': 'Total Damage',
        '伤害转化率': 'Damage Conversion',
        '输出占比': 'Damage Share',
        '分均承伤': 'Taken / Min',
        '每死承伤': 'Taken / Death',
        '总承伤': 'Total Taken',
        '承伤占比': 'Taken Share',
        '分均经济': 'Gold / Min',
        '全部经济': 'Total Gold',
        '野怪经济': 'Jungle Gold',
        '经济占比': 'Economy Share',
        '参团率': 'Participation',
        '治疗量': 'Healing',
        '控制时长': 'Control Time',
        '补刀数': 'Last Hits',
        'MVP率': 'MVP Rate',
        '胜方MVP率': 'Win MVP',
        '败方MVP率': 'Loss MVP',
        '巅峰分': 'Peak Score',
        '排位星': 'Stars',
        '胜场': 'Wins',
        '总场次': 'Matches',
        '分均输出': 'Damage / Min',
        '排名': 'Rank',
        '评分': 'Rating',
        '常用英雄': 'Main Heroes',
        '加权得分': 'Weighted Score',
        '最常顺位': 'Common Slot',
        '平均顺位': 'Avg Slot',
        '数量': 'Quantity',
        '梯度': 'Tier',
        '梯度值': 'Score',
      }[fallback] ??
      fallback;
}

String _baselineLabel(String baseline) => switch (baseline) {
  'all' => 'All ranks',
  'peak_base' => 'Peak 1350+',
  'top_rank' => 'Top Rank',
  'peak_1000' => 'Peak Top 1000',
  'tournament' => 'Tournament',
  _ => baseline,
};

String _baselineShortLabel(String baseline) => switch (baseline) {
  'all' => 'All',
  'peak_base' => '1350+',
  'top_rank' => 'Top Rank',
  'peak_1000' => 'Top 1000',
  'tournament' => 'Tournament',
  _ => baseline,
};

String _windowLabel(int days) => switch (days) {
  1 => 'Yesterday',
  7 => 'Last 7 days',
  30 => 'Last 30 days',
  999 => 'Current season',
  _ => '$days days',
};

String _windowShortLabel(int days) => switch (days) {
  1 => '1D',
  7 => '7D',
  30 => '30D',
  999 => 'Season',
  _ => '${days}D',
};

String _percent(Object? value) {
  final number = _double(value);
  return number.isFinite ? '${number.toStringAsFixed(2)}%' : '-';
}

String _compactNumber(Object? value) {
  final number = _double(value);
  if (!number.isFinite) return '-';
  if (number.abs() >= 1000) return number.toStringAsFixed(0);
  if (number == number.roundToDouble()) return number.toStringAsFixed(0);
  return number.toStringAsFixed(2);
}

double _double(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? double.nan;
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}

List<Map<String, dynamic>> _listOfMaps(Object? value) {
  if (value is! List) return const [];
  return value.map(_map).toList(growable: false);
}
