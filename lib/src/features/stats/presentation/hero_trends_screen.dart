import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_lane_icon.dart';
import '../../../core/widgets/app_list_footer.dart';
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
                          hintText:
                              '${AppLocalizations.of(context).search} ${identityColumn?.label ?? ''}',
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            size: 19,
                          ),
                          suffixIcon: _searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: AppLocalizations.of(context).close,
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
                ? AppEmptyState(
                    icon: Icons.query_stats_rounded,
                    title: AppLocalizations.of(context).noData,
                    message: AppLocalizations.of(context).serviceSlow,
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
                    footer: rows.length > 10
                        ? const AppListFooter(hasMore: false)
                        : null,
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
                              ? AppLocalizations.of(
                                  context,
                                ).translate('statsCore')
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
    _showStatsDrawer(
      context,
      _HeroPreparationSheet(
        request: _detailRequest(row, table),
        showOverview: _query.dimension != 'power_rank',
      ),
    );
  }

  void _openTrendDetail(StatsTrendRow row, StatsTrendTable table) {
    _showStatsDrawer(
      context,
      _TrendDetailSheet(request: _detailRequest(row, table)),
    );
  }
}

/// HOKX 手机端样式：详情面板从右侧滑出的全高抽屉（340px 宽 + 半透明遮罩）。
void _showStatsDrawer(BuildContext context, Widget child) {
  showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'stats-drawer',
    barrierColor: Colors.black45,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Align(alignment: Alignment.centerRight, child: child);
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: child,
      );
    },
  );
}

class _StatsDrawerShell extends StatelessWidget {
  const _StatsDrawerShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<HokThemeColors>();
    final width = math.min(340.0, MediaQuery.sizeOf(context).width * 0.92);
    return Material(
      color: colors?.surfaceSlate ?? context.hokTheme.surfaceSlate,
      shape: Border(
        left: BorderSide(
          color: colors?.outlineSoft ?? context.hokTheme.outlineSoft,
        ),
      ),
      child: SizedBox(
        width: width,
        height: double.infinity,
        child: SafeArea(child: child),
      ),
    );
  }
}

enum _TrendDimension {
  hero('hero_rank', 'Hero', 'base', Icons.person_pin_circle_rounded),
  power('power_rank', 'Power', 'main', Icons.speed_rounded),
  player('player_rank', 'Player', 'peak', Icons.people_alt_rounded),
  equipment('equip_rank', 'Equipment', 'main', Icons.inventory_2_rounded),
  tier('tier_rank', 'Tier', 'main', Icons.workspace_premium_rounded);

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
            tooltip: AppLocalizations.of(context).translate('statsSearchTable'),
            onPressed: onSearch,
            icon: const Icon(Icons.search_rounded, size: 19),
          ),
          IconButton(
            tooltip: AppLocalizations.of(context).translate('statsRefreshData'),
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
      child: AppImage(
        url: url,
        width: 17,
        height: 17,
        borderRadius: 999,
        semanticLabel: label,
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
      if (rows.isEmpty) return const SizedBox.shrink();
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (final item in rows.take(3))
            Expanded(child: _TrendMainHeroCell(item: item)),
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

/// 玩家统计的 Main Heroes：头像下显示真实战力（top_fight），不再把评分当作战力。
class _TrendMainHeroCell extends StatelessWidget {
  const _TrendMainHeroCell({required this.item});

  final Object? item;

  @override
  Widget build(BuildContext context) {
    final hero = _map(item);
    final nestedHero = _map(hero['hero']);
    final power = _heroPowerValue(hero) ?? _heroPowerValue(nestedHero);
    final name = (hero['name'] ?? nestedHero['name'])?.toString().trim() ?? '';
    return Tooltip(
      message: [
        if (name.isNotEmpty) name,
        if (power != null) 'Power ${_formatPowerValue(power)}',
      ].join(' · '),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppImage(
            url: _trendHeroListImageUrl(item),
            width: 24,
            height: 24,
            borderRadius: 12,
            semanticLabel: name.isEmpty ? null : name,
          ),
          if (power != null) ...[
            const SizedBox(height: 2),
            Text(
              _formatPowerValue(power),
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
    );
  }
}

double? _heroPowerValue(Map<String, dynamic> hero) {
  for (final key in const [
    'top_fight',
    'topFight',
    'power',
    'power_value',
    'powerValue',
    'fight_power',
  ]) {
    final value = _double(hero[key]);
    if (value.isFinite && value > 0) return value;
  }
  return null;
}

String _formatPowerValue(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(1);
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
                    label: Text(
                      AppLocalizations.of(context).translate('commonReset'),
                    ),
                  ),
                  IconButton(
                    tooltip: AppLocalizations.of(context).close,
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
                    _FilterLabel(
                      label: AppLocalizations.of(
                        context,
                      ).translate('statsBaseline'),
                    ),
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
                    _FilterLabel(
                      label: AppLocalizations.of(
                        context,
                      ).translate('statsSnapshot'),
                    ),
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
                    _FilterLabel(
                      label: AppLocalizations.of(
                        context,
                      ).translate('statsWindow'),
                    ),
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
                      _FilterLabel(
                        label: AppLocalizations.of(
                          context,
                        ).translate('statsLane'),
                      ),
                      _LaneFilter(
                        selected: _draft.lanePosition,
                        onChanged: (lane) => setState(() {
                          _draft = _draft.copyWith(lanePosition: lane);
                        }),
                      ),
                    ],
                    if (_draft.dimension == 'equip_rank') ...[
                      const SizedBox(height: 14),
                      _FilterLabel(
                        label: AppLocalizations.of(
                          context,
                        ).translate('statsEquipmentCategory'),
                      ),
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
                      _FilterLabel(
                        label: AppLocalizations.of(
                          context,
                        ).translate('statsRegion'),
                      ),
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
                  label: Text(
                    AppLocalizations.of(context).translate('statsApplyFilters'),
                  ),
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
    final tabs = <(String, String)>[
      if (widget.showOverview) ('overview', 'Overview'),
      ('power', 'Power'),
      ('hero_equip', 'Single Equip'),
      ('skill_equip', 'Builds'),
      ('master_build', 'Pro Builds'),
      ('playstyle', 'Skill Flow'),
      ('bp', 'BP'),
    ];
    final value = ref.watch(heroTrendDetailProvider(widget.request));
    return _StatsDrawerShell(
      child: Column(
        children: [
          _StatsDetailHeader(
            row: row,
            subtitle: AppLocalizations.of(context).translate('statsHero'),
            onClose: () => Navigator.pop(context),
          ),
          _StatsDrawerTabs(
            key: const ValueKey('hero-preparation-tabs'),
            tabs: tabs,
            selected: _tab,
            onSelected: (tab) => setState(() => _tab = tab),
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

class _StatsDrawerTabs extends StatelessWidget {
  const _StatsDrawerTabs({
    super.key,
    required this.tabs,
    required this.selected,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
  });

  final List<(String, String)> tabs;
  final String selected;
  final ValueChanged<String> onSelected;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<HokThemeColors>();
    final primary = Theme.of(context).colorScheme.primary;
    // HOKX 样式：纯文字胶囊 chips，超出时换行显示。
    return Padding(
      padding: padding,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final tab in tabs)
              InkWell(
                onTap: () => onSelected(tab.$1),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: selected == tab.$1 ? primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: selected == tab.$1
                          ? primary
                          : colors?.outlineSoft ?? context.hokTheme.outlineSoft,
                    ),
                  ),
                  child: Text(
                    tab.$2,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: selected == tab.$1
                          ? Colors.white
                          : colors?.onSurfaceMuted ??
                                context.hokTheme.onSurfaceMuted,
                    ),
                  ),
                ),
              ),
          ],
        ),
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
    final displayName = _trendRowDisplayName(context, row);
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
                  displayName,
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
            tooltip: AppLocalizations.of(context).close,
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
    // HOKX 抽屉：装备/出装/技能流均以可排序横滚表格展现。
    return switch (tab) {
      'power' => _PowerDetail(detail: detail),
      'hero_equip' => _HeroEquipTable(
        heroRow: row,
        rows: detail.list('hero_equip_stats'),
      ),
      'skill_equip' => _SkillEquipTable(
        heroRow: row,
        rows: detail.list('hero_skill_equip_stats'),
      ),
      'master_build' => _MasterBuildTable(
        heroRow: row,
        rows: detail.list('hero_master_builds'),
      ),
      'playstyle' => _PlaystyleTable(
        heroRow: row,
        rows: detail.list('hero_skill_position_stats'),
      ),
      'bp' => _BpPreparation(detail: detail),
      _ => _PreparationOverview(row: row),
    };
  }
}

class _PreparationOverview extends StatelessWidget {
  const _PreparationOverview({required this.row});

  final StatsTrendRow row;

  @override
  Widget build(BuildContext context) {
    // HOKX 英雄抽屉「综合」布局：8 张两列指标卡。
    return _MetricGrid(
      items: [
        ('WR', _percent(row.raw['wr'])),
        ('P', _percent(row.raw['pick_rate'])),
        ('B', _percent(row.raw['ban_rate'])),
        ('BP', _percent(row.raw['bp_rate'])),
        ('Avg Rating', _compactNumber(row.raw['avg_grade_game'])),
        ('MVP Rate', _percent(row.raw['mvp_rate'])),
        ('Early Win', _percent(row.raw['early_win_rate'])),
        ('Mid Win', _percent(row.raw['mid_win_rate'])),
      ],
    );
  }
}

// ---- HOKX 风格抽屉表格框架：左列固定，表头与行体同步横向滚动，表头可排序 ----

class _TableColumnSpec {
  const _TableColumnSpec({
    required this.id,
    required this.label,
    required this.width,
    required this.cell,
    this.group = '',
    this.sortValue,
    this.sortText,
  });

  final String id;
  final String label;
  final double width;
  // HOKX 两行表头：相邻同 group 的列合并出一个跨列组头（如「槽位分布」「MVP」）。
  final String group;
  final Widget Function(BuildContext context, Map<String, dynamic> row) cell;
  final num Function(Map<String, dynamic> row)? sortValue;
  final String Function(Map<String, dynamic> row)? sortText;

  bool get sortable => sortValue != null || sortText != null;
}

class _DrawerStatsTable extends StatefulWidget {
  const _DrawerStatsTable({
    required this.rows,
    required this.leadingLabel,
    required this.leadingCell,
    required this.columns,
    required this.initialSortId,
    this.rowHeight = 48,
    this.groupHeaders = const {},
    this.leadingSortText,
  });

  final List<Map<String, dynamic>> rows;
  final String leadingLabel;
  final Widget Function(BuildContext context, Map<String, dynamic> row)
  leadingCell;
  final List<_TableColumnSpec> columns;
  final String initialSortId;
  // 固定左列宽度，与 HOKX sticky 首列一致。
  final double leadingWidth = 56;
  final double rowHeight;
  // group id -> 自定义组头（缺省时直接渲染 group 文本）。
  final Map<String, WidgetBuilder> groupHeaders;
  // HOKX 首列（装备名/英雄名/技能名）也可排序；提供取值器即启用。
  final String Function(Map<String, dynamic> row)? leadingSortText;

  @override
  State<_DrawerStatsTable> createState() => _DrawerStatsTableState();
}

class _DrawerStatsTableState extends State<_DrawerStatsTable> {
  late String _sortId = widget.initialSortId;
  bool _descending = true;

  static const _leadingSortId = '__leading';
  // 首屏 30 行，滚动到表尾自动追加（后端单表上限 ≤60）。
  static const _pageRows = 30;

  int _visibleRows = _pageRows;

  List<Map<String, dynamic>> get _sortedRows {
    // HOKX：先对全量行排序，再截断展示（否则切换排序换不进后段行）。
    final rows = widget.rows.toList();
    // 缺失字段的 NaN 与 HOKX toNum 一致按 0 参与排序，避免降序时置顶。
    num finite(num value) => value.isFinite ? value : 0;
    final leadingSortText = widget.leadingSortText;
    if (_sortId == _leadingSortId && leadingSortText != null) {
      rows.sort((left, right) {
        final compare = leadingSortText(left).compareTo(leadingSortText(right));
        return _descending ? -compare : compare;
      });
      return rows.take(_visibleRows).toList();
    }
    final column = widget.columns
        .where((column) => column.id == _sortId && column.sortable)
        .firstOrNull;
    if (column == null) return rows.take(_visibleRows).toList();
    rows.sort((left, right) {
      int compare;
      if (column.sortValue != null) {
        compare = finite(
          column.sortValue!(left),
        ).compareTo(finite(column.sortValue!(right)));
      } else {
        compare = column.sortText!(left).compareTo(column.sortText!(right));
      }
      return _descending ? -compare : compare;
    });
    return rows.take(_visibleRows).toList();
  }

  void _toggleSortId(String id) {
    setState(() {
      if (_sortId == id) {
        _descending = !_descending;
      } else {
        _sortId = id;
        _descending = true;
      }
    });
  }

  void _toggleSort(_TableColumnSpec column) {
    if (!column.sortable) return;
    _toggleSortId(column.id);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<HokThemeColors>();
    final outline = colors?.outlineSoft ?? context.hokTheme.outlineSoft;
    final headerColor = Theme.of(
      context,
    ).scaffoldBackgroundColor.withValues(alpha: 0.8);
    final mutedStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      fontSize: 10,
      fontWeight: FontWeight.w800,
      color: colors?.onSurfaceMuted,
    );
    if (widget.rows.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: headerColor.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: outline),
        ),
        child: Text('No data', style: mutedStyle),
      );
    }
    final rows = _sortedRows;
    const headerHeight = 34.0;
    const groupHeight = 22.0;
    final hasGroups = widget.columns.any((column) => column.group.isNotEmpty);
    final headerBlockHeight = hasGroups
        ? headerHeight + groupHeight
        : headerHeight;

    // HOKX 两行表头：把相邻同 group 的列合并为一个跨列组头单元。
    Widget groupRow() {
      final cells = <Widget>[];
      var index = 0;
      while (index < widget.columns.length) {
        final group = widget.columns[index].group;
        var width = widget.columns[index].width;
        var next = index + 1;
        while (next < widget.columns.length &&
            widget.columns[next].group == group) {
          width += widget.columns[next].width;
          next++;
        }
        cells.add(
          Container(
            width: width,
            height: groupHeight,
            alignment: Alignment.center,
            color: headerColor,
            child: group.isEmpty
                ? null
                : widget.groupHeaders[group]?.call(context) ??
                      Text(
                        group,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: mutedStyle,
                      ),
          ),
        );
        index = next;
      }
      return Row(children: cells);
    }

    Widget headerCell(_TableColumnSpec column) {
      return InkWell(
        onTap: column.sortable ? () => _toggleSort(column) : null,
        child: Container(
          width: column.width,
          height: headerHeight,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          alignment: Alignment.centerLeft,
          color: headerColor,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  column.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: mutedStyle,
                ),
              ),
              if (_sortId == column.id && column.sortable)
                Icon(
                  _descending
                      ? Icons.arrow_drop_down_rounded
                      : Icons.arrow_drop_up_rounded,
                  size: 14,
                  color: colors?.onSurfaceMuted,
                ),
            ],
          ),
        ),
      );
    }

    final table = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: outline),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sticky 左列（有组头时纵向跨两行，等价 HOKX rowSpan=2）。
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: widget.leadingSortText == null
                      ? null
                      : () => _toggleSortId(_leadingSortId),
                  child: Container(
                    width: widget.leadingWidth,
                    height: headerBlockHeight,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    alignment: Alignment.centerLeft,
                    color: headerColor,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            widget.leadingLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: mutedStyle,
                          ),
                        ),
                        if (_sortId == _leadingSortId &&
                            widget.leadingSortText != null)
                          Icon(
                            _descending
                                ? Icons.arrow_drop_down_rounded
                                : Icons.arrow_drop_up_rounded,
                            size: 14,
                            color: colors?.onSurfaceMuted,
                          ),
                      ],
                    ),
                  ),
                ),
                for (final row in rows)
                  Container(
                    width: widget.leadingWidth,
                    height: widget.rowHeight,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: outline)),
                    ),
                    child: widget.leadingCell(context, row),
                  ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasGroups) groupRow(),
                    Row(
                      children: [
                        for (final column in widget.columns) headerCell(column),
                      ],
                    ),
                    for (final row in rows)
                      Row(
                        children: [
                          for (final column in widget.columns)
                            Container(
                              width: column.width,
                              height: widget.rowHeight,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              alignment: Alignment.centerLeft,
                              decoration: BoxDecoration(
                                border: Border(top: BorderSide(color: outline)),
                              ),
                              child: column.cell(context, row),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (widget.rows.length <= _pageRows) {
      return table;
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        table,
        AppListFooter(
          hasMore: _visibleRows < widget.rows.length,
          onLoadMore: () => setState(() => _visibleRows += _pageRows),
        ),
      ],
    );
  }
}

extension _FirstOrNullColumn on Iterable<_TableColumnSpec> {
  _TableColumnSpec? get firstOrNull => isEmpty ? null : first;
}

Widget _tableText(
  BuildContext context,
  String value, {
  Color? color,
  double fontSize = 11,
}) {
  return Text(
    value,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      fontSize: fontSize,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    ),
  );
}

_TableColumnSpec _metricColumn(
  String id,
  String label, {
  double width = 62,
  bool percent = true,
  String group = '',
}) {
  return _TableColumnSpec(
    id: id,
    label: label,
    width: width,
    group: group,
    sortValue: (row) => _double(row[id]),
    cell: (context, row) => _tableText(
      context,
      percent ? _percent(row[id]) : _compactNumber(row[id]),
    ),
  );
}

// 左列固定单元：主头像 + 右下角标（HOKX sticky 首列样式）。
Widget _avatarBadgeCell({
  required String mainUrl,
  required String badgeUrl,
  String? mainLabel,
  String? badgeLabel,
}) {
  return SizedBox(
    width: 40,
    height: 34,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        AppImage(
          url: mainUrl,
          width: 30,
          height: 30,
          borderRadius: 15,
          semanticLabel: mainLabel,
          excludeFromSemantics: mainLabel == null,
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: AppImage(
            url: badgeUrl,
            width: 16,
            height: 16,
            borderRadius: 8,
            semanticLabel: badgeLabel,
            excludeFromSemantics: badgeLabel == null,
          ),
        ),
      ],
    ),
  );
}

// 英雄抽屉左列：英雄头像 + 右下角标（装备或召唤师技能）。
Widget _heroBadgeCell(
  BuildContext context,
  StatsTrendRow heroRow,
  Map<String, dynamic> row,
  String identityKey,
) {
  final entity = _map(row[identityKey]);
  return _avatarBadgeCell(
    mainUrl: heroRow.imageUrl,
    badgeUrl: _trendAssetUrl(
      entity,
      identityKey == 'skill' ? 'summoner_skill' : 'equip',
    ),
    badgeLabel: entity['name']?.toString(),
  );
}

/// 单件装备表：Pick/Win/常见槽位/平均槽位/场次 + S1-S6 槽位分布(份额/胜率)。
/// HOKX 槽位分布组头：「Slot Distribution Share/Win」份额黄、胜率玫红图例。
Widget _slotDistributionGroupHeader(BuildContext context) {
  final colors = Theme.of(context).extension<HokThemeColors>();
  TextStyle style(Color? color) => Theme.of(context).textTheme.labelSmall!
      .copyWith(fontSize: 10, fontWeight: FontWeight.w800, color: color);
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('Slot Distribution', style: style(colors?.onSurfaceMuted)),
      const SizedBox(width: 4),
      Text('Share', style: style(const Color(0xFFFACC15))),
      Text(' / ', style: style(colors?.onSurfaceMuted)),
      Text('Win', style: style(const Color(0xFFF43F5E))),
    ],
  );
}

/// 单件装备矩阵共用列：Pick/Win/常见槽位/平均槽位/场次 + S1-S6 份额胜率格。
List<_TableColumnSpec> _equipSlotMatrixColumns() {
  return [
    _metricColumn('pick_rate', 'Pick'),
    _metricColumn('win_rate', 'Win'),
    _metricColumn('most_common_slot', 'Slot', width: 52, percent: false),
    _metricColumn('avg_slot', 'Avg', width: 52, percent: false),
    _metricColumn('quantity', 'Count', width: 58, percent: false),
    for (var slot = 1; slot <= 6; slot++)
      _TableColumnSpec(
        id: 'slot${slot}_share',
        label: 'S$slot',
        width: 88,
        group: 'slots',
        sortValue: (row) => _double(row['slot${slot}_share']),
        cell: (context, row) => _SlotMatrixCell(row: row, slot: slot),
      ),
  ];
}

class _HeroEquipTable extends StatelessWidget {
  const _HeroEquipTable({required this.heroRow, required this.rows});

  final StatsTrendRow heroRow;
  final List<Map<String, dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    return _DrawerStatsTable(
      rows: rows,
      initialSortId: 'pick_rate',
      leadingLabel: 'Hero',
      rowHeight: 52,
      leadingCell: (context, row) =>
          _heroBadgeCell(context, heroRow, row, 'equip'),
      leadingSortText: (row) => _map(row['equip'])['name']?.toString() ?? '',
      groupHeaders: const {'slots': _slotDistributionGroupHeader},
      columns: _equipSlotMatrixColumns(),
    );
  }
}

/// 装备抽屉「单件装备」表：每行英雄头像 + 该装备角标，同 HOKX 矩阵列。
class _EquipHeroTable extends StatelessWidget {
  const _EquipHeroTable({required this.equipRow, required this.rows});

  final StatsTrendRow equipRow;
  final List<Map<String, dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    return _DrawerStatsTable(
      rows: rows,
      initialSortId: 'pick_rate',
      leadingLabel: 'Hero',
      rowHeight: 52,
      leadingCell: (context, row) {
        final hero = _map(row['hero']);
        return _avatarBadgeCell(
          mainUrl: _trendAssetUrl(hero, 'hero'),
          mainLabel: hero['name']?.toString(),
          badgeUrl: equipRow.imageUrl,
          badgeLabel: equipRow.name,
        );
      },
      leadingSortText: (row) => _map(row['hero'])['name']?.toString() ?? '',
      groupHeaders: const {'slots': _slotDistributionGroupHeader},
      columns: _equipSlotMatrixColumns(),
    );
  }
}

/// S1-S6 槽位矩阵格：份额(黄)/胜率(玫红)并排 + 份额进度条，行内最大值高亮。
class _SlotMatrixCell extends StatelessWidget {
  const _SlotMatrixCell({required this.row, required this.slot});

  final Map<String, dynamic> row;
  final int slot;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<HokThemeColors>();
    // HOKX getSlotMaxes：缺失槽位按 0 处理，防止 NaN 传播吃掉最大值高亮。
    var maxShare = 0.0;
    var maxWin = 0.0;
    for (var index = 1; index <= 6; index++) {
      final shareValue = _double(row['slot${index}_share']);
      final winValue = _double(row['slot${index}_win_rate']);
      if (shareValue.isFinite) maxShare = math.max(maxShare, shareValue);
      if (winValue.isFinite) maxWin = math.max(maxWin, winValue);
    }
    final share = _double(row['slot${slot}_share']);
    final win = _double(row['slot${slot}_win_rate']);
    final isShareMax = share > 0 && share >= maxShare;
    final isWinMax = win > 0 && win >= maxWin;
    TextStyle style(Color? highlight, bool isMax, Color? fallback) =>
        Theme.of(context).textTheme.labelSmall!.copyWith(
          fontSize: 10,
          color: isMax ? highlight : fallback,
          fontWeight: isMax ? FontWeight.w900 : FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()],
        );
    final shareFraction = share.isFinite
        ? (share / 100).clamp(0.0, 1.0).toDouble()
        : 0.0;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _slotPercent(share),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style(
                  const Color(0xFFFACC15),
                  isShareMax,
                  Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: Text(
                _slotPercent(win),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: style(
                  const Color(0xFFF43F5E),
                  isWinMax,
                  colors?.onSurfaceMuted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: Container(
            height: 4,
            color: Theme.of(
              context,
            ).scaffoldBackgroundColor.withValues(alpha: 0.8),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: shareFraction,
              heightFactor: 1,
              child: const ColoredBox(color: Color(0xB394A3B8)),
            ),
          ),
        ),
      ],
    );
  }
}

/// 成型装备表：S1-S6 装备图标 + 场次/胜率/时长 + MVP 指标。
class _SkillEquipTable extends StatelessWidget {
  const _SkillEquipTable({required this.heroRow, required this.rows});

  final StatsTrendRow heroRow;
  final List<Map<String, dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    return _DrawerStatsTable(
      rows: rows,
      initialSortId: 'match_count',
      leadingLabel: 'Hero',
      rowHeight: 46,
      leadingCell: (context, row) =>
          _heroBadgeCell(context, heroRow, row, 'skill'),
      leadingSortText: (row) => _map(row['skill'])['name']?.toString() ?? '',
      columns: [
        for (var slot = 0; slot < 6; slot++)
          _TableColumnSpec(
            id: 'equip_slot_$slot',
            label: 'S${slot + 1}',
            width: 38,
            group: 'Equip Distribution',
            cell: (context, row) {
              final equips = _listOfMaps(row['equips']);
              final equip = slot < equips.length ? equips[slot] : null;
              if (equip == null) return _emptySlotPlaceholder(context, 24);
              return AppImage(
                url: _trendAssetUrl(equip, 'equip'),
                width: 24,
                height: 24,
                borderRadius: 12,
                semanticLabel: equip['name']?.toString(),
              );
            },
          ),
        _metricColumn('match_count', 'Matches', width: 62, percent: false),
        _metricColumn('win_rate', 'Win'),
        _TableColumnSpec(
          id: 'avg_duration',
          label: 'Time',
          width: 54,
          sortValue: (row) => _double(row['avg_duration']),
          cell: (context, row) =>
              _tableText(context, _formatDuration(row['avg_duration'])),
        ),
        _metricColumn('mvp_rate', 'MVP', width: 56, group: 'MVP'),
        _metricColumn('mvp_rate_win', 'MVP W', width: 62, group: 'MVP'),
        _metricColumn('mvp_rate_lose', 'MVP L', width: 62, group: 'MVP'),
      ],
    );
  }
}

/// 大神装备表：玩家 / 描述 / S1-S6 装备图标。
class _MasterBuildTable extends StatelessWidget {
  const _MasterBuildTable({required this.heroRow, required this.rows});

  final StatsTrendRow heroRow;
  final List<Map<String, dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<HokThemeColors>();
    return _DrawerStatsTable(
      rows: rows,
      initialSortId: 'hot_score',
      leadingLabel: 'Hero',
      rowHeight: 46,
      leadingCell: (context, row) =>
          _heroBadgeCell(context, heroRow, row, 'skill'),
      leadingSortText: (row) => _map(row['skill'])['name']?.toString() ?? '',
      columns: [
        _TableColumnSpec(
          id: 'player_name',
          label: 'Player',
          width: 104,
          sortText: (row) => row['player_name']?.toString() ?? '',
          cell: (context, row) =>
              _tableText(context, row['player_name']?.toString() ?? '-'),
        ),
        _TableColumnSpec(
          id: 'desc',
          label: 'Notes',
          width: 150,
          sortText: (row) => row['desc']?.toString() ?? '',
          cell: (context, row) => _tableText(
            context,
            row['desc']?.toString() ?? '-',
            color: colors?.onSurfaceMuted,
          ),
        ),
        for (var slot = 0; slot < 6; slot++)
          _TableColumnSpec(
            id: 'equip_slot_$slot',
            label: 'S${slot + 1}',
            width: 38,
            group: 'Equip Distribution',
            cell: (context, row) {
              final equips = _listOfMaps(row['equips']);
              final equip = slot < equips.length ? equips[slot] : null;
              if (equip == null) return _emptySlotPlaceholder(context, 22);
              return AppImage(
                url: _trendAssetUrl(equip, 'equip'),
                width: 22,
                height: 22,
                borderRadius: 11,
                semanticLabel: equip['name']?.toString(),
              );
            },
          ),
      ],
    );
  }
}

/// 技能流表：分路 / 场次 / 占比 / 胜率 + MVP 指标。
class _PlaystyleTable extends StatelessWidget {
  const _PlaystyleTable({required this.heroRow, required this.rows});

  final StatsTrendRow heroRow;
  final List<Map<String, dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    return _DrawerStatsTable(
      rows: rows,
      initialSortId: 'style_share',
      leadingLabel: 'Hero',
      rowHeight: 46,
      leadingCell: (context, row) =>
          _heroBadgeCell(context, heroRow, row, 'skill'),
      leadingSortText: (row) => _map(row['skill'])['name']?.toString() ?? '',
      columns: [
        _TableColumnSpec(
          id: 'position_label',
          label: 'Lane',
          width: 74,
          sortText: _playstyleLane,
          cell: (context, row) {
            final lane = _playstyleLane(row);
            return _tableText(context, lane.isEmpty ? '-' : lane);
          },
        ),
        _metricColumn('match_count', 'Matches', width: 62, percent: false),
        _metricColumn('style_share', 'Share'),
        _metricColumn('win_rate', 'Win'),
        _metricColumn('mvp_rate', 'MVP', width: 56, group: 'MVP'),
        _metricColumn('mvp_rate_win', 'MVP W', width: 62, group: 'MVP'),
        _metricColumn('mvp_rate_lose', 'MVP L', width: 62, group: 'MVP'),
      ],
    );
  }
}

// HOKX：残缺出装的空槽位显示描边空圆占位，而非留白。
Widget _emptySlotPlaceholder(BuildContext context, double size) {
  final colors = Theme.of(context).extension<HokThemeColors>();
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.6),
      border: Border.all(
        color: colors?.outlineSoft ?? context.hokTheme.outlineSoft,
      ),
    ),
  );
}

// 技能流分路：优先后端文案字段，缺省时按 HOKX 位置码映射。
String _playstyleLane(Map<String, dynamic> row) {
  return _positionLabel(
    row['position_label'] ??
        row['position_desc'] ??
        row['position'] ??
        row['position_key'] ??
        row['position_code'],
  );
}

String _formatDuration(Object? value) {
  final seconds = _double(value);
  if (!seconds.isFinite || seconds <= 0) return '-';
  final minutes = seconds ~/ 60;
  final rest = (seconds % 60).round().toString().padLeft(2, '0');
  return '$minutes:$rest';
}

class _BpPreparation extends StatelessWidget {
  const _BpPreparation({required this.detail});

  final StatsTrendDetail detail;

  @override
  Widget build(BuildContext context) {
    final bp = detail.map('hero_bp_stats');
    return _DetailSection(
      title: 'BP · ${AppLocalizations.of(context).translate('statsPosition')}',
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
    // HOKX BP tab：蓝/红方分块，每个 Pick 顺位一张「占比/胜率」小卡。
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      fontSize: 10,
      color: color.withValues(alpha: 0.85),
    );
    final valueStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      fontSize: 10,
      fontWeight: FontWeight.w800,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.32)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                _percent(data['${prefix}_pick_share']),
                style: valueStyle?.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Text('Win', style: labelStyle),
              const Spacer(),
              Text(_percent(data['${prefix}_win_rate']), style: valueStyle),
            ],
          ),
          const SizedBox(height: 8),
          for (var slot = 1; slot <= 5; slot++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              // 不能用 CrossAxisAlignment.stretch：滚动容器内高度无界会导致布局崩溃、整个 tab 空白。
              child: Row(
                children: [
                  SizedBox(
                    width: 22,
                    child: Center(
                      child: Text(
                        '$slot',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        border: Border.all(color: color.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text('Share', style: labelStyle),
                              const Spacer(),
                              Text(
                                _percent(data['${prefix}_slot${slot}_share']),
                                style: valueStyle,
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Text('Win', style: labelStyle),
                              const Spacer(),
                              Text(
                                _percent(
                                  data['${prefix}_slot${slot}_win_rate'],
                                ),
                                style: valueStyle,
                              ),
                            ],
                          ),
                        ],
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
  late int _windowDays = widget.request.query.windowDays;

  StatsTrendDetailRequest get _effectiveRequest =>
      _windowDays == widget.request.query.windowDays
      ? widget.request
      : StatsTrendDetailRequest(
          row: widget.request.row,
          query: widget.request.query.copyWith(windowDays: _windowDays),
        );

  @override
  Widget build(BuildContext context) {
    final request = _effectiveRequest;
    final value = ref.watch(heroTrendDetailProvider(request));
    final row = widget.request.row;
    final colors = Theme.of(context).extension<HokThemeColors>();
    final displayName = _trendRowDisplayName(context, row);
    return _StatsDrawerShell(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 6, 8),
            child: Row(
              children: [
                AppImage(
                  url: row.imageUrl,
                  width: 36,
                  height: 36,
                  borderRadius: row.kind == 'equip' ? 9 : 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        row.kind == 'equip'
                            ? 'Equipment details'
                            : 'Trend Chart · ${_baselineLabel(widget.request.query.baseline)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors?.onSurfaceMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                // HOKX：窗口天数切换仅英雄趋势抽屉头部有，装备抽屉没有。
                if (row.kind != 'equip')
                  DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      key: const ValueKey('trend-window-select'),
                      value: _windowDays,
                      isDense: true,
                      borderRadius: BorderRadius.circular(10),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      items: [
                        for (final days in const [1, 7, 30, 999])
                          DropdownMenuItem(
                            value: days,
                            child: Text(_windowLabel(days)),
                          ),
                      ],
                      onChanged: (days) {
                        if (days != null) setState(() => _windowDays = days);
                      },
                    ),
                  ),
                IconButton(
                  tooltip: AppLocalizations.of(context).close,
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
              retry: () => ref.invalidate(heroTrendDetailProvider(request)),
              data: (detail) {
                final tabs = row.kind == 'equip'
                    ? const <(String, String)>[
                        ('overview', 'Trend'),
                        ('heroes', 'Single Equip'),
                      ]
                    : const <(String, String)>[
                        ('overview', 'Overview'),
                        ('power', 'Power'),
                        ('playstyle', 'Playstyle'),
                        ('equipment', 'Equipment'),
                        ('matchups', 'Matchups'),
                      ];
                return Column(
                  children: [
                    _StatsDrawerTabs(
                      key: const ValueKey('trend-detail-tabs'),
                      tabs: tabs,
                      selected: _tab,
                      onSelected: (tab) => setState(() => _tab = tab),
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
        title: AppLocalizations.of(context).translate('statsTrend'),
        rows: detail.list('playstyle_trend_series'),
        identityKey: 'skill',
      ),
      'equipment' => _SeriesListDetail(
        title: AppLocalizations.of(context).translate('statsEquipmentTrends'),
        rows: detail.list('equip_trend_series'),
        identityKey: 'equip',
        toggleableLegend: true,
      ),
      'matchups' => _MatchupDetail(row: row, detail: detail),
      'heroes' => _EquipHeroTable(
        equipRow: row,
        rows: detail.list('hero_equip_stats'),
      ),
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
      // HOKX 装备抽屉「趋势」tab：胜率/出场率双指标卡 + 双线趋势图。
      final points = detail.list('trend_points');
      final series = points.isEmpty
          ? [_ChartSeries('Win Rate', const Color(0xFF3B82F6), row.sparkline)]
          : [
              _seriesFromMaps(
                'Win Rate',
                const Color(0xFF3B82F6),
                points,
                'win_rate',
              ),
              _seriesFromMaps(
                'Pick Rate',
                const Color(0xFFEF4444),
                points,
                'pick_rate',
              ),
            ];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MetricGrid(
            items: [
              ('Win Rate', _percent(row.raw['win_rate'] ?? row.raw['wr'])),
              ('Pick Rate', _percent(row.raw['pick_rate'])),
            ],
          ),
          const SizedBox(height: 8),
          _TrendChart(height: 250, series: series),
        ],
      );
    }

    // HOKX 趋势抽屉「综合」布局：大图表 → 最新快照日期 → 2×2 指标卡。
    final points = row.coreTrendPoints;
    final latest = points.isNotEmpty ? points.last : row.raw;
    final snapshotDate = latest['snapshot_date']?.toString() ?? '-';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TrendChart(
          height: 250,
          series: [
            _seriesFromMaps('WR', const Color(0xFF60A5FA), points, 'wr'),
            _seriesFromMaps('P', const Color(0xFFFBBF24), points, 'pick_rate'),
            _seriesFromMaps('B', const Color(0xFF34D399), points, 'ban_rate'),
            _seriesFromMaps('BP', const Color(0xFFF472B6), points, 'bp_rate'),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          snapshotDate,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(
              context,
            ).extension<HokThemeColors>()?.onSurfaceMuted,
          ),
        ),
        const SizedBox(height: 8),
        _MetricGrid(
          items: [
            ('WR', _percent(latest['wr'] ?? row.raw['wr'])),
            ('P', _percent(latest['pick_rate'] ?? row.raw['pick_rate'])),
            ('B', _percent(latest['ban_rate'] ?? row.raw['ban_rate'])),
            ('BP', _percent(latest['bp_rate'] ?? row.raw['bp_rate'])),
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
    // HOKX「战力」布局：Top1/10/50/100 折线图 + 2×2 最新值卡。
    final points = detail.list('power_trend_points');
    final latest = points.isEmpty ? const <String, dynamic>{} : points.last;
    return Column(
      children: [
        _TrendChart(
          height: 250,
          series: [
            _seriesFromMaps('Top1', const Color(0xFFEF4444), points, 'top1'),
            _seriesFromMaps('Top10', const Color(0xFFF59E0B), points, 'top10'),
            _seriesFromMaps('Top50', const Color(0xFF22C55E), points, 'top50'),
            _seriesFromMaps(
              'Top100',
              const Color(0xFF3B82F6),
              points,
              'top100',
            ),
          ],
        ),
        const SizedBox(height: 10),
        _MetricGrid(
          items: [
            ('Top1', _compactNumber(latest['top1'])),
            ('Top10', _compactNumber(latest['top10'])),
            ('Top50', _compactNumber(latest['top50'])),
            ('Top100', _compactNumber(latest['top100'])),
          ],
        ),
      ],
    );
  }
}

/// HOKX 趋势抽屉「打法/装备」tab：多系列合并折线图（胜率实线 + 占比虚线同色）。
class _SeriesListDetail extends StatefulWidget {
  const _SeriesListDetail({
    required this.title,
    required this.rows,
    required this.identityKey,
    this.toggleableLegend = false,
  });

  final String title;
  final List<Map<String, dynamic>> rows;
  final String identityKey;
  final bool toggleableLegend;

  @override
  State<_SeriesListDetail> createState() => _SeriesListDetailState();
}

class _SeriesListDetailState extends State<_SeriesListDetail> {
  final Map<int, bool> _visible = {};

  bool _isVisible(int index) => _visible[index] ?? index < 3;

  @override
  Widget build(BuildContext context) {
    if (widget.rows.isEmpty) {
      return AppEmptyState(
        icon: Icons.show_chart_rounded,
        title: AppLocalizations.of(context).noData,
        message: AppLocalizations.of(context).serviceSlow,
      );
    }
    final colors = Theme.of(context).extension<HokThemeColors>();
    final rows = widget.rows.take(8).toList(growable: false);
    final chartSeries = <_ChartSeries>[];
    for (var index = 0; index < rows.length; index++) {
      if (widget.toggleableLegend && !_isVisible(index)) continue;
      final row = rows[index];
      final color = _chartColors[index % _chartColors.length];
      final points = _listOfMaps(row['points']);
      final name = _seriesName(context, row);
      final chartName = name.isEmpty
          ? _seriesFallbackLabel(context, row, widget.identityKey)
          : name;
      chartSeries.add(
        _seriesFromMaps('$chartName Win', color, points, 'win_rate'),
      );
      chartSeries.add(
        _ChartSeries('$chartName Share', color, [
          for (final point in points)
            _double(point['style_share'] ?? point['pick_rate']),
        ], dashed: true),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.toggleableLegend) ...[
          // HOKX 装备 tab：图例 chips 可开关系列（默认展示前 3 个）。
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var index = 0; index < rows.length; index++)
                _SeriesLegendChip(
                  row: rows[index],
                  identityKey: widget.identityKey,
                  color: _chartColors[index % _chartColors.length],
                  selected: _isVisible(index),
                  onTap: () =>
                      setState(() => _visible[index] = !_isVisible(index)),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        _TrendChart(height: 250, showLegend: false, series: chartSeries),
        const SizedBox(height: 8),
        // 每个系列一张摘要卡：色点 + 名称 + 最新占比/胜率。
        for (var index = 0; index < rows.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).scaffoldBackgroundColor.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colors?.outlineSoft ?? context.hokTheme.outlineSoft,
                ),
              ),
              child: _SeriesSummaryRow(
                row: rows[index],
                identityKey: widget.identityKey,
                color: _chartColors[index % _chartColors.length],
              ),
            ),
          ),
      ],
    );
  }

  String _seriesName(BuildContext context, Map<String, dynamic> row) =>
      _seriesDisplayName(context, row, widget.identityKey);
}

// 系列名优先使用当前语言；非中文界面不把未翻译的中文名称落到界面。
String _seriesDisplayName(
  BuildContext context,
  Map<String, dynamic> row,
  String identityKey,
) {
  final identity = _map(row[identityKey]);
  final base = _localizedEntityName(
    context,
    identity,
    hideUnlocalizedCjk: identityKey == 'equip',
  );
  if (identityKey != 'skill') return base;
  final lane = _positionLabel(
    row['position'] ??
        row['position_desc'] ??
        row['position_key'] ??
        row['position_code'],
  );
  return base.isEmpty || lane.isEmpty ? base : '$base · $lane';
}

// 服务端不同统计接口的本地化字段形状不完全一致，按常见字段顺序读取。
String _localizedEntityName(
  BuildContext context,
  Map<String, dynamic> entity, {
  bool hideUnlocalizedCjk = false,
}) {
  final languageCode = AppLocalizations.of(
    context,
  ).locale.languageCode.toLowerCase();

  String accepted(Object? value) {
    final name = value?.toString().trim() ?? '';
    if (name.isEmpty) return '';
    if (hideUnlocalizedCjk && languageCode != 'zh' && _containsCjk(name)) {
      return '';
    }
    return name;
  }

  final languageTitle = languageCode.isEmpty
      ? ''
      : '${languageCode[0].toUpperCase()}${languageCode.substring(1)}';
  final localizedValues = <Object?>[
    entity['name_$languageCode'],
    entity['${languageCode}_name'],
    if (languageTitle.isNotEmpty) entity['name$languageTitle'],
    _localizedMapValue(entity['names'], languageCode),
    _localizedMapValue(entity['localized_names'], languageCode),
    _localizedMapValue(entity['translations'], languageCode),
    _localizedMapValue(entity['i18n'], languageCode),
  ];
  for (final value in localizedValues) {
    final name = accepted(value);
    if (name.isNotEmpty) return name;
  }
  return accepted(entity['name'] ?? entity['label']);
}

String _localizedMapValue(Object? source, String languageCode) {
  if (source is! Map) return '';
  final keys = <String>[
    languageCode,
    languageCode.toUpperCase(),
    '${languageCode}_$languageCode',
    '$languageCode-${languageCode.toUpperCase()}',
  ];
  for (final key in keys) {
    final value = source[key];
    if (value is Map) {
      final nested = value['name'] ?? value['label'] ?? value['value'];
      final nestedText = nested?.toString().trim() ?? '';
      if (nestedText.isNotEmpty) return nestedText;
    }
    final text = value?.toString().trim() ?? '';
    if (text.isNotEmpty) return text;
  }
  return '';
}

bool _containsCjk(String value) {
  return value.runes.any(
    (rune) =>
        (rune >= 0x3400 && rune <= 0x4dbf) ||
        (rune >= 0x4e00 && rune <= 0x9fff) ||
        (rune >= 0xf900 && rune <= 0xfaff),
  );
}

String _entityId(Map<String, dynamic> entity) {
  for (final key in const ['id', 'equip_id', 'skill_id']) {
    final value = entity[key]?.toString().trim() ?? '';
    if (value.isNotEmpty) return value;
  }
  return '';
}

String _seriesFallbackLabel(
  BuildContext context,
  Map<String, dynamic> row,
  String identityKey,
) {
  final l10n = AppLocalizations.of(context);
  final entity = _map(row[identityKey]);
  final type = identityKey == 'equip'
      ? l10n.translate('statsEquipment')
      : identityKey == 'skill'
      ? l10n.translate('statsTrend')
      : identityKey;
  final id = _entityId(entity);
  return id.isEmpty ? type : '$type #$id';
}

String _trendRowDisplayName(BuildContext context, StatsTrendRow row) {
  if (row.kind != 'equip') return row.name;
  final name = _localizedEntityName(
    context,
    row.equip,
    hideUnlocalizedCjk: true,
  );
  return name.isEmpty
      ? AppLocalizations.of(context).translate('statsEquipment')
      : name;
}

class _SeriesLegendChip extends StatelessWidget {
  const _SeriesLegendChip({
    required this.row,
    required this.identityKey,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Map<String, dynamic> row;
  final String identityKey;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<HokThemeColors>();
    final primary = Theme.of(context).colorScheme.primary;
    final identity = _map(row[identityKey]);
    final name = _seriesDisplayName(context, row, identityKey);
    final accessibleName = name.isEmpty
        ? _seriesFallbackLabel(context, row, identityKey)
        : name;
    final iconUrl = _trendAssetUrl(
      identity,
      identityKey == 'skill' ? 'summoner_skill' : 'equip',
    );
    return Tooltip(
      message: accessibleName,
      child: Semantics(
        button: true,
        label: accessibleName,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: selected
                  ? primary.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected
                    ? primary.withValues(alpha: 0.7)
                    : colors?.outlineSoft ?? context.hokTheme.outlineSoft,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                if (iconUrl.isNotEmpty) ...[
                  AppImage(
                    url: iconUrl,
                    width: 14,
                    height: 14,
                    borderRadius: 7,
                    excludeFromSemantics: true,
                  ),
                  const SizedBox(width: 4),
                ],
                if (name.isNotEmpty)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 110),
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: selected ? null : colors?.onSurfaceMuted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SeriesSummaryRow extends StatelessWidget {
  const _SeriesSummaryRow({
    required this.row,
    required this.identityKey,
    required this.color,
  });

  final Map<String, dynamic> row;
  final String identityKey;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<HokThemeColors>();
    final name = _seriesDisplayName(context, row, identityKey);
    final accessibleName = name.isEmpty
        ? _seriesFallbackLabel(context, row, identityKey)
        : name;
    final identity = _map(row[identityKey]);
    final iconUrl = _trendAssetUrl(
      identity,
      identityKey == 'skill' ? 'summoner_skill' : 'equip',
    );
    final points = _listOfMaps(row['points']);
    final latest = points.isNotEmpty ? points.last : row;
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: accessibleName,
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              if (iconUrl.isNotEmpty) ...[
                Tooltip(
                  message: accessibleName,
                  child: AppImage(
                    url: iconUrl,
                    width: 24,
                    height: 24,
                    borderRadius: 6,
                    semanticLabel: accessibleName,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              if (name.isNotEmpty)
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${l10n.translate('statsPickRate')} '
              '${_percent(latest['style_share'] ?? latest['pick_rate'])}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors?.onSurfaceMuted,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${l10n.translate('statsWinRate')} '
              '${_percent(latest['win_rate'])}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// HOKX getHeroLanePositions：position 词元 -> 分路编号（仅识别 0-4 与别名）。
Set<int> _heroLanes(Map<String, dynamic> hero) {
  const tokenToLane = {
    '0': 0,
    'clash': 0,
    'solo': 0,
    'top': 0,
    '对抗': 0,
    '对抗路': 0,
    '1': 1,
    'mid': 1,
    'middle': 1,
    '中': 1,
    '中路': 1,
    '2': 2,
    'farm': 2,
    'adc': 2,
    'bot': 2,
    'marksman': 2,
    '发育': 2,
    '发育路': 2,
    '3': 3,
    'jungle': 3,
    'jg': 3,
    '野': 3,
    '打野': 3,
    '4': 4,
    'support': 4,
    'sup': 4,
    'roam': 4,
    '辅助': 4,
    '游走': 4,
  };
  final lanes = <int>{};
  for (final key in const ['position', 'postion', 'lanePosition']) {
    final tokens = (hero[key]?.toString() ?? '')
        .replaceAll(RegExp(r'[|/，、;；]'), ',')
        .split(',')
        .map((token) => token.trim().toLowerCase());
    for (final token in tokens) {
      final lane = tokenToLane[token];
      if (lane != null) lanes.add(lane);
    }
  }
  return lanes;
}

bool _hasLaneConflict(
  Map<String, dynamic> baseHero,
  Map<String, dynamic> otherHero,
) {
  final baseLanes = _heroLanes(baseHero);
  final otherLanes = _heroLanes(otherHero);
  if (baseLanes.isEmpty || otherLanes.isEmpty) return false;
  return otherLanes.any(baseLanes.contains);
}

class _MatchupDetail extends StatefulWidget {
  const _MatchupDetail({required this.row, required this.detail});

  final StatsTrendRow row;
  final StatsTrendDetail detail;

  @override
  State<_MatchupDetail> createState() => _MatchupDetailState();
}

class _MatchupDetailState extends State<_MatchupDetail> {
  String _tab = 'synergy';

  @override
  Widget build(BuildContext context) {
    // 搭配英雄过滤同分路冲突（同 HOKX）；两组列表较长，移动端用二级 tab 切换查看。
    final synergyRows = widget.detail
        .list('synergy_list')
        .where((item) => !_hasLaneConflict(widget.row.hero, _map(item['hero'])))
        .toList(growable: false);
    final counterRows = widget.detail.list('counter_list');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatsDrawerTabs(
          key: const ValueKey('matchup-subtabs'),
          padding: EdgeInsets.zero,
          tabs: [
            ('synergy', 'Synergy (${synergyRows.length})'),
            ('counter', 'Counter (${counterRows.length})'),
          ],
          selected: _tab,
          onSelected: (tab) => setState(() => _tab = tab),
        ),
        const SizedBox(height: 8),
        if (_tab == 'synergy')
          _MatchupList(
            title: AppLocalizations.of(context).translate('teamSynergy'),
            scoreLabel: 'Synergy',
            rows: synergyRows,
          )
        else
          _MatchupList(
            title: AppLocalizations.of(context).translate('teamCounter'),
            scoreLabel: 'Counter',
            rows: counterRows,
          ),
      ],
    );
  }
}

class _MatchupList extends StatelessWidget {
  const _MatchupList({
    required this.title,
    required this.rows,
    this.scoreLabel = 'Score',
  });

  final String title;
  final List<Map<String, dynamic>> rows;
  final String scoreLabel;

  @override
  Widget build(BuildContext context) {
    return _DetailSection(
      title: title,
      child: Column(
        children: [
          // HOKX 全量渲染（外层已有整页滚动）。
          for (var index = 0; index < rows.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _CompactHeroStat(
                row: rows[index],
                rank: index + 1,
                scoreLabel: scoreLabel,
              ),
            ),
          if (rows.isEmpty)
            const Padding(padding: EdgeInsets.all(20), child: Text('No data')),
        ],
      ),
    );
  }
}

class _CompactHeroStat extends StatelessWidget {
  const _CompactHeroStat({
    required this.row,
    required this.rank,
    required this.scoreLabel,
  });

  final Map<String, dynamic> row;
  final int rank;
  final String scoreLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<HokThemeColors>();
    final hero = _map(row['hero']);
    final id = hero['id'] ?? hero['heroId'] ?? '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colors?.outlineSoft ?? context.hokTheme.outlineSoft,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            child: Text(
              '$rank',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: colors?.onSurfaceMuted,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          AppImage(
            url: 'https://hokhelper.com/static/game/hero/$id.png',
            width: 28,
            height: 28,
            borderRadius: 14,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hero['name']?.toString() ?? '-',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Matches ${_compactNumber(row['matches'])}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  color: colors?.onSurfaceMuted,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                '$scoreLabel ${_percent(row['score'] ?? row['win_rate'])}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
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

// HOKX 抽屉指标卡：两列网格、深色底 + 描边圆角、小标签在上等宽数字在下。
class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.items});

  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<HokThemeColors>();
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).scaffoldBackgroundColor.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colors?.outlineSoft ?? context.hokTheme.outlineSoft,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.$1,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: colors?.onSurfaceMuted,
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
  const _ChartSeries(
    this.label,
    this.color,
    this.values, {
    this.dashed = false,
  });

  final String label;
  final Color color;
  final List<double> values;
  final bool dashed;
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({
    required this.series,
    this.height = 190,
    this.showLegend = true,
  });

  final List<_ChartSeries> series;
  final double height;
  final bool showLegend;

  @override
  Widget build(BuildContext context) {
    final visible = series.where((item) => item.values.length > 1).toList();
    if (visible.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(child: Text('No trend data')),
      );
    }
    return Column(
      children: [
        SizedBox(
          height: height,
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
        if (showLegend) ...[
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
                        shape: item.dashed
                            ? BoxShape.rectangle
                            : BoxShape.circle,
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
    // HOKX recharts 单一共享 Y 轴：全部系列用同一个 min/max 归一化。
    final allValues = [
      for (final item in series)
        ...item.values.where((value) => value.isFinite),
    ];
    if (allValues.length < 2) return;
    final minValue = allValues.reduce(math.min);
    final maxValue = allValues.reduce(math.max);
    final spread = math.max(maxValue - minValue, 0.0001);
    for (final item in series) {
      final values = item.values.where((value) => value.isFinite).toList();
      if (values.length < 2) continue;
      final points = <Offset>[
        for (var index = 0; index < values.length; index++)
          Offset(
            chart.left + chart.width * index / (values.length - 1),
            chart.bottom - (values[index] - minValue) / spread * chart.height,
          ),
      ];
      final paint = Paint()
        ..color = item.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = item.dashed ? 1.6 : 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      if (item.dashed) {
        // HOKX 用虚线区分占比/份额系列。
        for (var index = 0; index < points.length - 1; index++) {
          _drawDashedSegment(canvas, points[index], points[index + 1], paint);
        }
      } else {
        final path = Path()..moveTo(points.first.dx, points.first.dy);
        for (final point in points.skip(1)) {
          path.lineTo(point.dx, point.dy);
        }
        canvas.drawPath(path, paint);
      }
    }
  }

  void _drawDashedSegment(Canvas canvas, Offset from, Offset to, Paint paint) {
    const dashLength = 4.0;
    const gapLength = 3.0;
    final distance = (to - from).distance;
    if (distance <= 0) return;
    final direction = (to - from) / distance;
    var traveled = 0.0;
    while (traveled < distance) {
      final segmentEnd = math.min(traveled + dashLength, distance);
      canvas.drawLine(
        from + direction * traveled,
        from + direction * segmentEnd,
        paint,
      );
      traveled = segmentEnd + gapLength;
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
    this.badge = _TrendBadge.none,
    this.direction,
    this.showSignal = false,
    super.key,
  });

  final List<double> values;
  final _TrendBadge badge;
  final _TrendDirection? direction;
  final bool showSignal;

  @override
  Widget build(BuildContext context) {
    final signal = _TrendSignal.resolve(
      values: values,
      badge: badge,
      direction: direction ?? _resolveTrendDirection(values),
      fallbackColor: Theme.of(context).colorScheme.primary,
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

// HOKX TREND_SERIES_COLORS：打法/装备趋势系列的 8 色循环。
const _chartColors = [
  Color(0xFF60A5FA),
  Color(0xFFF59E0B),
  Color(0xFF22C55E),
  Color(0xFFF472B6),
  Color(0xFFA78BFA),
  Color(0xFF14B8A6),
  Color(0xFFEF4444),
  Color(0xFF38BDF8),
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
  final l10n = AppLocalizations.of(context);
  return switch (dimension) {
    _TrendDimension.hero => l10n.translate('statsHero'),
    _TrendDimension.power => l10n.translate('statsPower'),
    _TrendDimension.player => l10n.translate('statsPlayer'),
    _TrendDimension.equipment => l10n.translate('statsEquipment'),
    _TrendDimension.tier => l10n.translate('statsTier'),
  };
}

String _metricGroupLabel(BuildContext context, String group) {
  final l10n = AppLocalizations.of(context);
  final key = const {
    '核心': 'statsCore',
    '时段': 'statsPhases',
    '时段(胜率/占比)': 'statsPhases',
    '评分': 'statsRating',
    '输出': 'statsDamage',
    '承伤': 'statsTaken',
    '经济': 'statsEconomy',
    '团队': 'statsTeam',
    '趋势': 'statsTrend',
    '梯度': 'statsTier',
  }[group];
  return key == null ? group : l10n.translate(key);
}

String _columnLabel(BuildContext context, String id, String fallback) {
  final l10n = AppLocalizations.of(context);
  final localizedKey = const {
    'hero': 'statsHero',
    'player': 'statsPlayer',
    'equip': 'statsEquipment',
    'team': 'statsTeam',
    'wr': 'statsWinRate',
    'win_rate': 'statsWinRate',
    'pick_rate': 'statsPickRate',
    'ban_rate': 'statsBanRate',
    'bp_rate': 'statsBpRate',
    'avg_kills': 'statsKills',
    'avg_deaths': 'statsDeaths',
    'avg_assists': 'statsAssists',
    'peak_score': 'homePeakScore',
    'rank_stars': 'statsStars',
    'play_cnt': 'statsMatches',
    'avg_kda': 'statsKda',
    'grade_score': 'statsRating',
    'grade_rank': 'statsRank',
    'tier': 'statsTier',
    'score': 'statsScore',
    'position': 'statsPosition',
  }[id];
  if (localizedKey != null) return l10n.translate(localizedKey);
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

// 88px 槽位格专用：三位整数（100%）去掉小数位，避免省略号截断。
String _slotPercent(double number) {
  if (!number.isFinite) return '-';
  if (number >= 99.995) return '${number.round()}%';
  return '${number.toStringAsFixed(2)}%';
}

// HOKX resolvePositionLabel：位置码 0-4 为打法分路，5-7 为兼容映射。
String _positionLabel(Object? value) {
  final normalized = value?.toString().trim() ?? '';
  if (normalized.isEmpty) return '';
  final code = int.tryParse(normalized);
  if (code != null) {
    return const {
          0: 'Clash',
          1: 'Mid',
          2: 'Farm',
          3: 'Jungle',
          4: 'Support',
          5: 'Jungle',
          6: 'Clash',
          7: 'Farm',
        }[code] ??
        '';
  }
  return normalized;
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
