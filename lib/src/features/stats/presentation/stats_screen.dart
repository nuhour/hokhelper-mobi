import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../settings/presentation/settings_controller.dart';
import '../data/stats_repository.dart';
import '../domain/stats_dashboard.dart';

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  return StatsRepository(apiClient: ref.watch(apiClientProvider));
});

final statsDashboardProvider = FutureProvider<StatsDashboard>((ref) async {
  final settings = await ref.watch(appSettingsControllerProvider.future);
  return ref
      .watch(statsRepositoryProvider)
      .loadDashboard(regionCode: settings.region.languageCode);
});

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(statsDashboardProvider);

    return AppAsyncView<StatsDashboard>(
      value: value,
      retry: () => ref.invalidate(statsDashboardProvider),
      data: (dashboard) {
        return RefreshIndicator(
          onRefresh: () => ref.refresh(statsDashboardProvider.future),
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
                _StatsSection(
                  title: 'Hero Trends',
                  icon: Icons.person_search_outlined,
                  children: [
                    for (final hero in dashboard.heroes.take(10))
                      _HeroStatsCard(hero: hero),
                  ],
                ),
                const SizedBox(height: 18),
                _StatsSection(
                  title: 'Equipment Trends',
                  icon: Icons.inventory_2_outlined,
                  children: [
                    for (final equip in dashboard.equips.take(10))
                      _EquipStatsCard(equip: equip),
                  ],
                ),
                const SizedBox(height: 18),
                _StatsSection(
                  title: 'Hero Combos',
                  icon: Icons.hub_outlined,
                  children: [
                    for (final combo in dashboard.combos.take(10))
                      _ComboStatsCard(combo: combo),
                  ],
                ),
              ],
            ],
          ),
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
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

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
          ],
        ),
        const SizedBox(height: 10),
        ...children.expand((child) => [child, const SizedBox(height: 10)]),
      ],
    );
  }
}

class _HeroStatsCard extends StatelessWidget {
  const _HeroStatsCard({required this.hero});

  final StatsHeroRow hero;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
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

class _EquipStatsCard extends StatelessWidget {
  const _EquipStatsCard({required this.equip});

  final StatsEquipRow equip;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
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
  const _MetricPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppTheme.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _PanelCard extends StatelessWidget {
  const _PanelCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(padding: const EdgeInsets.all(14), child: child),
    );
  }
}
