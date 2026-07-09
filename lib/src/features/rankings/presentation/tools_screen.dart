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
      assetIcon: 'assets/tools/bp.png',
      title: 'BP Simulator',
      subtitle: 'Draft schemes',
      route: '/tools/bp-simulator',
    ),
    _ToolItem(
      icon: Icons.format_list_numbered_outlined,
      assetIcon: 'assets/tools/tier.png',
      title: 'Tier List Tool',
      subtitle: 'Edit tiers',
      route: '/tools/tier-list',
    ),
    _ToolItem(
      icon: Icons.auto_awesome_outlined,
      assetIcon: 'assets/tools/prompt.png',
      title: 'Prompts',
      subtitle: 'AI templates',
      route: '/tools/prompts',
    ),
    _ToolItem(
      icon: Icons.groups_2_outlined,
      assetIcon: 'assets/tools/team.png',
      title: 'Team Builder',
      subtitle: 'Lineup advice',
      route: '/tools/team-builder',
    ),
    _ToolItem(
      icon: Icons.tune_outlined,
      assetIcon: 'assets/tools/build.png',
      title: 'Build Simulator',
      subtitle: 'Hero slots',
      route: '/tools/build-sim',
    ),
    _ToolItem(
      icon: Icons.auto_fix_high_outlined,
      assetIcon: 'assets/tools/fortune.png',
      title: 'Rank Fortune',
      subtitle: 'Daily draw',
      route: '/tools/rank-fortune',
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
            final cardWidth = (constraints.maxWidth - spacing) / 2;
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
    this.assetIcon,
  });

  final IconData icon;
  final String? assetIcon;
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
                _ToolIcon(tool: tool, size: 34),
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

class _ToolIcon extends StatelessWidget {
  const _ToolIcon({required this.tool, required this.size});

  final _ToolItem tool;
  final double size;

  @override
  Widget build(BuildContext context) {
    final assetIcon = tool.assetIcon;
    if (assetIcon != null) {
      return Image.asset(
        assetIcon,
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    }

    return Icon(tool.icon, color: AppTheme.gold, size: size);
  }
}
