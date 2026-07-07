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
            data: (stats) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HomePortalPreviews(result: stats.result),
                if (_hasHomePortalPreviews(stats.result))
                  const SizedBox(height: 18),
                _BackendSummary(stats: stats),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomePortalPreviews extends StatelessWidget {
  const _HomePortalPreviews({required this.result});

  final Map<String, dynamic> result;

  @override
  Widget build(BuildContext context) {
    final heroRows = _readList(_readMap(result['hero_ranking_table'])['rows']);
    final tierRows = _readList(result['tier_list']);
    final peakPlayers = _readList(_readMap(result['player_ranking'])['peak']);
    final communityPosts = _readList(result['community_hot']);
    final patchNotes = _readList(result['patch_notes']);

    final sections = <Widget>[
      if (heroRows.isNotEmpty)
        _HomePreviewSection(
          icon: Icons.bar_chart_outlined,
          title: 'Hero Rankings',
          route: '/tools/stats?entry=home_core',
          rows: [
            for (final row in heroRows.take(3))
              _HomePreviewRow(
                title: _readHeroName(row, fallback: 'Hero'),
                detail: _readRateDetail(row),
              ),
          ],
        ),
      if (tierRows.isNotEmpty)
        _HomePreviewSection(
          icon: Icons.local_fire_department_outlined,
          title: 'Tier List Preview',
          route: '/tier-list',
          rows: [
            for (final row in tierRows.take(4))
              _HomePreviewRow(
                title: _readString(row['tier'], fallback: 'Tier'),
                detail: _readTierHeroNames(row),
              ),
          ],
        ),
      if (peakPlayers.isNotEmpty)
        _HomePreviewSection(
          icon: Icons.emoji_events_outlined,
          title: 'Leaderboard',
          route: '/leaderboard',
          rows: [
            for (final row in peakPlayers.take(3))
              _HomePreviewRow(
                title: _readString(row['player_name'], fallback: 'Player'),
                detail: _readScoreDetail(row),
              ),
          ],
        ),
      if (communityPosts.isNotEmpty)
        _HomePreviewSection(
          icon: Icons.forum_outlined,
          title: 'Community Hot',
          route: '/content/community',
          rows: [
            for (final row in communityPosts.take(3))
              _HomePreviewRow(
                title: _readString(row['title'], fallback: 'Community post'),
                detail: _readString(row['content_preview']),
                route: _communityPostRoute(row['id']),
              ),
          ],
        ),
      if (patchNotes.isNotEmpty)
        _HomePreviewSection(
          icon: Icons.newspaper_outlined,
          title: 'Latest Updates',
          route: '/content/patch-notes',
          rows: [
            for (final row in patchNotes.take(3))
              _HomePreviewRow(
                title: _readString(row['title'], fallback: 'Patch note'),
                detail: _readString(row['content_preview']),
                route:
                    _communityPostRoute(row['post_id']) ??
                    _patchNoteRoute(row['id']),
              ),
          ],
        ),
    ];

    if (sections.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < sections.length; index++) ...[
          sections[index],
          if (index != sections.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _HomePreviewSection extends StatelessWidget {
  const _HomePreviewSection({
    required this.icon,
    required this.title,
    required this.route,
    required this.rows,
  });

  final IconData icon;
  final String title;
  final String route;
  final List<_HomePreviewRow> rows;

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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: AppTheme.gold, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppTheme.text,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chevron_right,
                      color: AppTheme.gold,
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                for (var index = 0; index < rows.length; index++) ...[
                  _HomePreviewTile(row: rows[index]),
                  if (index != rows.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomePreviewRow {
  const _HomePreviewRow({
    required this.title,
    required this.detail,
    this.route,
  });

  final String title;
  final String detail;
  final String? route;
}

class _HomePreviewTile extends StatelessWidget {
  const _HomePreviewTile({required this.row});

  final _HomePreviewRow row;

  @override
  Widget build(BuildContext context) {
    final route = row.route;
    final tile = DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panelAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                row.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (row.detail.isNotEmpty) ...[
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  row.detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (route == null) {
      return tile;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go(route),
        child: tile,
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

bool _hasHomePortalPreviews(Map<String, dynamic> result) {
  return _readList(_readMap(result['hero_ranking_table'])['rows']).isNotEmpty ||
      _readList(result['tier_list']).isNotEmpty ||
      _readList(_readMap(result['player_ranking'])['peak']).isNotEmpty ||
      _readList(result['community_hot']).isNotEmpty ||
      _readList(result['patch_notes']).isNotEmpty;
}

Map<String, dynamic> _readMap(Object? value) {
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return const {};
}

List<Map<String, dynamic>> _readList(Object? value) {
  if (value is! List) {
    return const [];
  }
  return [
    for (final item in value)
      if (item is Map) Map<String, dynamic>.from(item),
  ];
}

String _readString(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String? _communityPostRoute(Object? value) {
  final id = _readString(value);
  if (id.isEmpty) {
    return null;
  }
  return '/content/community/post/$id';
}

String? _patchNoteRoute(Object? value) {
  final id = _readString(value);
  if (id.isEmpty) {
    return null;
  }
  return '/content/patch-notes?note_id=$id';
}

String _readHeroName(Map<String, dynamic> row, {required String fallback}) {
  final hero = _readMap(row['hero']);
  return _readString(
    hero['name'] ?? row['name'] ?? row['hero_name'],
    fallback: fallback,
  );
}

String _readRateDetail(Map<String, dynamic> row) {
  final value = row['win_rate'];
  final rate = value is num ? value : num.tryParse(value?.toString() ?? '');
  if (rate == null) {
    return '';
  }
  final percent = rate > 1 ? rate : rate * 100;
  return '${percent.toStringAsFixed(1)}% WR';
}

String _readTierHeroNames(Map<String, dynamic> row) {
  final names = [
    for (final hero in _readList(row['heroes']).take(4))
      _readString(hero['name'] ?? hero['hero_name']),
  ].where((name) => name.isNotEmpty).join(', ');
  return names;
}

String _readScoreDetail(Map<String, dynamic> row) {
  final peakScore = _readString(row['peak_score']);
  if (peakScore.isNotEmpty) {
    return peakScore;
  }
  final rankStars = _readString(row['rank_stars']);
  return rankStars.isEmpty ? '' : '$rankStars stars';
}
