import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../heroes/presentation/hero_gallery_screen.dart';
import '../../settings/presentation/settings_controller.dart';
import '../data/rankings_repository.dart';
import '../domain/equip_ranking_entry.dart';
import '../domain/hero_ranking_entry.dart';
import '../domain/player_ranking_entry.dart';
import '../domain/tier_list_entry.dart';

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

final playerRankingProvider = FutureProvider<List<PlayerRankingEntry>>((
  ref,
) async {
  final settings = await ref.watch(appSettingsControllerProvider.future);
  return ref
      .watch(rankingsRepositoryProvider)
      .loadPlayerRanking(settings.region.regionId);
});

final equipRankingProvider = FutureProvider<List<EquipRankingEntry>>((ref) {
  return ref.watch(rankingsRepositoryProvider).loadEquipRanking();
});

final tierRankingProvider = FutureProvider<List<TierListEntry>>((ref) async {
  final settings = await ref.watch(appSettingsControllerProvider.future);
  return ref
      .watch(rankingsRepositoryProvider)
      .loadTierList(settings.region.regionId);
});

final tierHistoryProvider = FutureProvider.family<List<TierHistoryPoint>, int>((
  ref,
  heroId,
) {
  return ref.watch(rankingsRepositoryProvider).loadTierHistory(heroId: heroId);
});

final tierCompactModeProvider = StateProvider<bool>((ref) => true);

final tierRankingDisplayProvider = FutureProvider<List<TierListEntry>>((
  ref,
) async {
  final entries = await ref.watch(tierRankingProvider.future);
  final heroes = ref.watch(heroGalleryProvider).valueOrNull ?? const [];
  if (heroes.isEmpty) {
    return entries;
  }

  final avatarById = <String, String>{};
  for (final hero in heroes) {
    if (hero.avatar.isEmpty) {
      continue;
    }
    avatarById[hero.id] = hero.avatar;
    if (hero.heroId.isNotEmpty) {
      avatarById[hero.heroId] = hero.avatar;
    }
  }
  return entries
      .map((entry) {
        if (entry.avatarUrl.isNotEmpty) {
          return entry;
        }
        final avatar =
            avatarById[entry.externalHeroId] ??
            avatarById['${entry.heroId}'] ??
            '';
        return avatar.isEmpty ? entry : entry.withAvatarUrl(avatar);
      })
      .toList(growable: false);
});

class TierRankingScreen extends ConsumerStatefulWidget {
  const TierRankingScreen({super.key});

  @override
  ConsumerState<TierRankingScreen> createState() => _TierRankingScreenState();
}

class _TierRankingScreenState extends ConsumerState<TierRankingScreen> {
  List<TierListEntry>? _previousEntries;

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(tierRankingDisplayProvider);
    final loaded = value.valueOrNull;
    if (loaded != null) {
      _previousEntries = loaded;
    }
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _TierListTab(tierValue: value, previousEntries: _previousEntries),
    );
  }
}

class HeroRankingScreen extends ConsumerStatefulWidget {
  const HeroRankingScreen({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  ConsumerState<HeroRankingScreen> createState() => _HeroRankingScreenState();
}

class _HeroRankingScreenState extends ConsumerState<HeroRankingScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      initialIndex: widget.initialTabIndex.clamp(0, 3),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rankingValue = ref.watch(heroRankingProvider);
    final playerValue = ref.watch(playerRankingProvider);
    final equipValue = ref.watch(equipRankingProvider);
    final tierValue = ref.watch(tierRankingDisplayProvider);
    final selectedSort = ref.watch(selectedHeroRankingSortProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppSectionHeader(title: 'Hero Rankings'),
              const SizedBox(height: 8),
              Text(
                'Compare heroes, players, equipment, and tier data.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
              ),
              const SizedBox(height: 16),
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Heroes'),
                  Tab(text: 'Players'),
                  Tab(text: 'Equips'),
                  Tab(text: 'Tier'),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _HeroRankingTab(
                rankingValue: rankingValue,
                selectedSort: selectedSort,
              ),
              _PlayerRankingTab(playerValue: playerValue),
              _EquipRankingTab(equipValue: equipValue),
              _TierListTab(tierValue: tierValue),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroRankingTab extends ConsumerWidget {
  const _HeroRankingTab({
    required this.rankingValue,
    required this.selectedSort,
  });

  final AsyncValue<List<HeroRankingEntry>> rankingValue;
  final HeroRankingSort selectedSort;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppAsyncView<List<HeroRankingEntry>>(
      value: rankingValue,
      retry: () => ref.invalidate(heroRankingProvider),
      data: (entries) => RefreshIndicator(
        onRefresh: () => ref.refresh(heroRankingProvider.future),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              sliver: SliverToBoxAdapter(
                child: _SortSelector(selectedSort: selectedSort),
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
      ),
    );
  }
}

class _PlayerRankingTab extends ConsumerWidget {
  const _PlayerRankingTab({required this.playerValue});

  final AsyncValue<List<PlayerRankingEntry>> playerValue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppAsyncView<List<PlayerRankingEntry>>(
      value: playerValue,
      retry: () => ref.invalidate(playerRankingProvider),
      data: (entries) => RefreshIndicator(
        onRefresh: () => ref.refresh(playerRankingProvider.future),
        child: entries.isEmpty
            ? const CustomScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppEmptyState(
                      icon: Icons.person_search_outlined,
                      title: 'No players found',
                      message: 'Pull to refresh or switch region in settings.',
                    ),
                  ),
                ],
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  return _PlayerRankingCard(
                    entry: entries[index],
                    rank: index + 1,
                  );
                },
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
              ),
      ),
    );
  }
}

class _EquipRankingTab extends ConsumerWidget {
  const _EquipRankingTab({required this.equipValue});

  final AsyncValue<List<EquipRankingEntry>> equipValue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppAsyncView<List<EquipRankingEntry>>(
      value: equipValue,
      retry: () => ref.invalidate(equipRankingProvider),
      data: (entries) => RefreshIndicator(
        onRefresh: () => ref.refresh(equipRankingProvider.future),
        child: entries.isEmpty
            ? const CustomScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppEmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'No equipment found',
                      message:
                          'Pull to refresh once equipment stats are ready.',
                    ),
                  ),
                ],
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  return _EquipRankingCard(
                    entry: entries[index],
                    rank: index + 1,
                  );
                },
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
              ),
      ),
    );
  }
}

class _TierListTab extends ConsumerWidget {
  const _TierListTab({required this.tierValue, this.previousEntries});

  final AsyncValue<List<TierListEntry>> tierValue;
  final List<TierListEntry>? previousEntries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compact = ref.watch(tierCompactModeProvider);
    return AppAsyncView<List<TierListEntry>>(
      value: tierValue,
      previousData: previousEntries,
      loadingStyle: AppAsyncLoadingStyle.gallery,
      retry: () => ref.invalidate(tierRankingDisplayProvider),
      data: (entries) {
        final groups = <String, List<TierListEntry>>{};
        for (final entry in entries) {
          groups.putIfAbsent(entry.tier, () => []).add(entry);
        }
        final tiers = groups.keys.toList(growable: false)
          ..sort((a, b) => _tierOrder(a).compareTo(_tierOrder(b)));

        return RefreshIndicator(
          onRefresh: () => ref.refresh(tierRankingDisplayProvider.future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
            children: [
              Row(
                children: [
                  Icon(
                    Icons.workspace_premium_outlined,
                    size: 19,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Hero Tier List',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: true,
                        icon: Icon(Icons.grid_view_rounded, size: 17),
                        tooltip: 'Compact',
                      ),
                      ButtonSegment(
                        value: false,
                        icon: Icon(Icons.view_agenda_outlined, size: 17),
                        tooltip: 'Spacious',
                      ),
                    ],
                    selected: {compact},
                    showSelectedIcon: false,
                    onSelectionChanged: (selection) {
                      ref.read(tierCompactModeProvider.notifier).state =
                          selection.single;
                    },
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh',
                    onPressed: () => ref.invalidate(tierRankingDisplayProvider),
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (entries.isEmpty)
                const SizedBox(
                  height: 360,
                  child: AppEmptyState(
                    icon: Icons.workspace_premium_outlined,
                    title: 'No tier data found',
                    message: 'Pull to refresh once tier snapshots are ready.',
                  ),
                ),
              for (final tier in tiers) ...[
                _TierGroup(
                  tier: tier,
                  entries: groups[tier]!,
                  compact: compact,
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        );
      },
    );
  }
}

int _tierOrder(String tier) {
  final match = RegExp(r'\d+').firstMatch(tier);
  return int.tryParse(match?.group(0) ?? '') ?? 99;
}

class _TierGroup extends StatelessWidget {
  const _TierGroup({
    required this.tier,
    required this.entries,
    required this.compact,
  });

  final String tier;
  final List<TierListEntry> entries;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<HokThemeColors>();
    final tierColor = switch (tier) {
      'T0' => const Color(0xFFEF4444),
      'T1' => const Color(0xFFF97316),
      'T2' => const Color(0xFFF2B705),
      'T3' => const Color(0xFF22C55E),
      _ => const Color(0xFF64748B),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors?.surfaceSlate ?? AppTheme.panel,
        border: Border.all(color: colors?.outlineSoft ?? AppTheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Column(
          children: [
            Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              color: tierColor,
              child: Row(
                children: [
                  Text(
                    tier,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${entries.length}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final count = compact
                      ? (constraints.maxWidth >= 430 ? 6 : 5)
                      : (constraints.maxWidth >= 430 ? 4 : 3);
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: count,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 6,
                      childAspectRatio: compact ? 0.78 : 0.9,
                    ),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      return _CompactTierHero(
                        entry: entries[index],
                        compact: compact,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactTierHero extends StatelessWidget {
  const _CompactTierHero({required this.entry, required this.compact});

  final TierListEntry entry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<HokThemeColors>();
    final heroRouteId = _heroRouteId(
      externalHeroId: entry.externalHeroId,
      heroId: entry.heroId,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors?.surfaceMuted ?? AppTheme.panelAlt,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkResponse(
              radius: compact ? 25 : 34,
              onTap: entry.heroId <= 0
                  ? null
                  : () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (context) => _TierHistorySheet(entry: entry),
                    ),
              child: AppImage(
                url: entry.avatarUrl,
                width: compact ? 42 : 58,
                height: compact ? 42 : 58,
                borderRadius: compact ? 21 : 29,
                semanticLabel: '${entry.name} tier history',
              ),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: heroRouteId.isEmpty
                  ? null
                  : () => context.go('/heroes/$heroRouteId'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 22),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                entry.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors?.onSurfaceStrong,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (!compact)
              Text(
                '${(entry.winRate * 100).toStringAsFixed(1)}% · ${entry.score.toStringAsFixed(1)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors?.onSurfaceMuted,
                  fontSize: 10,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TierHistorySheet extends ConsumerWidget {
  const _TierHistorySheet({required this.entry});

  final TierListEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(tierHistoryProvider(entry.heroId));
    final colors = Theme.of(context).extension<HokThemeColors>();
    return FractionallySizedBox(
      heightFactor: 0.72,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
        child: Column(
          children: [
            Row(
              children: [
                AppImage(
                  url: entry.avatarUrl,
                  width: 44,
                  height: 44,
                  borderRadius: 22,
                  semanticLabel: entry.name,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        'Historical tier changes',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: colors?.onSurfaceMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: value.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator.adaptive()),
                error: (error, stackTrace) => Center(
                  child: FilledButton.icon(
                    onPressed: () =>
                        ref.invalidate(tierHistoryProvider(entry.heroId)),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                  ),
                ),
                data: (points) {
                  if (points.isEmpty) {
                    return const AppEmptyState(
                      icon: Icons.show_chart_rounded,
                      title: 'No tier history',
                      message: 'Historical snapshots are not available yet.',
                    );
                  }
                  return _TierHistoryChart(points: points);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TierHistoryChart extends StatelessWidget {
  const _TierHistoryChart({required this.points});

  static const sourceColors = <String, Color>{
    'all': Color(0xFF60A5FA),
    'peak_1000': Color(0xFFF472B6),
    'peak_base': Color(0xFFF59E0B),
    'top_rank': Color(0xFF34D399),
  };

  final List<TierHistoryPoint> points;

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<TierHistoryPoint>>{};
    for (final point in points) {
      groups.putIfAbsent(point.source, () => []).add(point);
    }
    for (final values in groups.values) {
      values.sort((a, b) => a.date.compareTo(b.date));
    }
    final dates = points.map((point) => point.date).toList()..sort();
    return Column(
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 6,
          children: [
            for (final entry in groups.entries)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: sourceColors[entry.key] ?? Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _tierSourceLabel(entry.key),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color:
                  Theme.of(context).extension<HokThemeColors>()?.surfaceMuted ??
                  AppTheme.panelAlt,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 14, 12, 8),
              child: CustomPaint(
                painter: _TierHistoryPainter(
                  groups: groups,
                  sourceColors: sourceColors,
                  gridColor: Theme.of(context).dividerColor,
                  labelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_shortDate(dates.first)),
            Text(_shortDate(dates.last)),
          ],
        ),
      ],
    );
  }
}

class _TierHistoryPainter extends CustomPainter {
  const _TierHistoryPainter({
    required this.groups,
    required this.sourceColors,
    required this.gridColor,
    required this.labelColor,
  });

  final Map<String, List<TierHistoryPoint>> groups;
  final Map<String, Color> sourceColors;
  final Color gridColor;
  final Color labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 30.0;
    const top = 8.0;
    const right = 6.0;
    const bottom = 8.0;
    final chart = Rect.fromLTRB(
      left,
      top,
      size.width - right,
      size.height - bottom,
    );
    if (chart.width <= 0 || chart.height <= 0) return;

    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.7)
      ..strokeWidth = 1;
    for (var tier = 0; tier <= 3; tier++) {
      final y = chart.top + chart.height * tier / 3;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
      final painter = TextPainter(
        text: TextSpan(
          text: 'T$tier',
          style: TextStyle(color: labelColor, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, Offset(2, y - painter.height / 2));
    }

    final allPoints = groups.values.expand((points) => points).toList();
    final minDate = allPoints
        .map((point) => point.date.millisecondsSinceEpoch)
        .reduce(math.min);
    final maxDate = allPoints
        .map((point) => point.date.millisecondsSinceEpoch)
        .reduce(math.max);
    final dateSpan = math.max(1, maxDate - minDate);

    for (final entry in groups.entries) {
      final values = entry.value;
      if (values.isEmpty) continue;
      final offsets = values
          .map(
            (point) => Offset(
              chart.left +
                  chart.width *
                      (point.date.millisecondsSinceEpoch - minDate) /
                      dateSpan,
              chart.top + chart.height * point.tier.clamp(0, 3) / 3,
            ),
          )
          .toList(growable: false);
      final path = Path()..moveTo(offsets.first.dx, offsets.first.dy);
      for (var i = 1; i < offsets.length; i++) {
        final previous = offsets[i - 1];
        final current = offsets[i];
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
      if (offsets.length > 1) {
        final beforeLast = offsets[offsets.length - 2];
        final last = offsets.last;
        path.quadraticBezierTo(beforeLast.dx, beforeLast.dy, last.dx, last.dy);
      }
      final color = sourceColors[entry.key] ?? Colors.grey;
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
      for (final point in offsets) {
        canvas.drawCircle(point, 2.6, Paint()..color = color);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TierHistoryPainter oldDelegate) {
    return oldDelegate.groups != groups ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.labelColor != labelColor;
  }
}

String _tierSourceLabel(String source) => switch (source) {
  'peak_1000' => 'Peak Top 1000',
  'peak_base' => 'Peak Base',
  'top_rank' => 'Top Rank',
  _ => 'All',
};

String _shortDate(DateTime date) =>
    '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';

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
    final heroRouteId = _heroRouteId(
      externalHeroId: entry.externalHeroId,
      heroId: entry.heroId,
    );

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: heroRouteId.isEmpty
            ? null
            : () => context.go('/heroes/$heroRouteId'),
        child: DecoratedBox(
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
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppTheme.muted),
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
                    _MetricChip(
                      label: 'Ban',
                      value: _formatPercent(entry.banRate),
                    ),
                    _MetricChip(
                      label: 'MVP',
                      value: _formatPercent(entry.mvpRate),
                    ),
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
        ),
      ),
    );
  }
}

class _PlayerRankingCard extends StatelessWidget {
  const _PlayerRankingCard({required this.entry, required this.rank});

  final PlayerRankingEntry entry;
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
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              entry.playerName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: AppTheme.text,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                          if (entry.playerTypeLabel.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            _TypeBadge(label: entry.playerTypeLabel),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Region ${entry.region}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                      ),
                    ],
                  ),
                ),
                _PrimaryScore(value: entry.peakScore),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetricChip(label: 'Stars', value: entry.rankStars.toString()),
                _MetricChip(label: 'Win', value: _formatPercent(entry.winRate)),
                _MetricChip(
                  label: 'KDA',
                  value: entry.avgKda.toStringAsFixed(1),
                ),
                _MetricChip(
                  label: 'Matches',
                  value: entry.playCount.toString(),
                ),
                _MetricChip(
                  label: 'Grade',
                  value: entry.grade.toStringAsFixed(1),
                ),
                _MetricChip(label: 'MVP', value: entry.mvpCount.toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EquipRankingCard extends StatelessWidget {
  const _EquipRankingCard({required this.entry, required this.rank});

  final EquipRankingEntry entry;
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
        child: Row(
          children: [
            _RankBadge(rank: rank),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                entry.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                _MetricChip(
                  label: 'Pick',
                  value: _formatPercent(entry.pickRate),
                ),
                const SizedBox(height: 8),
                _MetricChip(label: 'Win', value: _formatPercent(entry.winRate)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryScore extends StatelessWidget {
  const _PrimaryScore({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatScore(value),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.gold,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          'Peak',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
        ),
      ],
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.gold.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppTheme.gold,
            fontWeight: FontWeight.w800,
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

String _heroRouteId({required String externalHeroId, required int heroId}) {
  final external = externalHeroId.trim();
  if (external.isNotEmpty) {
    return external;
  }
  return heroId > 0 ? heroId.toString() : '';
}

String _formatScore(double value) {
  final text = value.toStringAsFixed(1);
  final parts = text.split('.');
  final whole = parts.first;
  final buffer = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    final remaining = whole.length - i;
    buffer.write(whole[i]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write(',');
    }
  }
  return '${buffer.toString()}.${parts.last}';
}
