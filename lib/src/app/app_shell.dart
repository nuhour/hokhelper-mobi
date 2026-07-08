import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    return Scaffold(
      body: SafeArea(child: navigationShell),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex(location),
        onDestinationSelected: (index) {
          context.go(_destinationRoute(index));
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '首页',
          ),
          NavigationDestination(
            icon: Icon(Icons.query_stats_outlined),
            selectedIcon: Icon(Icons.query_stats),
            label: '统计',
          ),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum),
            label: '社区',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: '工具',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
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
