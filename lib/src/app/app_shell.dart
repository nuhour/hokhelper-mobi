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

    return Scaffold(
      body: SafeArea(child: navigationShell),
      bottomNavigationBar: isLandscape
          ? null
          : MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.noScaling),
              child: NavigationBarTheme(
                data: NavigationBarTheme.of(context).copyWith(
                  labelTextStyle: WidgetStateProperty.resolveWith((states) {
                    return Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      height: 1,
                      fontWeight: states.contains(WidgetState.selected)
                          ? FontWeight.w800
                          : FontWeight.w600,
                    );
                  }),
                ),
                child: NavigationBar(
                  height: 56,
                  selectedIndex: _selectedIndex(location),
                  onDestinationSelected: (index) {
                    context.go(_destinationRoute(index));
                  },
                  destinations: [
                    NavigationDestination(
                      icon: const Icon(Icons.home_outlined),
                      selectedIcon: const Icon(Icons.home),
                      label: l10n.navHome,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.query_stats_outlined),
                      selectedIcon: const Icon(Icons.query_stats),
                      label: l10n.navStats,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.forum_outlined),
                      selectedIcon: const Icon(Icons.forum),
                      label: l10n.navCommunity,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.handyman_outlined),
                      selectedIcon: const Icon(Icons.handyman_rounded),
                      label: l10n.navTools,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.person_outline),
                      selectedIcon: const Icon(Icons.person),
                      label: l10n.navMe,
                    ),
                  ],
                ),
              ),
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
