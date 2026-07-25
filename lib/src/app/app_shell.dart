import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/i18n/app_localizations.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final l10n = AppLocalizations.of(context);
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final selectedIndex = _selectedIndex(location);

    return Scaffold(
      body: SafeArea(bottom: false, child: navigationShell),
      bottomNavigationBar: isLandscape
          ? null
          : _CompactBottomNavigation(
              selectedIndex: selectedIndex,
              labels: [
                l10n.navHome,
                l10n.navStats,
                l10n.navCommunity,
                l10n.navTools,
                l10n.navMe,
              ],
              onSelected: (index) => context.go(_destinationRoute(index)),
            ),
    );
  }

  int _selectedIndex(String location) {
    if (location == '/me') {
      return 4;
    }
    if (location == '/tools') {
      return 3;
    }
    if (location.startsWith('/tools/') &&
        !location.startsWith('/tools/stats')) {
      return 3;
    }
    if (location.startsWith('/content/community')) {
      return 2;
    }
    if (location.startsWith('/stats-home')) {
      return 1;
    }
    if (location.startsWith('/tools/stats')) {
      return 1;
    }
    return 0;
  }

  String _destinationRoute(int index) {
    return switch (index) {
      1 => '/stats-home',
      2 => '/content/community',
      3 => '/tools',
      4 => '/me',
      _ => '/',
    };
  }
}

class _CompactBottomNavigation extends StatelessWidget {
  const _CompactBottomNavigation({
    required this.selectedIndex,
    required this.labels,
    required this.onSelected,
  });

  final int selectedIndex;
  final List<String> labels;
  final ValueChanged<int> onSelected;

  static const _icons = [
    (Icons.home_outlined, Icons.home),
    (Icons.query_stats_outlined, Icons.query_stats),
    (Icons.forum_outlined, Icons.forum),
    (Icons.handyman_outlined, Icons.handyman_rounded),
    (Icons.person_outline, Icons.person),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navigationTheme = theme.navigationBarTheme;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final background =
        navigationTheme.backgroundColor ?? theme.colorScheme.surface;
    final indicator =
        navigationTheme.indicatorColor ?? theme.colorScheme.secondaryContainer;

    return Material(
      key: const ValueKey('compact-bottom-navigation'),
      color: background,
      child: SizedBox(
        height: 58 + bottomInset,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.noScaling),
            child: Row(
              children: [
                for (var index = 0; index < labels.length; index++)
                  Expanded(
                    child: _CompactDestination(
                      label: labels[index],
                      icon: _icons[index].$1,
                      selectedIcon: _icons[index].$2,
                      selected: selectedIndex == index,
                      indicatorColor: indicator,
                      onTap: () => onSelected(index),
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

class _CompactDestination extends StatelessWidget {
  const _CompactDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.indicatorColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final Color indicatorColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final states = selected ? {WidgetState.selected} : <WidgetState>{};
    final iconTheme = theme.navigationBarTheme.iconTheme?.resolve(states);
    final labelStyle = theme.navigationBarTheme.labelTextStyle?.resolve(states);

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 48,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? indicatorColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  selected ? selectedIcon : icon,
                  size: 21,
                  color: iconTheme?.color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.fade,
                style: labelStyle?.copyWith(
                  fontSize: 10,
                  height: 1,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
