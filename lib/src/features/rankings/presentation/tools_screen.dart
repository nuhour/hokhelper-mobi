import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_section_header.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const AppSectionHeader(title: 'Tools'),
        const SizedBox(height: 16),
        _ToolTile(
          icon: Icons.leaderboard_outlined,
          title: 'Rankings',
          subtitle: 'Compare hero performance metrics',
          onTap: () => context.go('/tools/rankings'),
        ),
        const SizedBox(height: 12),
        _ToolTile(
          icon: Icons.emoji_events_outlined,
          title: 'Player Leaderboard',
          subtitle: 'Browse ranked and peak score players',
          onTap: () => context.go('/tools/leaderboard'),
        ),
        const SizedBox(height: 12),
        _ToolTile(
          icon: Icons.construction_outlined,
          title: 'Build Explorer',
          subtitle: 'Browse public build schemes',
          onTap: () => context.go('/tools/builds'),
        ),
        const SizedBox(height: 12),
        _ToolTile(
          icon: Icons.tune_outlined,
          title: 'Build Simulator',
          subtitle: 'Manage hero slots and clone community builds',
          onTap: () => context.go('/tools/build-sim'),
        ),
        const SizedBox(height: 12),
        _ToolTile(
          icon: Icons.account_tree_outlined,
          title: 'BP Simulator',
          subtitle: 'Review pick/ban schemes and draft progress',
          onTap: () => context.go('/tools/bp-simulator'),
        ),
        const SizedBox(height: 12),
        _ToolTile(
          icon: Icons.format_list_numbered_outlined,
          title: 'Tier List Tool',
          subtitle: 'Review custom hero tier list schemes',
          onTap: () => context.go('/tools/tier-list'),
        ),
        const SizedBox(height: 12),
        _ToolTile(
          icon: Icons.smartphone_outlined,
          title: 'Game Assistant',
          subtitle: 'Preview timers, economy, cooldowns, and AI tips',
          onTap: () => context.go('/tools/game-assistant'),
        ),
        const SizedBox(height: 12),
        _ToolTile(
          icon: Icons.auto_fix_high_outlined,
          title: 'Rank Fortune',
          subtitle: "Draw today's ranked match fortune",
          onTap: () => context.go('/tools/rank-fortune'),
        ),
        const SizedBox(height: 12),
        _ToolTile(
          icon: Icons.psychology_outlined,
          title: 'Curiosity Lab',
          subtitle: 'Query mechanics, interactions, and replay evidence',
          onTap: () => context.go('/tools/curiosity-lab'),
        ),
        const SizedBox(height: 12),
        _ToolTile(
          icon: Icons.groups_2_outlined,
          title: 'Team Builder',
          subtitle: 'Draft picks and review lineup recommendations',
          onTap: () => context.go('/tools/team-builder'),
        ),
        const SizedBox(height: 12),
        _ToolTile(
          icon: Icons.auto_awesome_outlined,
          title: 'Prompts',
          subtitle: 'Explore public AI prompt templates',
          onTap: () => context.go('/tools/prompts'),
        ),
        const SizedBox(height: 12),
        _ToolTile(
          icon: Icons.emoji_events_outlined,
          title: 'Esports',
          subtitle: 'Matches, teams, and pro players',
          onTap: () => context.go('/tools/esports'),
        ),
        const SizedBox(height: 12),
        _ToolTile(
          icon: Icons.query_stats_outlined,
          title: 'Stats',
          subtitle: 'Hero, equipment, and combo trends',
          onTap: () => context.go('/tools/stats'),
        ),
      ],
    );
  }
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

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
          onTap: onTap,
          leading: Icon(icon, color: AppTheme.gold),
          trailing: onTap == null
              ? null
              : const Icon(Icons.chevron_right, color: AppTheme.muted),
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
