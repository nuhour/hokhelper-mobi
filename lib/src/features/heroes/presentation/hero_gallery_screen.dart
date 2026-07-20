import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_rating_stars.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../settings/presentation/settings_controller.dart';
import '../data/heroes_repository.dart';
import '../domain/hero_summary.dart';

final heroesRepositoryProvider = Provider<HeroesRepository>((ref) {
  return HeroesRepository(apiClient: ref.watch(apiClientProvider));
});

final heroGalleryRegionProvider = FutureProvider<int>((ref) async {
  final settings = await ref.watch(appSettingsControllerProvider.future);
  return settings.region.regionId;
});

final heroGalleryProvider = FutureProvider<List<HeroSummary>>((ref) async {
  final regionId = await ref.watch(heroGalleryRegionProvider.future);
  return ref.watch(heroesRepositoryProvider).loadHeroes(regionId);
});

final heroGalleryQueryProvider =
    FutureProvider.family<List<HeroSummary>, _HeroGalleryQuery>((ref, query) {
      if (query.isDefault) {
        return ref.watch(heroGalleryProvider.future);
      }
      return ref.watch(heroGalleryRegionProvider.future).then((regionId) {
        return ref
            .watch(heroesRepositoryProvider)
            .loadHeroes(
              regionId,
              sort: query.sort.apiValue,
              order: query.sort.order,
              search: query.search,
              lanePosition: query.lanePosition,
            );
      });
    });

class _HeroGalleryQuery {
  const _HeroGalleryQuery({
    this.sort = _HeroSort.release,
    this.search = '',
    this.lanePosition,
  });

  final _HeroSort sort;
  final String search;
  final int? lanePosition;

  bool get isDefault =>
      sort == _HeroSort.release &&
      search.trim().isEmpty &&
      lanePosition == null;

  @override
  bool operator ==(Object other) {
    return other is _HeroGalleryQuery &&
        other.sort == sort &&
        other.search == search &&
        other.lanePosition == lanePosition;
  }

  @override
  int get hashCode => Object.hash(sort, search, lanePosition);
}

class HeroGalleryScreen extends ConsumerStatefulWidget {
  const HeroGalleryScreen({
    this.initialSearchQuery,
    this.onHeroSelected,
    super.key,
  });

  final String? initialSearchQuery;
  final ValueChanged<String>? onHeroSelected;

  @override
  ConsumerState<HeroGalleryScreen> createState() => _HeroGalleryScreenState();
}

class _HeroGalleryScreenState extends ConsumerState<HeroGalleryScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  _HeroSort _sort = _HeroSort.release;
  int? _lanePosition;
  List<HeroSummary>? _previousHeroes;

  @override
  void initState() {
    super.initState();
    final initialQuery = widget.initialSearchQuery?.trim() ?? '';
    if (initialQuery.isNotEmpty) {
      _query = initialQuery;
      _searchController.text = initialQuery;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final galleryQuery = _HeroGalleryQuery(
      sort: _sort,
      search: _query,
      lanePosition: _lanePosition,
    );
    final heroesValue = ref.watch(heroGalleryQueryProvider(galleryQuery));
    final loadedHeroes = heroesValue.valueOrNull;
    if (loadedHeroes != null) {
      _previousHeroes = loadedHeroes;
    }

    return Material(
      color: context.hokTheme.backgroundDeep,
      child: AppAsyncView<List<HeroSummary>>(
        value: heroesValue,
        retry: () => ref.invalidate(heroGalleryQueryProvider(galleryQuery)),
        previousData: _previousHeroes,
        loadingStyle: AppAsyncLoadingStyle.gallery,
        data: (heroes) {
          final visibleHeroes = _filterHeroes(heroes);
          return RefreshIndicator(
            onRefresh: () =>
                ref.refresh(heroGalleryQueryProvider(galleryQuery).future),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Expanded(
                              child: AppSectionHeader(title: 'Heroes'),
                            ),
                            IconButton.filledTonal(
                              tooltip: 'World Map',
                              onPressed: () => context.push('/world-map'),
                              icon: const Icon(Icons.travel_explore_outlined),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filledTonal(
                              tooltip: 'Hero Relationships',
                              onPressed: () => context.push('/relationships'),
                              icon: const Icon(Icons.hub_outlined),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _searchController,
                          onChanged: (value) => setState(() => _query = value),
                          style: TextStyle(
                            color: context.hokTheme.onSurfaceStrong,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search hero or title',
                            prefixIcon: Icon(
                              Icons.search,
                              color: context.hokTheme.onSurfaceMuted,
                            ),
                            suffixIcon: _query.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Clear',
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _query = '');
                                    },
                                    icon: Icon(
                                      Icons.close,
                                      color: context.hokTheme.onSurfaceMuted,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SegmentedButton<_HeroSort>(
                          segments: const [
                            ButtonSegment(
                              value: _HeroSort.release,
                              label: Text('Release'),
                              icon: Icon(Icons.schedule),
                            ),
                            ButtonSegment(
                              value: _HeroSort.name,
                              label: Text('Name'),
                              icon: Icon(Icons.sort_by_alpha),
                            ),
                            ButtonSegment(
                              value: _HeroSort.rating,
                              label: Text('Rating'),
                              icon: Icon(Icons.star_border),
                            ),
                          ],
                          selected: {_sort},
                          onSelectionChanged: (value) =>
                              setState(() => _sort = value.first),
                        ),
                        const SizedBox(height: 10),
                        _LaneFilterBar(
                          lanePosition: _lanePosition,
                          onChanged: (value) =>
                              setState(() => _lanePosition = value),
                        ),
                      ],
                    ),
                  ),
                ),
                if (visibleHeroes.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppEmptyState(
                      icon: Icons.shield_outlined,
                      title: _query.trim().isEmpty
                          ? 'No heroes found'
                          : 'No matching heroes',
                      message: _query.trim().isEmpty
                          ? 'Pull to refresh and try loading the roster again.'
                          : 'Try another hero name or title.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    sliver: SliverGrid.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.82,
                          ),
                      itemCount: visibleHeroes.length,
                      itemBuilder: (context, index) {
                        return _HeroCard(
                          hero: visibleHeroes[index],
                          onSelected: widget.onHeroSelected,
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<HeroSummary> _filterHeroes(List<HeroSummary> heroes) {
    final normalizedQuery = _query.trim().toLowerCase();
    return heroes
        .where((hero) {
          if (_lanePosition != null && hero.position != _lanePosition) {
            return false;
          }
          if (normalizedQuery.isEmpty) {
            return true;
          }
          return hero.name.toLowerCase().contains(normalizedQuery) ||
              hero.title.toLowerCase().contains(normalizedQuery) ||
              hero.heroId.toLowerCase().contains(normalizedQuery) ||
              hero.id.toLowerCase().contains(normalizedQuery);
        })
        .toList(growable: false);
  }
}

class _LaneFilterBar extends StatelessWidget {
  const _LaneFilterBar({required this.lanePosition, required this.onChanged});

  final int? lanePosition;
  final ValueChanged<int?> onChanged;

  static const _options = [
    _LaneFilterOption(label: 'All lanes', assetName: null),
    _LaneFilterOption(label: 'Clash', assetName: 'clash', value: 0),
    _LaneFilterOption(label: 'Mid', assetName: 'mid', value: 1),
    _LaneFilterOption(label: 'Farm', assetName: 'adc', value: 2),
    _LaneFilterOption(label: 'Jungle', assetName: 'jungle', value: 3),
    _LaneFilterOption(label: 'Support', assetName: 'support', value: 4),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in _options)
          Tooltip(
            message: option.label,
            child: Semantics(
              button: true,
              selected: lanePosition == option.value,
              label: '${option.label} lane',
              child: InkWell(
                key: ValueKey('hero-lane-${option.value ?? 'all'}'),
                onTap: () => onChanged(option.value),
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: lanePosition == option.value
                        ? AppTheme.gold
                        : context.hokTheme.surfaceSlate,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: lanePosition == option.value
                          ? AppTheme.gold
                          : context.hokTheme.outlineSoft,
                    ),
                  ),
                  child: option.assetName == null
                      ? const Icon(Icons.grid_view_rounded, size: 18)
                      : Image.asset(
                          'assets/lane-icons/${option.assetName}.png',
                          width: 20,
                          height: 20,
                        ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _LaneFilterOption {
  const _LaneFilterOption({
    required this.label,
    required this.assetName,
    this.value,
  });

  final String label;
  final String? assetName;
  final int? value;
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.hero, this.onSelected});

  final HeroSummary hero;
  final ValueChanged<String>? onSelected;

  @override
  Widget build(BuildContext context) {
    final detailRouteId = hero.detailRouteId;
    final tier = hero.tier.isEmpty ? '--' : hero.tier.toUpperCase();
    final roleLabels = [
      hero.mainJob,
      hero.minorJob,
    ].where((value) => value.isNotEmpty).join(' / ');

    return Material(
      key: ValueKey('hero-card-${hero.id}'),
      color: context.hokTheme.surfaceSlate,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: detailRouteId == null
            ? null
            : () => _openDetail(context, detailRouteId),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AppImage(
              url: hero.avatar,
              width: double.infinity,
              height: double.infinity,
              borderRadius: 0,
              semanticLabel: '${hero.name} hero portrait',
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x33000000),
                    Colors.transparent,
                    Color(0xD9000000),
                  ],
                  stops: [0, 0.36, 1],
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: _HeroCardCorner(
                child: _HeroLaneBadge(position: hero.position),
              ),
            ),
            Positioned(top: 8, right: 8, child: _HeroTierBadge(tier: tier)),
            Positioned(
              left: 10,
              right: 10,
              bottom: 9,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hero.name.isEmpty ? 'Hero #${hero.id}' : hero.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                shadows: const [
                                  Shadow(color: Colors.black, blurRadius: 6),
                                ],
                              ),
                        ),
                        if (roleLabels.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            roleLabels,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w700,
                                  shadows: const [
                                    Shadow(color: Colors.black, blurRadius: 6),
                                  ],
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  AppRatingStars(
                    rating: hero.rating,
                    ratingCount: hero.ratingCount,
                    size: 12,
                    countLabel: '',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, String detailRouteId) {
    if (onSelected != null) {
      onSelected!(detailRouteId);
      return;
    }
    final router = GoRouter.of(context);
    final currentUri = router.routeInformationProvider.value.uri;
    final nextUri = currentUri.replace(path: '/heroes/$detailRouteId');
    router.go(nextUri.toString());
  }
}

class _HeroCardCorner extends StatelessWidget {
  const _HeroCardCorner({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Padding(padding: const EdgeInsets.all(3), child: child),
    );
  }
}

class _HeroLaneBadge extends StatelessWidget {
  const _HeroLaneBadge({required this.position});

  final int? position;

  @override
  Widget build(BuildContext context) {
    final assetName = switch (position) {
      0 => 'clash',
      1 => 'mid',
      2 => 'adc',
      3 => 'jungle',
      4 => 'support',
      _ => null,
    };
    return Tooltip(
      message: _laneLabel(position),
      child: SizedBox.square(
        dimension: 18,
        child: assetName == null
            ? Icon(
                Icons.grid_view_rounded,
                size: 16,
                color: context.hokTheme.onSurfaceMuted,
              )
            : Image.asset('assets/lane-icons/$assetName.png'),
      ),
    );
  }
}

class _HeroTierBadge extends StatelessWidget {
  const _HeroTierBadge({required this.tier});

  final String tier;

  @override
  Widget build(BuildContext context) {
    final color = switch (tier) {
      'T0' => const Color(0xFFEF4444),
      'T1' => const Color(0xFFF97316),
      'T2' => const Color(0xFFEAB308),
      'T3' => const Color(0xFF22C55E),
      _ => context.hokTheme.onSurfaceMuted,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.white.withValues(alpha: 0.82)),
        boxShadow: const [BoxShadow(color: Colors.black, blurRadius: 6)],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        child: Text(
          tier,
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

String _laneLabel(int? position) {
  return switch (position) {
    0 => 'Clash lane',
    1 => 'Mid lane',
    2 => 'Farm lane',
    3 => 'Jungle',
    4 => 'Support',
    _ => 'All lanes',
  };
}

enum _HeroSort {
  release('created_at', 'desc'),
  name('name', 'asc'),
  rating('rating', 'asc');

  const _HeroSort(this.apiValue, this.order);

  final String apiValue;
  final String order;
}
