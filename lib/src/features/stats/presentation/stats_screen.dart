import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../rankings/presentation/hero_ranking_screen.dart';
import '../../rankings/presentation/player_leaderboard_screen.dart';
import '../../settings/presentation/settings_controller.dart';
import '../data/stats_repository.dart';
import '../domain/stats_dashboard.dart';
import 'hero_trends_screen.dart';

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  return StatsRepository(apiClient: ref.watch(apiClientProvider));
});

final statsDashboardProvider =
    FutureProvider.family<StatsDashboard, StatsDashboardEntry>((
      ref,
      entry,
    ) async {
      final settings = await ref.watch(appSettingsControllerProvider.future);
      return ref
          .watch(statsRepositoryProvider)
          .loadDashboard(
            regionCode: settings.region.languageCode,
            entry: entry,
          );
    });

final statsEquipDetailProvider =
    FutureProvider.family<StatsEquipDetail, String>((ref, equipId) async {
      final settings = await ref.watch(appSettingsControllerProvider.future);
      return ref
          .watch(statsRepositoryProvider)
          .loadEquipDetail(
            equipId: equipId,
            regionCode: settings.region.languageCode,
          );
    });

final statsHeroDetailProvider = FutureProvider.family<StatsHeroDetail, String>((
  ref,
  heroId,
) async {
  final settings = await ref.watch(appSettingsControllerProvider.future);
  return ref
      .watch(statsRepositoryProvider)
      .loadHeroDetail(heroId: heroId, regionCode: settings.region.languageCode);
});

enum StatsEntry {
  overview,
  homeCore,
  tierRank,
  powerRank,
  equipRank,
  playerRank;

  static StatsEntry fromRoute(String? value, {String? dimension}) {
    final entry = switch (value) {
      'home_core' => StatsEntry.homeCore,
      'tier_rank' => StatsEntry.tierRank,
      'power_rank' => StatsEntry.powerRank,
      'equip_rank' => StatsEntry.equipRank,
      'player_rank' => StatsEntry.playerRank,
      _ => null,
    };
    if (entry != null) {
      return entry;
    }

    return switch (dimension) {
      'tier_rank' => StatsEntry.tierRank,
      'power_rank' => StatsEntry.powerRank,
      'equip_rank' => StatsEntry.equipRank,
      'player_rank' => StatsEntry.playerRank,
      'home_core' => StatsEntry.homeCore,
      _ => StatsEntry.overview,
    };
  }

  StatsDashboardEntry get dashboardEntry {
    return switch (this) {
      StatsEntry.homeCore => StatsDashboardEntry.homeCore,
      StatsEntry.tierRank => StatsDashboardEntry.tierRank,
      StatsEntry.powerRank => StatsDashboardEntry.powerRank,
      StatsEntry.equipRank => StatsDashboardEntry.equipRank,
      StatsEntry.playerRank => StatsDashboardEntry.playerRank,
      StatsEntry.overview => StatsDashboardEntry.overview,
    };
  }
}

class StatsScreen extends ConsumerWidget {
  const StatsScreen({
    this.initialEntry = StatsEntry.overview,
    this.initialEquipId,
    this.initialHeroId,
    this.showPortalTabs = false,
    super.key,
  });

  final StatsEntry initialEntry;
  final String? initialEquipId;
  final String? initialHeroId;
  final bool showPortalTabs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (showPortalTabs) {
      return const _StatsPortalTabs();
    }

    final dashboardProvider = statsDashboardProvider(
      initialEntry.dashboardEntry,
    );
    final value = ref.watch(dashboardProvider);

    return AppAsyncView<StatsDashboard>(
      value: value,
      retry: () => ref.invalidate(dashboardProvider),
      data: (dashboard) {
        return RefreshIndicator(
          onRefresh: () => ref.refresh(dashboardProvider.future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            children: [
              const AppSectionHeader(title: 'Stats Dashboard'),
              const SizedBox(height: 8),
              Text(
                'Hero, equipment, and combo trends from the HOK stats service.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
              ),
              const SizedBox(height: 18),
              if (dashboard.isEmpty)
                const SizedBox(
                  height: 420,
                  child: AppEmptyState(
                    icon: Icons.query_stats_outlined,
                    title: 'No stats found',
                    message: 'Pull to refresh or switch region in settings.',
                  ),
                )
              else ...[
                ..._buildSections(dashboard),
                if (_showsHeroDetail) ...[
                  const SizedBox(height: 18),
                  _HeroDetailSection(heroId: initialHeroId!),
                ],
                if (initialEntry == StatsEntry.equipRank &&
                    initialEquipId != null &&
                    initialEquipId!.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _EquipDetailSection(equipId: initialEquipId!),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildSections(StatsDashboard dashboard) {
    final sections = <_StatsSection>[
      _StatsSection(
        title: 'Hero Trends',
        icon: Icons.person_search_outlined,
        focusLabel: switch (initialEntry) {
          StatsEntry.homeCore => 'Focused home core stats',
          StatsEntry.tierRank => 'Focused tier rank',
          StatsEntry.powerRank => 'Focused power rank',
          _ => '',
        },
        children: [
          for (final hero in dashboard.heroes.take(10))
            _HeroStatsCard(hero: hero),
        ],
      ),
      _StatsSection(
        title: 'Equipment Trends',
        icon: Icons.inventory_2_outlined,
        focusLabel: initialEntry == StatsEntry.equipRank
            ? 'Focused equipment rank'
            : '',
        children: [
          for (final equip in _prioritizeEquips(dashboard.equips).take(10))
            _EquipStatsCard(
              equip: equip,
              isFocused:
                  initialEntry == StatsEntry.equipRank &&
                  _matchesEquip(equip, initialEquipId),
            ),
        ],
      ),
      _StatsSection(
        title: 'Hero Combos',
        icon: Icons.hub_outlined,
        children: [
          for (final combo in dashboard.combos.take(10))
            _ComboStatsCard(combo: combo),
        ],
      ),
      _StatsSection(
        title: 'Player Rankings',
        icon: Icons.emoji_events_outlined,
        focusLabel: initialEntry == StatsEntry.playerRank
            ? 'Focused player rank'
            : '',
        children: [
          for (final player in dashboard.players.take(10))
            _PlayerStatsCard(player: player),
        ],
      ),
    ];

    if (initialEntry == StatsEntry.equipRank) {
      final equipIndex = sections.indexWhere(
        (section) => section.title == 'Equipment Trends',
      );
      if (equipIndex > 0) {
        final equipSection = sections.removeAt(equipIndex);
        sections.insert(0, equipSection);
      }
    }
    if (initialEntry == StatsEntry.playerRank) {
      final playerIndex = sections.indexWhere(
        (section) => section.title == 'Player Rankings',
      );
      if (playerIndex > 0) {
        final playerSection = sections.removeAt(playerIndex);
        sections.insert(0, playerSection);
      }
    }

    return [
      for (final section in sections) ...[
        section,
        if (section != sections.last) const SizedBox(height: 18),
      ],
    ];
  }

  List<StatsEquipRow> _prioritizeEquips(List<StatsEquipRow> equips) {
    final focusedEquipId = initialEquipId;
    if (initialEntry != StatsEntry.equipRank ||
        focusedEquipId == null ||
        focusedEquipId.isEmpty) {
      return equips;
    }

    final rows = [...equips];
    final focusedIndex = rows.indexWhere(
      (equip) => _matchesEquip(equip, focusedEquipId),
    );
    if (focusedIndex > 0) {
      final focused = rows.removeAt(focusedIndex);
      rows.insert(0, focused);
    }
    return rows;
  }

  bool _matchesEquip(StatsEquipRow equip, String? focusedEquipId) {
    return focusedEquipId != null &&
        focusedEquipId.isNotEmpty &&
        equip.id == focusedEquipId;
  }

  bool get _showsHeroDetail {
    final heroId = initialHeroId;
    return heroId != null &&
        heroId.isNotEmpty &&
        (initialEntry == StatsEntry.tierRank ||
            initialEntry == StatsEntry.powerRank ||
            initialEntry == StatsEntry.homeCore);
  }
}

class _StatsPortalTabs extends StatefulWidget {
  const _StatsPortalTabs();

  @override
  State<_StatsPortalTabs> createState() => _StatsPortalTabsState();
}

class _StatsPortalTabsState extends State<_StatsPortalTabs> {
  late final PageController _pageController;
  var _selectedPage = 1;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _selectPage(int index) {
    if (_selectedPage != index) {
      setState(() {
        _selectedPage = index;
      });
    }
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: _StatsTopTabs(
            selectedIndex: _selectedPage,
            onSelected: _selectPage,
          ),
        ),
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _selectedPage = index;
              });
            },
            children: const [
              PlayerLeaderboardScreen(),
              HeroTrendsScreen(),
              HeroRankingScreen(initialTabIndex: 3),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsTopTabs extends StatelessWidget {
  const _StatsTopTabs({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = [
      l10n.statsTabRankings,
      l10n.statsTabTrends,
      l10n.statsTabTier,
    ];

    return Center(
      child: SingleChildScrollView(
        key: const ValueKey('stats-top-tab-strip'),
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < labels.length; index++) ...[
              _StatsTabButton(
                index: index,
                label: labels[index],
                selected: index == selectedIndex,
                onTap: () => onSelected(index),
              ),
              if (index != labels.length - 1) const SizedBox(width: 26),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatsTabButton extends StatelessWidget {
  const _StatsTabButton({
    required this.index,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final int index;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: selected ? AppTheme.text : AppTheme.muted,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            AnimatedContainer(
              key: selected ? ValueKey('stats-top-tab-indicator-$index') : null,
              duration: const Duration(milliseconds: 180),
              width: selected ? 20 : 0,
              height: 3,
              decoration: BoxDecoration(
                color: AppTheme.gold,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroDetailSection extends ConsumerWidget {
  const _HeroDetailSection({required this.heroId});

  final String heroId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(statsHeroDetailProvider(heroId));
    return AppAsyncView<StatsHeroDetail>(
      value: value,
      retry: () => ref.invalidate(statsHeroDetailProvider(heroId)),
      data: (detail) {
        if (detail.equips.isEmpty) {
          return const SizedBox.shrink();
        }
        return _StatsSection(
          title: 'Hero Build Usage',
          icon: Icons.construction_outlined,
          focusLabel: detail.heroName,
          children: [
            for (final equip in detail.equips.take(8))
              _HeroEquipUsageCard(equip: equip),
          ],
        );
      },
    );
  }
}

class _EquipDetailSection extends ConsumerWidget {
  const _EquipDetailSection({required this.equipId});

  final String equipId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(statsEquipDetailProvider(equipId));
    return AppAsyncView<StatsEquipDetail>(
      value: value,
      retry: () => ref.invalidate(statsEquipDetailProvider(equipId)),
      data: (detail) {
        if (detail.heroes.isEmpty) {
          return const SizedBox.shrink();
        }
        return _StatsSection(
          title: 'Equipment Hero Usage',
          icon: Icons.groups_2_outlined,
          focusLabel: detail.equipName,
          children: [
            for (final hero in detail.heroes.take(8))
              _EquipHeroUsageCard(hero: hero),
          ],
        );
      },
    );
  }
}

class _StatsSection extends StatelessWidget {
  const _StatsSection({
    required this.title,
    required this.icon,
    required this.children,
    this.focusLabel = '',
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final String focusLabel;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppTheme.gold, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.text,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (focusLabel.isNotEmpty) ...[
              const SizedBox(width: 8),
              Flexible(
                child: _MetricPill(label: focusLabel, color: AppTheme.gold),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        ...children.expand((child) => [child, const SizedBox(height: 10)]),
      ],
    );
  }
}

class _HeroEquipUsageCard extends StatelessWidget {
  const _HeroEquipUsageCard({required this.equip});

  final StatsHeroEquipRow equip;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      onTap: equip.id.isEmpty
          ? null
          : () => context.go(
              Uri(
                path: '/tools/stats',
                queryParameters: {'entry': 'equip_rank', 'equip_id': equip.id},
              ).toString(),
            ),
      child: Row(
        children: [
          AppImage(
            url: equip.iconUrl,
            width: 44,
            height: 44,
            borderRadius: 12,
            semanticLabel: equip.name,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  equip.name.isEmpty ? 'Equipment' : equip.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetricPill(label: '${equip.pickRateText} pick'),
                    _MetricPill(label: '${equip.winRateText} WR'),
                    _MetricPill(label: equip.matchesText),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EquipHeroUsageCard extends StatelessWidget {
  const _EquipHeroUsageCard({required this.hero});

  final StatsEquipHeroRow hero;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      onTap: hero.id.isEmpty
          ? null
          : () => context.go(
              Uri(
                path: '/tools/stats',
                queryParameters: {'entry': 'tier_rank', 'hero_id': hero.id},
              ).toString(),
            ),
      child: Row(
        children: [
          AppImage(
            url: hero.avatarUrl,
            width: 44,
            height: 44,
            borderRadius: 12,
            semanticLabel: hero.name,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hero.name.isEmpty ? 'Hero' : hero.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetricPill(label: '${hero.pickRateText} pick'),
                    _MetricPill(label: '${hero.winRateText} WR'),
                    _MetricPill(label: hero.matchesText),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStatsCard extends StatelessWidget {
  const _HeroStatsCard({required this.hero});

  final StatsHeroRow hero;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      onTap: hero.id.isEmpty
          ? null
          : () => context.go(
              Uri(
                path: '/tools/stats',
                queryParameters: {'entry': 'tier_rank', 'hero_id': hero.id},
              ).toString(),
            ),
      child: Row(
        children: [
          AppImage(
            url: hero.avatarUrl,
            width: 48,
            height: 48,
            borderRadius: 12,
            semanticLabel: hero.name,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hero.name.isEmpty ? 'Hero' : hero.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetricPill(label: '${hero.pickRateText} pick'),
                    _MetricPill(label: '${hero.banRateText} ban'),
                    _MetricPill(label: 'Score ${hero.scoreText}'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _PrimaryMetric(label: '${hero.winRateText} WR'),
        ],
      ),
    );
  }
}

class _PlayerStatsCard extends StatelessWidget {
  const _PlayerStatsCard({required this.player});

  final StatsPlayerRow player;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      child: Row(
        children: [
          AppImage(
            url: player.avatarUrl,
            width: 48,
            height: 48,
            borderRadius: 12,
            semanticLabel: player.playerName,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.playerName.isEmpty ? 'Player' : player.playerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetricPill(label: '${player.winRateText} WR'),
                    _MetricPill(label: 'KDA ${player.avgKdaText}'),
                    _MetricPill(label: player.playCountText),
                    if (player.rankStars > 0)
                      _MetricPill(label: player.rankStarsText),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _PrimaryMetric(label: '${player.peakScoreText} peak'),
        ],
      ),
    );
  }
}

class _EquipStatsCard extends StatelessWidget {
  const _EquipStatsCard({required this.equip, this.isFocused = false});

  final StatsEquipRow equip;
  final bool isFocused;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      onTap: equip.id.isEmpty
          ? null
          : () => context.go(
              Uri(
                path: '/tools/stats',
                queryParameters: {'entry': 'equip_rank', 'equip_id': equip.id},
              ).toString(),
            ),
      child: Row(
        children: [
          AppImage(
            url: equip.iconUrl,
            width: 44,
            height: 44,
            borderRadius: 10,
            semanticLabel: equip.name,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              equip.name.isEmpty ? 'Equipment' : equip.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.text,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isFocused) ...[
                const _MetricPill(
                  label: 'Focused equipment',
                  color: AppTheme.gold,
                ),
                const SizedBox(height: 8),
              ],
              _PrimaryMetric(label: '${equip.pickRateText} pick'),
              const SizedBox(height: 8),
              _MetricPill(label: '${equip.winRateText} WR'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComboStatsCard extends StatelessWidget {
  const _ComboStatsCard({required this.combo});

  final StatsComboRow combo;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  combo.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _PrimaryMetric(label: '${combo.winRateText} WR'),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetricPill(label: combo.matchesText),
              _MetricPill(label: 'Synergy ${combo.scoreText}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrimaryMetric extends StatelessWidget {
  const _PrimaryMetric({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.gold.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.38)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppTheme.gold,
            fontWeight: FontWeight.w900,
          ),
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color:
            tint?.withValues(alpha: 0.14) ??
            Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color:
              tint?.withValues(alpha: 0.28) ??
              Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: tint ?? AppTheme.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _PanelCard extends StatelessWidget {
  const _PanelCard({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(padding: const EdgeInsets.all(14), child: child),
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: content,
      ),
    );
  }
}
