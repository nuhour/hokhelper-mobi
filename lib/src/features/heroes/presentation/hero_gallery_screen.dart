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

final heroGalleryProvider = FutureProvider<List<HeroSummary>>((ref) async {
  final settings = await ref.watch(appSettingsControllerProvider.future);
  return ref
      .watch(heroesRepositoryProvider)
      .loadHeroes(settings.region.regionId);
});

class HeroGalleryScreen extends ConsumerStatefulWidget {
  const HeroGalleryScreen({this.initialSearchQuery, super.key});

  final String? initialSearchQuery;

  @override
  ConsumerState<HeroGalleryScreen> createState() => _HeroGalleryScreenState();
}

class _HeroGalleryScreenState extends ConsumerState<HeroGalleryScreen> {
  final _searchController = TextEditingController();
  String _query = '';

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
    final heroesValue = ref.watch(heroGalleryProvider);

    return Material(
      color: AppTheme.bg,
      child: AppAsyncView<List<HeroSummary>>(
        value: heroesValue,
        retry: () => ref.invalidate(heroGalleryProvider),
        data: (heroes) {
          final visibleHeroes = _filterHeroes(heroes);
          return RefreshIndicator(
            onRefresh: () => ref.refresh(heroGalleryProvider.future),
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
    if (normalizedQuery.isEmpty) {
      return heroes;
    }
    return heroes
        .where(
          (hero) =>
              hero.name.toLowerCase().contains(normalizedQuery) ||
              hero.title.toLowerCase().contains(normalizedQuery) ||
              hero.heroId.toLowerCase().contains(normalizedQuery) ||
              hero.id.toLowerCase().contains(normalizedQuery),
        )
        .toList(growable: false);
  }
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
        onTap: detailRouteId == null
            ? null
            : () => context.go('/heroes/$detailRouteId'),
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
}
