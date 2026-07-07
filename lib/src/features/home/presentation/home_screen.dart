import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_section_header.dart';
import '../data/home_repository.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository(apiClient: ref.watch(apiClientProvider));
});

final homeStatsProvider = FutureProvider<HomeStats>((ref) {
  return ref.watch(homeRepositoryProvider).loadHomeStats();
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsValue = ref.watch(homeStatsProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(homeStatsProvider.future),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const AppSectionHeader(title: 'HOK Helper'),
          const SizedBox(height: 12),
          Text(
            'Mobile companion for heroes, builds, content, tools, and your account.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppTheme.muted),
          ),
          const SizedBox(height: 18),
          const _SearchEntryCard(),
          const SizedBox(height: 18),
          const _HomePrimaryActions(),
          const SizedBox(height: 18),
          const _HomeToolGrid(),
          const SizedBox(height: 18),
          const _HokWorldEntryCard(),
          const SizedBox(height: 24),
          AppAsyncView<HomeStats>(
            value: statsValue,
            retry: () => ref.invalidate(homeStatsProvider),
            data: (stats) => _BackendSummary(stats: stats),
          ),
        ],
      ),
    );
  }
}

class _HomePrimaryActions extends StatelessWidget {
  const _HomePrimaryActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _PrimaryActionCard(
            title: 'View Core Stats',
            subtitle: 'Home metrics',
            route: '/tools/stats?entry=home_core',
            icon: Icons.bar_chart_outlined,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _PrimaryActionCard(
            title: 'Enter Tier List',
            subtitle: 'Hero tiers',
            route: '/tier-list',
            icon: Icons.leaderboard_outlined,
          ),
        ),
      ],
    );
  }
}

class _PrimaryActionCard extends StatelessWidget {
  const _PrimaryActionCard({
    required this.title,
    required this.subtitle,
    required this.route,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String route;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go(route),
        child: Ink(
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
                Icon(icon, color: AppTheme.gold, size: 22),
                const SizedBox(height: 10),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeToolGrid extends StatelessWidget {
  const _HomeToolGrid();

  static const _tools = [
    _HomeTool(
      title: 'BP Simulator',
      route: '/tools/bp-simulator',
      icon: Icons.sports_esports_outlined,
    ),
    _HomeTool(
      title: 'Tier Editor',
      route: '/tools/tier-list',
      icon: Icons.format_list_bulleted_outlined,
    ),
    _HomeTool(
      title: 'AI Prompts',
      route: '/tools/prompts',
      icon: Icons.auto_fix_high_outlined,
    ),
    _HomeTool(
      title: 'Team Builder',
      route: '/tools/team-builder',
      icon: Icons.groups_2_outlined,
    ),
    _HomeTool(
      title: 'Build Sim',
      route: '/tools/build-sim',
      icon: Icons.construction_outlined,
    ),
    _HomeTool(
      title: 'Rank Fortune',
      route: '/tools/rank-fortune',
      icon: Icons.auto_awesome_outlined,
    ),
    _HomeTool(
      title: 'Event Assistance',
      route: '/content/event-assistance',
      icon: Icons.event_available_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Tools',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.text,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 10) / 2;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final tool in _tools)
                  SizedBox(
                    width: cardWidth,
                    child: _HomeToolCard(tool: tool),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _HomeTool {
  const _HomeTool({
    required this.title,
    required this.route,
    required this.icon,
  });

  final String title;
  final String route;
  final IconData icon;
}

class _HomeToolCard extends StatelessWidget {
  const _HomeToolCard({required this.tool});

  final _HomeTool tool;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go(tool.route),
        child: Ink(
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
                Icon(tool.icon, color: AppTheme.gold, size: 22),
                const SizedBox(height: 10),
                Text(
                  tool.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.text,
                    fontWeight: FontWeight.w800,
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

class _HokWorldEntryCard extends StatelessWidget {
  const _HokWorldEntryCard();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/hok-world'),
        child: Ink(
          decoration: BoxDecoration(
            color: AppTheme.panel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.public_outlined, color: AppTheme.gold),
                    SizedBox(width: 10),
                    Text(
                      'HOK World',
                      style: TextStyle(
                        color: AppTheme.text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Move from HOK World character hype to practical ranked decisions with a dedicated topic page, live tier context, and direct routes into stats and hero details.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Enter HOK World Topic',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.gold,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.chevron_right,
                      color: AppTheme.gold,
                      size: 18,
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

class _SearchEntryCard extends StatelessWidget {
  const _SearchEntryCard();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/search'),
        child: Ink(
          decoration: BoxDecoration(
            color: AppTheme.panel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.manage_search_outlined, color: AppTheme.gold),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Global Search',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppTheme.text,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Find heroes, builds, guides, and community content.',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: AppTheme.gold),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BackendSummary extends StatelessWidget {
  const _BackendSummary({required this.stats});

  final HomeStats stats;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final statusColor = stats.success ? AppTheme.cyan : AppTheme.error;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panel,
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_done_outlined, color: statusColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    stats.success ? 'Backend connected' : 'Backend responded',
                    style: textTheme.titleMedium?.copyWith(
                      color: AppTheme.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              stats.message,
              style: textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
            ),
            const SizedBox(height: 20),
            if (stats.result.isEmpty)
              Text(
                'No stats returned yet.',
                style: textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final entry in stats.result.entries)
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: constraints.maxWidth,
                          ),
                          child: _StatChip(
                            label: entry.key,
                            value: entry.value.toString(),
                          ),
                        ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panelAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.text,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
