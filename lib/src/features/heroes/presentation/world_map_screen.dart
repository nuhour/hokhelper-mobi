import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../settings/presentation/settings_controller.dart';
import '../domain/hero_summary.dart';
import '../domain/world_map_region.dart';
import 'hero_gallery_screen.dart';

final worldMapHeroesProvider = FutureProvider<List<HeroSummary>>((ref) async {
  final settings = await ref.watch(appSettingsControllerProvider.future);
  return ref
      .watch(heroesRepositoryProvider)
      .loadHeroes(settings.region.regionId);
});

class WorldMapScreen extends ConsumerStatefulWidget {
  const WorldMapScreen({this.initialHeroId, super.key});

  final String? initialHeroId;

  @override
  ConsumerState<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends ConsumerState<WorldMapScreen> {
  String? _openedInitialHeroId;

  @override
  void didUpdateWidget(covariant WorldMapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialHeroId != widget.initialHeroId) {
      _openedInitialHeroId = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final heroesValue = ref.watch(worldMapHeroesProvider);

    return Material(
      color: AppTheme.bg,
      child: AppAsyncView<List<HeroSummary>>(
        value: heroesValue,
        retry: () => ref.invalidate(worldMapHeroesProvider),
        data: (heroes) {
          final regions = attachWorldMapHeroes(heroes);
          _openInitialHeroRegion(regions);

          return RefreshIndicator(
            onRefresh: () => ref.refresh(worldMapHeroesProvider.future),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppSectionHeader(title: 'World Map'),
                        const SizedBox(height: 8),
                        Text(
                          'Browse the Honor of Kings world by domain records and representative heroes.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.muted),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  sliver: SliverList.separated(
                    itemCount: regions.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _WorldRegionCard(
                        region: regions[index],
                        onOpenDetail: (region) =>
                            _openRegionDetail(context, region),
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

  void _openInitialHeroRegion(List<WorldMapRegion> regions) {
    final heroId = widget.initialHeroId?.trim();
    if (heroId == null || heroId.isEmpty || _openedInitialHeroId == heroId) {
      return;
    }

    WorldMapRegion? focusedRegion;
    for (final region in regions) {
      final containsHero = region.representativeHeroes.any((hero) {
        return hero.heroId == heroId || hero.id == heroId;
      });
      if (containsHero) {
        focusedRegion = region;
        break;
      }
    }
    _openedInitialHeroId = heroId;

    if (focusedRegion == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _openRegionDetail(context, focusedRegion!);
    });
  }

  void _openRegionDetail(BuildContext context, WorldMapRegion region) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.panel,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: ListView(
              shrinkWrap: true,
              children: [
                Text(
                  'Domain Records',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppTheme.gold,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  region.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  region.description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
                ),
                const SizedBox(height: 20),
                Text(
                  'Representative Heroes',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                if (region.representativeHeroes.isEmpty)
                  const AppEmptyState(
                    icon: Icons.travel_explore_outlined,
                    title: 'No hero data',
                    message: 'Switch region or pull to refresh hero records.',
                  )
                else
                  ...region.representativeHeroes.map((hero) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _HeroDetailRow(hero: hero),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WorldRegionCard extends StatelessWidget {
  const _WorldRegionCard({required this.region, required this.onOpenDetail});

  final WorldMapRegion region;
  final ValueChanged<WorldMapRegion> onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: AppTheme.panel,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onOpenDetail(region),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 14,
                    height: 44,
                    decoration: BoxDecoration(
                      color: region.color,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          region.name,
                          style: textTheme.titleMedium?.copyWith(
                            color: AppTheme.text,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${region.representativeHeroes.length} representative heroes',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppTheme.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppTheme.muted),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                region.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
              ),
              if (region.representativeHeroes.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 58,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: region.representativeHeroes.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      return _HeroPreview(
                        hero: region.representativeHeroes[index],
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroPreview extends StatelessWidget {
  const _HeroPreview({required this.hero});

  final HeroSummary hero;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 118,
      child: Row(
        children: [
          AppImage(
            url: hero.avatar,
            aspectRatio: 1,
            width: 42,
            height: 42,
            borderRadius: 12,
            semanticLabel: '${hero.name} avatar',
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hero.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.text,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroDetailRow extends StatelessWidget {
  const _HeroDetailRow({required this.hero});

  final HeroSummary hero;

  @override
  Widget build(BuildContext context) {
    final detailRouteId = hero.detailRouteId;

    return Material(
      color: AppTheme.panelAlt,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: detailRouteId == null
            ? null
            : () {
                Navigator.of(context).pop();
                context.go('/heroes/$detailRouteId');
              },
        leading: AppImage(
          url: hero.avatar,
          aspectRatio: 1,
          width: 44,
          height: 44,
          borderRadius: 12,
          semanticLabel: '${hero.name} avatar',
        ),
        title: Text(hero.name),
        subtitle: Text(hero.title.isEmpty ? 'Hero ${hero.heroId}' : hero.title),
      ),
    );
  }
}
