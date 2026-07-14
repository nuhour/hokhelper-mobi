import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_image.dart';
import '../../content/presentation/skin_gallery_screen.dart';
import '../../esports/presentation/esports_screen.dart';
import '../../heroes/presentation/hero_gallery_screen.dart';
import '../../search/presentation/search_screen.dart';
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
        key: const ValueKey('home-main-scroll-view'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          AppAsyncView<HomeStats>(
            value: statsValue,
            retry: () => ref.invalidate(homeStatsProvider),
            loadingStyle: AppAsyncLoadingStyle.dashboard,
            data: (stats) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [_HomePortalFramework(result: stats.result)],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomePortalFramework extends StatefulWidget {
  const _HomePortalFramework({required this.result});

  final Map<String, dynamic> result;

  @override
  State<_HomePortalFramework> createState() => _HomePortalFrameworkState();
}

class _HomePortalFrameworkState extends State<_HomePortalFramework> {
  late final PageController _pageController;
  int _selectedPage = 3;
  var _showPortalTopBar = true;

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

  void _setPortalTopBarVisible(bool visible) {
    if (_showPortalTopBar == visible) {
      return;
    }
    setState(() => _showPortalTopBar = visible);
  }

  @override
  Widget build(BuildContext context) {
    final pageHeight = (MediaQuery.sizeOf(context).height - 96).clamp(
      620.0,
      980.0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IgnorePointer(
          ignoring: !_showPortalTopBar,
          child: AnimatedOpacity(
            opacity: _showPortalTopBar ? 1 : 0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: _HomePortalTopBar(
              selectedIndex: _selectedPage,
              onSelected: _selectPage,
            ),
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          key: const ValueKey('home-tab-page-view'),
          height: pageHeight,
          child: PageView(
            controller: _pageController,
            allowImplicitScrolling: true,
            onPageChanged: (index) {
              setState(() {
                _selectedPage = index;
                if (index != 3) {
                  _showPortalTopBar = true;
                }
              });
            },
            children: [
              const EsportsScreen(),
              const SkinGalleryScreen(),
              const HeroGalleryScreen(),
              _HomeLandingTab(
                result: widget.result,
                onPortalTopBarVisibilityChanged: _setPortalTopBarVisible,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HomePortalTopBar extends StatelessWidget {
  const _HomePortalTopBar({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final entries = [
      _TopNavEntry(l10n.homeTabEsports),
      _TopNavEntry(l10n.homeTabSkins),
      _TopNavEntry(l10n.homeTabHeroes),
      _TopNavEntry(l10n.homeTabHome),
    ];

    return Row(
      children: [
        _RoundIconButton(
          icon: Icons.menu_rounded,
          onTap: () => _showPortalMenu(context),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              key: const ValueKey('home-top-tab-strip'),
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var index = 0; index < entries.length; index++) ...[
                    _PortalNavPill(
                      index: index,
                      entry: entries[index],
                      selected: index == selectedIndex,
                      onTap: () => onSelected(index),
                    ),
                    if (index != entries.length - 1) const SizedBox(width: 18),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _RoundIconButton(
          icon: Icons.search_rounded,
          onTap: () => showPortalSearchSheet(context),
        ),
      ],
    );
  }
}

class _HomeLandingTab extends StatefulWidget {
  const _HomeLandingTab({
    required this.result,
    required this.onPortalTopBarVisibilityChanged,
  });

  final Map<String, dynamic> result;
  final ValueChanged<bool> onPortalTopBarVisibilityChanged;

  @override
  State<_HomeLandingTab> createState() => _HomeLandingTabState();
}

class _HomeLandingTabState extends State<_HomeLandingTab> {
  var _showWorld = false;

  bool _onScrollNotification(UserScrollNotification notification) {
    final offset = notification.metrics.pixels;
    if (notification.direction == ScrollDirection.forward || offset <= 16) {
      widget.onPortalTopBarVisibilityChanged(true);
    } else if (notification.direction == ScrollDirection.reverse &&
        offset > 16) {
      widget.onPortalTopBarVisibilityChanged(false);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final backgroundUrl = _readString(
      _readMap(widget.result['season'])['mobile_background_pic'] ??
          _readMap(widget.result['season'])['background_pic'],
    );
    final seasonName = _readString(_readMap(widget.result['season'])['name']);
    final bottomNavigationGap = MediaQuery.viewPaddingOf(context).bottom + 104;
    return Stack(
      children: [
        NotificationListener<UserScrollNotification>(
          onNotification: _onScrollNotification,
          child: ListView(
            key: const ValueKey('home-landing-scroll-view'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(bottom: bottomNavigationGap),
            children: [
              Stack(
                children: [
                  Positioned.fill(
                    child: backgroundUrl.isNotEmpty
                        ? AppImage(
                            url: backgroundUrl,
                            fit: BoxFit.cover,
                            borderRadius: 0,
                            semanticLabel: 'Honor of Kings season background',
                          )
                        : const ColoredBox(color: AppTheme.bg),
                  ),
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x66020617),
                            Color(0xCC020617),
                            Color(0xF7020617),
                          ],
                          stops: [0, 0.36, 1],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
                    child: Column(
                      children: [
                        _HomeHeroBanner(
                          seasonName: seasonName,
                          showWorld: _showWorld,
                          onWorldChanged: (value) {
                            setState(() => _showWorld = value);
                          },
                        ),
                        const SizedBox(height: 18),
                        _HomePortalPreviews(result: widget.result),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ],
    );
  }
}

void _showPortalMenu(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: AppTheme.panel,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => const _PortalMenuSheet(),
  );
}

class _PortalMenuSheet extends StatelessWidget {
  const _PortalMenuSheet();

  static const _groups = [
    _PortalMenuGroup(title: '首页', links: [_PortalMenuLink('首页', '/')]),
    _PortalMenuGroup(
      title: '英雄',
      links: [
        _PortalMenuLink('图鉴', '/heroes'),
        _PortalMenuLink('梯度榜', '/tier-list'),
        _PortalMenuLink('强度趋势', '/tools/stats?entry=hero_trend'),
      ],
    ),
    _PortalMenuGroup(
      title: '皮肤',
      links: [
        _PortalMenuLink('图鉴', '/content/skins'),
        _PortalMenuLink('CG', '/content/cgs'),
      ],
    ),
    _PortalMenuGroup(
      title: '社区',
      links: [
        _PortalMenuLink('玩家排行榜', '/leaderboard'),
        _PortalMenuLink('论坛', '/content/community'),
        _PortalMenuLink('爆料', '/content/community?tab=leaks'),
        _PortalMenuLink('活动互助', '/content/event-assistance'),
      ],
    ),
    _PortalMenuGroup(
      title: '赛事',
      links: [
        _PortalMenuLink('赛程', '/esports/schedule'),
        _PortalMenuLink('赛事统计', '/esports/stats'),
        _PortalMenuLink('战队', '/esports/teams'),
        _PortalMenuLink('职业选手', '/esports/players'),
      ],
    ),
    _PortalMenuGroup(
      title: '工具',
      links: [
        _PortalMenuLink('全局 BP 模拟器', '/tools/bp-simulator'),
        _PortalMenuLink('梯度编辑器', '/tools/tier-list'),
        _PortalMenuLink('AI 提示词', '/tools/prompts'),
        _PortalMenuLink('阵容搭配', '/tools/team-builder'),
        _PortalMenuLink('出装方案', '/tools/build-sim'),
        _PortalMenuLink('局内助手', '/tools/game-assistant'),
        _PortalMenuLink('上分运势', '/tools/rank-fortune'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.muted.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.menu_book_outlined, color: AppTheme.gold),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '站点菜单',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.text,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: AppTheme.muted),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _groups.length,
                separatorBuilder: (context, index) => Divider(
                  color: AppTheme.outline.withValues(alpha: 0.75),
                  height: 22,
                ),
                itemBuilder: (context, index) {
                  return _PortalMenuGroupView(group: _groups[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PortalMenuGroup {
  const _PortalMenuGroup({required this.title, required this.links});

  final String title;
  final List<_PortalMenuLink> links;
}

class _PortalMenuLink {
  const _PortalMenuLink(this.label, this.route);

  final String label;
  final String route;
}

class _PortalMenuGroupView extends StatelessWidget {
  const _PortalMenuGroupView({required this.group});

  final _PortalMenuGroup group;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          group.title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppTheme.text,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final link in group.links) _PortalMenuChip(link: link),
          ],
        ),
      ],
    );
  }
}

class _PortalMenuChip extends StatelessWidget {
  const _PortalMenuChip({required this.link});

  final _PortalMenuLink link;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () {
          Navigator.of(context).pop();
          context.go(link.route);
        },
        child: Ink(
          decoration: BoxDecoration(
            color: AppTheme.panelAlt,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppTheme.outline),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            link.label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppTheme.muted,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _TopNavEntry {
  const _TopNavEntry(this.label);

  final String label;
}

class _PortalNavPill extends StatelessWidget {
  const _PortalNavPill({
    required this.index,
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  final int index;
  final _TopNavEntry entry;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                entry.label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: selected ? AppTheme.text : AppTheme.muted,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              AnimatedContainer(
                key: selected
                    ? ValueKey('home-top-tab-indicator-$index')
                    : null,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                width: selected ? 20 : 0,
                height: 3,
                decoration: BoxDecoration(
                  color: selected ? AppTheme.text : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Ink(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppTheme.panel,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Icon(icon, color: AppTheme.text, size: 22),
        ),
      ),
    );
  }
}

class _HomeHeroBanner extends StatelessWidget {
  const _HomeHeroBanner({
    required this.seasonName,
    required this.showWorld,
    required this.onWorldChanged,
  });

  final String seasonName;
  final bool showWorld;
  final ValueChanged<bool> onWorldChanged;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).width < 360 ? 380 : 220,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Color(0x33020617)),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _HomeLiveBadge(season: seasonName),
                      _HomeHeroSlideTabs(
                        showWorld: showWorld,
                        onChanged: onWorldChanged,
                      ),
                    ],
                  ),
                  const Spacer(),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: showWorld
                        ? _HomeWorldHeroContent(
                            key: ValueKey('home-world-hero-content'),
                            onBack: () => onWorldChanged(false),
                          )
                        : const _HomeMainHeroContent(
                            key: ValueKey('home-main-hero-content'),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeLiveBadge extends StatelessWidget {
  const _HomeLiveBadge({required this.season});

  final String season;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bolt_rounded, color: AppTheme.gold, size: 16),
            const SizedBox(width: 5),
            Text(
              '${season.isEmpty ? 'S15' : season}  Live Now',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeroSlideTabs extends StatelessWidget {
  const _HomeHeroSlideTabs({required this.showWorld, required this.onChanged});

  final bool showWorld;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _HomeHeroTab(
              label: 'HOK',
              selected: !showWorld,
              onTap: () => onChanged(false),
            ),
            _HomeHeroTab(
              label: 'HOK World',
              selected: showWorld,
              onTap: () => onChanged(true),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeroTab extends StatelessWidget {
  const _HomeHeroTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? Colors.white.withValues(alpha: 0.18)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: selected ? Colors.white : Colors.white70,
              fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeMainHeroContent extends StatelessWidget {
  const _HomeMainHeroContent({super.key});

  @override
  Widget build(BuildContext context) {
    return _HomeHeroContent(
      title: 'HOK HELPER',
      description:
          'Live rankings, hero data, and practical decisions for every match.',
      buttons: [
        _HomeHeroButton(
          label: 'Core Stats',
          icon: Icons.bar_chart_rounded,
          onTap: () => context.go('/tools/stats?entry=home_core'),
        ),
        _HomeHeroButton(
          label: 'Tier List',
          icon: Icons.leaderboard_rounded,
          onTap: () => context.go('/tier-list'),
        ),
      ],
    );
  }
}

class _HomeWorldHeroContent extends StatelessWidget {
  const _HomeWorldHeroContent({required this.onBack, super.key});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return _HomeHeroContent(
      leading: IconButton(
        tooltip: 'Back to HOK',
        onPressed: onBack,
        icon: const Icon(Icons.arrow_back_rounded),
        color: Colors.white,
        style: IconButton.styleFrom(
          backgroundColor: Colors.black.withValues(alpha: 0.28),
        ),
      ),
      title: 'HOK WORLD',
      description:
          'Explore the world, characters, and stories behind Honor of Kings.',
      buttons: [
        _HomeHeroButton(
          label: 'Enter HOK World',
          icon: Icons.public_rounded,
          onTap: () => context.go('/hok-world'),
        ),
      ],
    );
  }
}

class _HomeHeroContent extends StatelessWidget {
  const _HomeHeroContent({
    this.leading,
    required this.title,
    required this.description,
    required this.buttons,
  });

  final String title;
  final String description;
  final List<_HomeHeroButton> buttons;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (leading != null)
          Align(alignment: Alignment.centerLeft, child: leading!),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.78),
            height: 1.35,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 9,
          runSpacing: 9,
          children: buttons,
        ),
      ],
    );
  }
}

class _HomeHeroButton extends StatelessWidget {
  const _HomeHeroButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: AppTheme.gold,
        minimumSize: const Size(0, 42),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// Kept as a reference for the previous portal composition; it is intentionally
// not mounted on the data-first home screen.
// ignore: unused_element
class _HomeBentoGrid extends StatelessWidget {
  const _HomeBentoGrid({required this.trendingHero, required this.latestPatch});

  final Map<String, dynamic> trendingHero;
  final Map<String, dynamic> latestPatch;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TrendingHeroCard(row: trendingHero),
        const SizedBox(height: 10),
        Row(
          children: const [
            Expanded(
              child: _BentoShortcutCard(
                title: 'BP Simulator',
                route: '/tools/bp-simulator',
                icon: Icons.sports_esports_outlined,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _BentoShortcutCard(
                title: 'Tier List',
                route: '/tier-list',
                icon: Icons.leaderboard_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _LatestPatchCard(row: latestPatch),
      ],
    );
  }
}

class _TrendingHeroCard extends StatelessWidget {
  const _TrendingHeroCard({required this.row});

  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final name = _readHeroName(row, fallback: 'Featured Hero');
    final role = _readHeroRole(row);
    final winRate = _readRateDetail(row);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.go('/tools/stats?entry=home_core'),
        child: Ink(
          decoration: BoxDecoration(
            color: AppTheme.panel,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.panelAlt,
                  child: Icon(
                    Icons.shield_outlined,
                    color: AppTheme.gold,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trending Heroes',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppTheme.gold,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.text,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (role.isNotEmpty || winRate.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          [
                            role,
                            winRate,
                          ].where((item) => item.isNotEmpty).join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.muted),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'View All',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppTheme.gold,
                    fontWeight: FontWeight.w900,
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

class _BentoShortcutCard extends StatelessWidget {
  const _BentoShortcutCard({
    required this.title,
    required this.route,
    required this.icon,
  });

  final String title;
  final String route;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.go(route),
        child: Ink(
          decoration: BoxDecoration(
            color: AppTheme.panel,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppTheme.gold, size: 24),
              const SizedBox(height: 12),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.text,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LatestPatchCard extends StatelessWidget {
  const _LatestPatchCard({required this.row});

  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final title = _readString(row['title'], fallback: 'Latest balance update');
    final summary = _readString(
      row['content_preview'] ?? row['summary'],
      fallback: 'Track the newest hero, item, and battlefield changes.',
    );
    final version = _readPatchVersion(row);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          context.go(_patchNoteRoute(row['id']) ?? '/content/patch-notes');
        },
        child: Ink(
          decoration: BoxDecoration(
            color: AppTheme.panel,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Latest Patch',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppTheme.gold,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    if (version.isNotEmpty)
                      Text(
                        version,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: AppTheme.muted,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                ),
                const SizedBox(height: 12),
                Text(
                  'Read Notes',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppTheme.gold,
                    fontWeight: FontWeight.w900,
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

class _HomePortalPreviews extends StatelessWidget {
  const _HomePortalPreviews({required this.result});

  final Map<String, dynamic> result;

  @override
  Widget build(BuildContext context) {
    final heroRows = _readList(_readMap(result['hero_ranking_table'])['rows']);
    final heroColumns = _readMap(result['hero_ranking_table'])['columns'];
    final tierRows = _readList(result['tier_list']);
    final peakPlayers = _readList(_readMap(result['player_ranking'])['peak']);
    final communityPosts = _readList(result['community_hot']);
    final patchNotes = _readList(result['patch_notes']);

    final sections = <Widget>[
      _HomeHeroRankingTable(rows: heroRows, rawColumns: heroColumns),
      _HomeTierPreviewSection(
        icon: Icons.local_fire_department_outlined,
        title: 'Tier List Preview',
        route: '/tier-list',
        groups: tierRows.take(4).toList(growable: false),
      ),
      _HomePlayerRankingTable(
        peakRows: peakPlayers,
        rankRows: _readList(_readMap(result['player_ranking'])['rank']),
      ),
      _HomeCommunitySection(
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
      _HomePatchNotesSection(
        icon: Icons.newspaper_outlined,
        title: 'Latest Updates',
        route: '/content/patch-notes',
        notes: patchNotes.take(3).toList(growable: false),
        fallbackHeroes: _readList(result['hero_stats']).take(3).toList(),
      ),
    ];

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

class _HomeHeroRankingTable extends StatelessWidget {
  const _HomeHeroRankingTable({required this.rows, required this.rawColumns});

  final List<Map<String, dynamic>> rows;
  final Object? rawColumns;

  @override
  Widget build(BuildContext context) {
    final columns = _homeTableColumns(rawColumns, rows);
    final dataRows = rows;

    return _HomeDataSection(
      icon: Icons.bar_chart_outlined,
      title: 'Hero Rankings',
      route: '/tools/stats?entry=home_core',
      child: _HomeDataTable(columns: columns, rows: dataRows, maxRows: 116),
    );
  }
}

class _HomePlayerRankingTable extends StatefulWidget {
  const _HomePlayerRankingTable({
    required this.peakRows,
    required this.rankRows,
  });

  final List<Map<String, dynamic>> peakRows;
  final List<Map<String, dynamic>> rankRows;

  @override
  State<_HomePlayerRankingTable> createState() =>
      _HomePlayerRankingTableState();
}

class _HomePlayerRankingTableState extends State<_HomePlayerRankingTable> {
  String _selected = 'peak';

  @override
  Widget build(BuildContext context) {
    final rows = _selected == 'peak' ? widget.peakRows : widget.rankRows;
    return _HomeDataSection(
      icon: Icons.emoji_events_outlined,
      title: 'Leaderboard',
      route: '/leaderboard',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SegmentedButton<String>(
            key: const ValueKey('home-player-ranking-mode'),
            segments: const [
              ButtonSegment(value: 'peak', label: Text('Peak')),
              ButtonSegment(value: 'rank', label: Text('Rank')),
            ],
            selected: {_selected},
            onSelectionChanged: (selection) {
              setState(() {
                _selected = selection.first;
              });
            },
            showSelectedIcon: false,
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 8),
              ),
              textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 11)),
            ),
          ),
          const SizedBox(height: 4),
          _HomePlayerTable(rows: rows, mode: _selected),
        ],
      ),
    );
  }
}

class _HomePlayerTable extends StatelessWidget {
  const _HomePlayerTable({required this.rows, required this.mode});

  final List<Map<String, dynamic>> rows;
  final String mode;

  @override
  Widget build(BuildContext context) {
    final columns = [
      const _HomeTableColumn(
        id: 'player_name',
        label: 'Player',
        type: 'player',
      ),
      const _HomeTableColumn(id: 'rank', label: '#', type: 'number'),
      _HomeTableColumn(
        id: mode == 'peak' ? 'peak_score' : 'rank_stars',
        label: mode == 'peak' ? 'Peak' : 'Stars',
        type: 'number',
      ),
      const _HomeTableColumn(
        id: 'win_rate',
        label: 'Win Rate',
        type: 'percent',
      ),
      const _HomeTableColumn(id: 'avg_kda', label: 'KDA', type: 'number'),
    ];
    return _HomeDataTable(columns: columns, rows: rows.take(8).toList());
  }
}

class _HomeDataSection extends StatelessWidget {
  const _HomeDataSection({
    required this.icon,
    required this.title,
    required this.route,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String route;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: AppTheme.panel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: AppTheme.gold, size: 21),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go(route),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('View More'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeDataTable extends StatefulWidget {
  const _HomeDataTable({
    required this.columns,
    required this.rows,
    this.maxRows = 8,
  });

  final List<_HomeTableColumn> columns;
  final List<Map<String, dynamic>> rows;
  final int maxRows;

  @override
  State<_HomeDataTable> createState() => _HomeDataTableState();
}

class _HomeDataTableState extends State<_HomeDataTable> {
  static const _firstColumnWidth = 52.0;
  static const _headerHeight = 34.0;
  static const _rowHeight = 48.0;

  final _verticalController = ScrollController();
  final _horizontalController = ScrollController();

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.rows.isEmpty) {
      return Text(
        'No data',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
      );
    }
    final heroColumn = widget.columns.first;
    final metricColumns = widget.columns.skip(1).toList(growable: false);
    final metricWidth = metricColumns.fold<double>(
      0,
      (total, column) => total + _homeTableColumnWidth(column),
    );
    final fixedHeader = Container(
      key: const ValueKey('home-hero-ranking-fixed-header'),
      width: _firstColumnWidth,
      height: _headerHeight,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      color: AppTheme.panel,
      child: Text(
        heroColumn.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppTheme.muted,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
    final metricHeader = SingleChildScrollView(
      controller: _horizontalController,
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: metricWidth),
        child: Row(
          children: [
            for (final column in metricColumns)
              SizedBox(
                width: _homeTableColumnWidth(column),
                height: _headerHeight,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    column.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.muted,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    final metricRows = Column(
      children: [
        for (final row in widget.rows.take(widget.maxRows))
          SizedBox(
            height: _rowHeight,
            child: Row(
              children: [
                for (final column in metricColumns)
                  SizedBox(
                    width: _homeTableColumnWidth(column),
                    height: _rowHeight,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _HomeDataCell(row: row, column: column),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
    final identityRows = Column(
      children: [
        for (final row in widget.rows.take(widget.maxRows))
          SizedBox(
            width: _firstColumnWidth,
            height: _rowHeight,
            child: ColoredBox(
              color: AppTheme.panel,
              child: Center(
                child: _HomeFixedTableIdentity(row: row, column: heroColumn),
              ),
            ),
          ),
      ],
    );
    return SizedBox(
      key: const ValueKey('home-hero-ranking-scroll-area'),
      height: 420,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: AppTheme.outline.withValues(alpha: 0.7)),
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: _headerHeight,
              left: _firstColumnWidth,
              right: 0,
              bottom: 0,
              child: SingleChildScrollView(
                controller: _verticalController,
                child: SingleChildScrollView(
                  controller: _horizontalController,
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: metricWidth),
                    child: metricRows,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: _headerHeight,
              child: ColoredBox(
                color: AppTheme.panel,
                child: Row(
                  children: [
                    fixedHeader,
                    Expanded(child: metricHeader),
                  ],
                ),
              ),
            ),
            Positioned(
              top: _headerHeight,
              left: 0,
              width: _firstColumnWidth,
              bottom: 0,
              child: ClipRect(
                child: AnimatedBuilder(
                  animation: _verticalController,
                  builder: (context, child) {
                    final offset = _verticalController.hasClients
                        ? _verticalController.offset
                        : 0.0;
                    return Transform.translate(
                      offset: Offset(0, -offset),
                      child: child,
                    );
                  },
                  child: identityRows,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

double _homeTableColumnWidth(_HomeTableColumn column) {
  if (column.id == 'player_name' || column.type == 'player') return 132;
  if (column.id == 'hero' || column.type == 'hero') return 52;
  return 72;
}

class _HomeTableColumn {
  const _HomeTableColumn({required this.id, required this.label, this.type});

  final String id;
  final String label;
  final String? type;
}

class _HomeDataCell extends StatelessWidget {
  const _HomeDataCell({required this.row, required this.column});

  final Map<String, dynamic> row;
  final _HomeTableColumn column;

  @override
  Widget build(BuildContext context) {
    final cellStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: AppTheme.text,
      fontWeight: FontWeight.w700,
    );
    final isHero = column.id == 'hero' || column.type == 'hero';
    final isPlayer = column.id == 'player_name' || column.type == 'player';
    final minWidth = isHero ? 52.0 : (isPlayer ? 132.0 : 48.0);
    final maxWidth = isHero ? 52.0 : (isPlayer ? 170.0 : 92.0);
    if (!isHero && !isPlayer) {
      return ConstrainedBox(
        constraints: BoxConstraints(minWidth: minWidth, maxWidth: maxWidth),
        child: Text(
          _homeTableValue(row, column),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: cellStyle,
        ),
      );
    }

    final avatarUrl = isHero
        ? _homeHeroAvatarUrl(row)
        : _readString(
            row['avatar_url'] ?? _readMap(row['player'])['avatar_url'],
          );
    final heroName = _homeTableValue(row, column);
    if (isHero) {
      return ConstrainedBox(
        constraints: BoxConstraints(minWidth: minWidth, maxWidth: maxWidth),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [_HomeHeroAvatarCluster(row: row, heroName: heroName)],
        ),
      );
    }
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: minWidth, maxWidth: maxWidth),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: AppImage(
              url: avatarUrl,
              width: 28,
              height: 28,
              borderRadius: 999,
              excludeFromSemantics: true,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              _homeTableValue(row, column),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: cellStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeDataIcon extends StatelessWidget {
  const _HomeDataIcon({
    required this.row,
    required this.field,
    required this.kind,
    this.size = 25,
  });

  final Map<String, dynamic> row;
  final String field;
  final String kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    Object? raw = row[field];
    if (raw is List) {
      raw = raw.isEmpty ? null : raw.first;
    }
    final item = _readMap(raw);
    final id = _readString(item['id'] ?? item['skill_id'] ?? item['equip_id']);
    final name = _readString(
      item['name'],
      fallback: kind == 'equip' ? 'Equipment' : 'Summoner skill',
    );
    final url = id.isEmpty
        ? ''
        : 'https://hokhelper.com/static/game/$kind/$id.png';
    return Tooltip(
      message: name,
      child: AppImage(
        url: url,
        width: size,
        height: size,
        borderRadius: 6,
        semanticLabel: name,
      ),
    );
  }
}

class _HomeFixedTableIdentity extends StatelessWidget {
  const _HomeFixedTableIdentity({required this.row, required this.column});

  final Map<String, dynamic> row;
  final _HomeTableColumn column;

  @override
  Widget build(BuildContext context) {
    final isPlayer = column.id == 'player_name' || column.type == 'player';
    if (!isPlayer) {
      return _HomeHeroAvatarCluster(
        row: row,
        heroName: _homeTableValue(row, column),
      );
    }

    final player = _readMap(row['player']);
    final playerId = _readString(row['player_id'] ?? player['id']);
    final playerName = _homeTableValue(row, column);
    final avatarUrl = _readString(row['avatar_url'] ?? player['avatar_url']);
    final region = row['region'] ?? player['region'];
    return SizedBox(
      width: 50,
      height: 42,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 1,
            child: AppImage(
              key: ValueKey('home-player-avatar-$playerId'),
              url: avatarUrl,
              width: 34,
              height: 34,
              borderRadius: 999,
              semanticLabel: playerName,
            ),
          ),
          Positioned(
            left: 36,
            top: 12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppTheme.panel,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(1),
                child: Text(
                  _homeRegionFlag(region),
                  key: ValueKey('home-player-flag-$playerId'),
                  style: const TextStyle(fontSize: 10, height: 1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _homeRegionFlag(Object? rawRegion) {
  const isoByRegion = <int, String>{
    36: 'AU',
    76: 'BR',
    124: 'CA',
    156: 'CN',
    246: 'FI',
    250: 'FR',
    276: 'DE',
    344: 'HK',
    356: 'IN',
    360: 'ID',
    392: 'JP',
    410: 'KR',
    458: 'MY',
    484: 'MX',
    608: 'PH',
    642: 'RO',
    643: 'RU',
    702: 'SG',
    764: 'TH',
    784: 'AE',
    826: 'GB',
    840: 'US',
  };
  final region = int.tryParse(rawRegion?.toString() ?? '');
  final iso = region == null ? null : isoByRegion[region];
  if (iso == null) {
    return '🌐';
  }
  return String.fromCharCodes([
    0x1F1E6 + iso.codeUnitAt(0) - 0x41,
    0x1F1E6 + iso.codeUnitAt(1) - 0x41,
  ]);
}

class _HomeHeroAvatarCluster extends StatelessWidget {
  const _HomeHeroAvatarCluster({required this.row, required this.heroName});

  final Map<String, dynamic> row;
  final String heroName;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 42,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 7,
            top: 0,
            child: _HomeHeroAvatar(
              heroId: _readMap(row['hero'])['id'] ?? row['id'],
              name: heroName,
            ),
          ),
          Positioned(
            left: 0,
            bottom: 0,
            child: _HomeDataIcon(
              row: row,
              field: 'best_skill',
              kind: 'summoner_skill',
              size: 20,
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: _HomeDataIcon(
              row: row,
              field: 'best_equip',
              kind: 'equip',
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

String _homeHeroAvatarUrl(Map<String, dynamic> row) {
  final hero = _readMap(row['hero']);
  final explicit = _readString(
    hero['avatar_url'] ??
        hero['avatar_url_medium'] ??
        hero['avatarUrl'] ??
        row['avatar_url'] ??
        row['hero_avatar_url'],
  );
  if (explicit.isNotEmpty) {
    return explicit;
  }
  final heroId = _readString(hero['id'] ?? row['id']);
  if (heroId.isEmpty) {
    return '';
  }
  return 'https://hokhelper.com/static/game/hero/$heroId.png';
}

class _HomeHeroAvatar extends StatelessWidget {
  const _HomeHeroAvatar({
    required this.heroId,
    required this.name,
    this.size = 34,
  });

  final Object? heroId;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final id = _readString(heroId);
    return Tooltip(
      message: name,
      child: AppImage(
        key: ValueKey('home-hero-avatar-$id'),
        url: id.isEmpty ? '' : 'https://hokhelper.com/static/game/hero/$id.png',
        width: size,
        height: size,
        borderRadius: 999,
        semanticLabel: name,
      ),
    );
  }
}

List<_HomeTableColumn> _homeTableColumns(
  Object? rawColumns,
  List<Map<String, dynamic>> rows,
) {
  final columns = <_HomeTableColumn>[];
  if (rawColumns is List) {
    for (final value in rawColumns) {
      if (value is! Map) continue;
      final id = _readString(value['id']);
      if (id.isEmpty) continue;
      columns.add(
        _HomeTableColumn(
          id: id,
          label: _readString(value['label'], fallback: id),
          type: _readString(value['type']),
        ),
      );
    }
  }
  if (columns.isNotEmpty) {
    return columns;
  }
  return [
    const _HomeTableColumn(id: 'hero', label: 'Hero', type: 'hero'),
    if (rows.any((row) => row.containsKey('win_rate')))
      const _HomeTableColumn(
        id: 'win_rate',
        label: 'Win Rate',
        type: 'percent',
      ),
  ];
}

String _homeTableValue(Map<String, dynamic> row, _HomeTableColumn column) {
  Object? value = row[column.id];
  if (column.id == 'hero' || column.type == 'hero') {
    final hero = _readMap(value);
    value = hero['name'] ?? hero['hero_name'] ?? row['name'];
  } else if (column.id == 'player_name' || column.type == 'player') {
    final player = _readMap(row['player']);
    value = value ?? player['name'] ?? player['player_name'];
  }
  if (value == null || value.toString().trim().isEmpty) {
    return '-';
  }
  if (column.type == 'percent' || column.id.endsWith('_rate')) {
    final number = double.tryParse(value.toString());
    if (number != null) {
      final percent = number <= 1 ? number * 100 : number;
      return '${percent.toStringAsFixed(1)}%';
    }
  }
  if (value is double) {
    return value.toStringAsFixed(1);
  }
  if (value is List) {
    return value.join(', ');
  }
  return value.toString();
}

class _HomeTierPreviewSection extends StatelessWidget {
  const _HomeTierPreviewSection({
    required this.icon,
    required this.title,
    required this.route,
    required this.groups,
  });

  final IconData icon;
  final String title;
  final String route;
  final List<Map<String, dynamic>> groups;

  @override
  Widget build(BuildContext context) {
    return _HomeDataSection(
      icon: icon,
      title: title,
      route: route,
      child: Column(
        children: [
          if (groups.isEmpty)
            const _HomeEmptyPanelMessage()
          else
            for (final group in groups)
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(
                        _readString(group['tier'], fallback: 'Tier'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.muted,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 5,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _homeTierColor(
                          _readString(group['tier'], fallback: 'Tier'),
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: [
                          for (final hero in _readList(group['heroes']))
                            _HomeHeroAvatar(
                              heroId: hero['hero_id'] ?? hero['id'],
                              name: _readString(hero['name'], fallback: 'Hero'),
                              size: 24,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _HomeCommunitySection extends StatelessWidget {
  const _HomeCommunitySection({
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
    return _HomeDataSection(
      icon: icon,
      title: title,
      route: route,
      child: Column(
        children: [
          if (rows.isEmpty)
            const _HomeEmptyPanelMessage()
          else
            for (final row in rows)
              _HomeInfoListRow(
                title: row.title,
                detail: row.detail,
                route: row.route,
                suffix: 'Hot',
              ),
        ],
      ),
    );
  }
}

class _HomePatchNotesSection extends StatelessWidget {
  const _HomePatchNotesSection({
    required this.icon,
    required this.title,
    required this.route,
    required this.notes,
    required this.fallbackHeroes,
  });

  final IconData icon;
  final String title;
  final String route;
  final List<Map<String, dynamic>> notes;
  final List<Map<String, dynamic>> fallbackHeroes;

  @override
  Widget build(BuildContext context) {
    return _HomeDataSection(
      icon: icon,
      title: title,
      route: route,
      child: Column(
        children: [
          if (notes.isEmpty)
            const _HomeEmptyPanelMessage()
          else
            for (final note in notes)
              _HomePatchNoteRow(note: note, fallbackHeroes: fallbackHeroes),
        ],
      ),
    );
  }
}

class _HomePatchNoteRow extends StatelessWidget {
  const _HomePatchNoteRow({required this.note, required this.fallbackHeroes});

  final Map<String, dynamic> note;
  final List<Map<String, dynamic>> fallbackHeroes;

  @override
  Widget build(BuildContext context) {
    final rawChanges =
        note['hero_changes'] ?? note['changes'] ?? note['heroes'];
    final changes = _readList(rawChanges).isNotEmpty
        ? _readList(rawChanges)
        : [
            for (final hero in fallbackHeroes)
              {
                'hero_id': hero['hero_id'] ?? hero['id'],
                'name': hero['name'],
                'direction': _homeChangeDirection(hero['win_rate']),
              },
          ];
    final route =
        _communityPostRoute(note['post_id']) ?? _patchNoteRoute(note['id']);
    final child = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _readString(note['title'], fallback: 'Patch note'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                if (changes.isNotEmpty)
                  Wrap(
                    spacing: 7,
                    runSpacing: 6,
                    children: [
                      for (final change in changes.take(6))
                        _HomePatchChangeIcon(change: change),
                    ],
                  )
                else
                  Text(
                    _readString(note['content_preview']),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.article_outlined, color: AppTheme.gold, size: 18),
        ],
      ),
    );
    if (route == null) return child;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => context.go(route),
      child: child,
    );
  }
}

class _HomePatchChangeIcon extends StatelessWidget {
  const _HomePatchChangeIcon({required this.change});

  final Map<String, dynamic> change;

  @override
  Widget build(BuildContext context) {
    final name = _readString(
      change['name'] ?? change['hero_name'],
      fallback: 'Hero',
    );
    final heroId = change['hero_id'] ?? change['id'];
    final isUp =
        _homeChangeDirection(change['direction'] ?? change['trend']) == 'up';
    return Tooltip(
      message: name,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _HomeHeroAvatar(heroId: heroId, name: name, size: 24),
          const SizedBox(width: 2),
          Icon(
            isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            color: isUp ? AppTheme.success : AppTheme.error,
            size: 16,
          ),
        ],
      ),
    );
  }
}

String _homeChangeDirection(Object? value) {
  if (value is num) {
    return value < 0 ? 'down' : 'up';
  }
  final text = value?.toString().toLowerCase() ?? '';
  return text.contains('down') ||
          text.contains('nerf') ||
          text.contains('decrease') ||
          text.contains('buff_down')
      ? 'down'
      : 'up';
}

class _HomeInfoListRow extends StatelessWidget {
  const _HomeInfoListRow({
    required this.title,
    required this.detail,
    required this.suffix,
    this.route,
  });

  final String title;
  final String detail;
  final String suffix;
  final String? route;

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (detail.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            suffix,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.gold,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
    if (route == null) return child;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => context.go(route!),
      child: child,
    );
  }
}

class _HomeEmptyPanelMessage extends StatelessWidget {
  const _HomeEmptyPanelMessage();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          'No data yet',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
        ),
      ),
    );
  }
}

Color _homeTierColor(String tier) {
  return switch (tier.toUpperCase()) {
    'T0' || 'S' => const Color(0xFFE53935),
    'T1' || 'A' => const Color(0xFFFF7A1A),
    'T2' || 'B' => const Color(0xFFF2BE0A),
    'T3' || 'C' => const Color(0xFF23C76A),
    _ => const Color(0xFF72809A),
  };
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

// ignore: unused_element
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

// ignore: unused_element
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

// ignore: unused_element
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

String _readHeroRole(Map<String, dynamic> row) {
  final hero = _readMap(row['hero']);
  return _readString(
    hero['main_job'] ??
        hero['role'] ??
        hero['lane'] ??
        row['main_job'] ??
        row['role'] ??
        row['lane'],
  );
}

String _readPatchVersion(Map<String, dynamic> row) {
  final version = _readString(row['version'] ?? row['patch_version']);
  return version.isEmpty ? '' : 'v$version';
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

// ignore: unused_element
String _readTierHeroNames(Map<String, dynamic> row) {
  final names = [
    for (final hero in _readList(row['heroes']).take(4))
      _readString(hero['name'] ?? hero['hero_name']),
  ].where((name) => name.isNotEmpty).join(', ');
  return names;
}
