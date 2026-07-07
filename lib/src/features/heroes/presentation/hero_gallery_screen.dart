import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_image.dart';
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
              minRating: query.minRating,
            );
      });
    });

class _HeroGalleryQuery {
  const _HeroGalleryQuery({
    this.sort = _HeroSort.release,
    this.search = '',
    this.lanePosition,
    this.minRating = 0,
  });

  final _HeroSort sort;
  final String search;
  final int? lanePosition;
  final double minRating;

  bool get isDefault =>
      sort == _HeroSort.release &&
      search.trim().isEmpty &&
      lanePosition == null &&
      minRating <= 0;

  @override
  bool operator ==(Object other) {
    return other is _HeroGalleryQuery &&
        other.sort == sort &&
        other.search == search &&
        other.lanePosition == lanePosition &&
        other.minRating == minRating;
  }

  @override
  int get hashCode => Object.hash(sort, search, lanePosition, minRating);
}

class HeroGalleryScreen extends ConsumerStatefulWidget {
  const HeroGalleryScreen({this.initialSearchQuery, super.key});

  final String? initialSearchQuery;

  @override
  ConsumerState<HeroGalleryScreen> createState() => _HeroGalleryScreenState();
}

class _HeroGalleryScreenState extends ConsumerState<HeroGalleryScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  _HeroSort _sort = _HeroSort.release;
  int? _lanePosition;
  double _minRating = 0;

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
      minRating: _minRating,
    );
    final heroesValue = ref.watch(heroGalleryQueryProvider(galleryQuery));

    return Material(
      color: AppTheme.bg,
      child: AppAsyncView<List<HeroSummary>>(
        value: heroesValue,
        retry: () => ref.invalidate(heroGalleryQueryProvider(galleryQuery)),
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
                              tooltip: 'Hero Trends',
                              onPressed: () => context.go('/trends'),
                              icon: const Icon(Icons.trending_up_outlined),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filledTonal(
                              tooltip: 'World Map',
                              onPressed: () => context.go('/world-map'),
                              icon: const Icon(Icons.travel_explore_outlined),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filledTonal(
                              tooltip: 'Hero Relationships',
                              onPressed: () => context.go('/relationships'),
                              icon: const Icon(Icons.hub_outlined),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Browse the international hero roster.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.muted),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => context.go('/trends'),
                              icon: const Icon(Icons.trending_up_outlined),
                              label: const Text('Hero Trends'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => context.go('/world-map'),
                              icon: const Icon(Icons.travel_explore_outlined),
                              label: const Text('World Map'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => context.go('/relationships'),
                              icon: const Icon(Icons.hub_outlined),
                              label: const Text('Hero Relationships'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _searchController,
                          onChanged: (value) => setState(() => _query = value),
                          style: const TextStyle(color: AppTheme.text),
                          decoration: InputDecoration(
                            hintText: 'Search hero or title',
                            prefixIcon: const Icon(
                              Icons.search,
                              color: AppTheme.muted,
                            ),
                            suffixIcon: _query.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Clear',
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _query = '');
                                    },
                                    icon: const Icon(
                                      Icons.close,
                                      color: AppTheme.muted,
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
                        _RatingFilterBar(
                          minRating: _minRating,
                          onChanged: (value) =>
                              setState(() => _minRating = value),
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
                            crossAxisCount: 3,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.68,
                          ),
                      itemCount: visibleHeroes.length,
                      itemBuilder: (context, index) {
                        return _HeroCard(hero: visibleHeroes[index]);
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
    _LaneFilterOption(label: 'All lanes'),
    _LaneFilterOption(label: 'Clash', value: 0),
    _LaneFilterOption(label: 'Mid', value: 1),
    _LaneFilterOption(label: 'Farm', value: 2),
    _LaneFilterOption(label: 'Jungle', value: 3),
    _LaneFilterOption(label: 'Support', value: 4),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in _options)
          ChoiceChip(
            label: Text(option.label),
            selected: lanePosition == option.value,
            onSelected: (_) => onChanged(option.value),
            avatar: option.value == null
                ? const Icon(Icons.route_outlined, size: 16)
                : const Icon(Icons.sports_martial_arts, size: 16),
            labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: lanePosition == option.value ? AppTheme.bg : AppTheme.text,
              fontWeight: FontWeight.w800,
            ),
            selectedColor: AppTheme.gold,
            backgroundColor: AppTheme.panel,
            side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
      ],
    );
  }
}

class _RatingFilterBar extends StatelessWidget {
  const _RatingFilterBar({required this.minRating, required this.onChanged});

  final double minRating;
  final ValueChanged<double> onChanged;

  static const _options = [
    _RatingFilterOption(label: 'All scores'),
    _RatingFilterOption(label: '>3', value: 3),
    _RatingFilterOption(label: '>4', value: 4),
    _RatingFilterOption(label: '>4.5', value: 4.5),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in _options)
          ChoiceChip(
            label: Text(option.label),
            selected: minRating == option.value,
            onSelected: (_) => onChanged(option.value),
            avatar: const Icon(Icons.star_border, size: 16),
            labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: minRating == option.value ? AppTheme.bg : AppTheme.text,
              fontWeight: FontWeight.w800,
            ),
            selectedColor: AppTheme.gold,
            backgroundColor: AppTheme.panel,
            side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
      ],
    );
  }
}

class _RatingFilterOption {
  const _RatingFilterOption({required this.label, this.value = 0});

  final String label;
  final double value;
}

class _LaneFilterOption {
  const _LaneFilterOption({required this.label, this.value});

  final String label;
  final int? value;
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.hero});

  final HeroSummary hero;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final detailRouteId = hero.detailRouteId;

    return Material(
      color: AppTheme.panel,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: detailRouteId == null ? null : () => _openDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Flexible(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 88,
                      maxHeight: 88,
                    ),
                    child: AppImage(
                      url: hero.avatar,
                      aspectRatio: 1,
                      borderRadius: 12,
                      semanticLabel: '${hero.name} hero portrait',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                hero.name.isEmpty ? 'Hero #${hero.id}' : hero.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppTheme.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                hero.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(color: AppTheme.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetail(BuildContext context) {
    final detailRouteId = hero.detailRouteId;
    if (detailRouteId == null) {
      return;
    }
    final router = GoRouter.of(context);
    final currentUri = router.routeInformationProvider.value.uri;
    final nextUri = currentUri.replace(path: '/heroes/$detailRouteId');
    router.go(nextUri.toString());
  }
}

enum _HeroSort {
  release('created_at', 'desc'),
  name('name', 'asc'),
  rating('rating', 'asc');

  const _HeroSort(this.apiValue, this.order);

  final String apiValue;
  final String order;
}
