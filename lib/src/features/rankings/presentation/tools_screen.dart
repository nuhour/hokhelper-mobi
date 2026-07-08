import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_section_header.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  static const _primaryTools = [
    _ToolItem(
      icon: Icons.account_tree_outlined,
      title: 'BP Simulator',
      subtitle: 'Draft schemes',
      route: '/tools/bp-simulator',
    ),
    _ToolItem(
      icon: Icons.format_list_numbered_outlined,
      title: 'Tier List Tool',
      subtitle: 'Edit tiers',
      route: '/tools/tier-list',
    ),
    _ToolItem(
      icon: Icons.auto_awesome_outlined,
      title: 'Prompts',
      subtitle: 'AI templates',
      route: '/tools/prompts',
    ),
    _ToolItem(
      icon: Icons.groups_2_outlined,
      title: 'Team Builder',
      subtitle: 'Lineup advice',
      route: '/tools/team-builder',
    ),
    _ToolItem(
      icon: Icons.tune_outlined,
      title: 'Build Simulator',
      subtitle: 'Hero slots',
      route: '/tools/build-sim',
    ),
    _ToolItem(
      icon: Icons.smartphone_outlined,
      title: 'Game Assistant',
      subtitle: 'Match helper',
      route: '/tools/game-assistant',
    ),
    _ToolItem(
      icon: Icons.auto_fix_high_outlined,
      title: 'Rank Fortune',
      subtitle: 'Daily draw',
      route: '/tools/rank-fortune',
    ),
    _ToolItem(
      icon: Icons.event_available_outlined,
      title: 'Event Assistance',
      subtitle: 'Help board',
      route: '/content/event-assistance',
    ),
    _ToolItem(
      icon: Icons.psychology_outlined,
      title: 'Curiosity Lab',
      subtitle: 'Mechanics Q&A',
      route: '/tools/curiosity-lab',
    ),
  ];

  static const _secondaryTools = [
    _ToolItem(
      icon: Icons.construction_outlined,
      title: 'Build Explorer',
      subtitle: 'Browse public build schemes',
      route: '/tools/builds',
    ),
    _ToolItem(
      icon: Icons.leaderboard_outlined,
      title: 'Rankings',
      subtitle: 'Compare hero performance metrics',
      route: '/tools/rankings',
    ),
    _ToolItem(
      icon: Icons.emoji_events_outlined,
      title: 'Player Leaderboard',
      subtitle: 'Browse ranked and peak score players',
      route: '/tools/leaderboard',
    ),
    _ToolItem(
      icon: Icons.emoji_events_outlined,
      title: 'Esports',
      subtitle: 'Matches, teams, and pro players',
      route: '/tools/esports',
    ),
    _ToolItem(
      icon: Icons.query_stats_outlined,
      title: 'Stats',
      subtitle: 'Rankings, tier list, and trends',
      route: '/tools/stats',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        AppSectionHeader(title: l10n.toolsTitle),
        const SizedBox(height: 16),
        LayoutBuilder(
          key: const ValueKey('tools-nine-grid'),
          builder: (context, constraints) {
            const spacing = 10.0;
            final cardWidth = (constraints.maxWidth - spacing * 2) / 3;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final tool in _primaryTools)
                  SizedBox(
                    width: cardWidth,
                    height: cardWidth * 1.14,
                    child: _ToolGridCard(
                      key: ValueKey('tool-grid-card-${tool.title}'),
                      tool: tool,
                      title: l10n.toolTitle(tool.route),
                      subtitle: l10n.toolSubtitle(tool.route),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        Text(
          l10n.toolsMore,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.text,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        for (final tool in _secondaryTools) ...[
          _ToolTile(
            tool: tool,
            title: l10n.toolTitle(tool.route),
            subtitle: l10n.toolSubtitle(tool.route),
          ),
          if (tool != _secondaryTools.last) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _ToolItem {
  const _ToolItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
}

class _ToolGridCard extends StatelessWidget {
  const _ToolGridCard({
    required this.tool,
    required this.title,
    required this.subtitle,
    super.key,
  });

  final _ToolItem tool;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go(tool.route),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.panel,
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(tool.icon, color: AppTheme.gold, size: 28),
                const SizedBox(height: 10),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    height: 1.12,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.muted,
                    fontSize: 11,
                    height: 1.1,
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

class _ToolTile extends StatelessWidget {
  const _ToolTile({
    required this.tool,
    required this.title,
    required this.subtitle,
  });

  final _ToolItem tool;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panel,
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          onTap: () => context.go(tool.route),
          leading: Icon(tool.icon, color: AppTheme.gold),
          trailing: const Icon(Icons.chevron_right, color: AppTheme.muted),
          title: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.text,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppTheme.muted),
          ),
        ),
      ),
    );
  }
}
