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

class HeroGalleryScreen extends ConsumerWidget {
  const HeroGalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heroesValue = ref.watch(heroGalleryProvider);

    return AppAsyncView<List<HeroSummary>>(
      value: heroesValue,
      retry: () => ref.invalidate(heroGalleryProvider),
      data: (heroes) {
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
                      const AppSectionHeader(title: 'Heroes'),
                      const SizedBox(height: 8),
                      Text(
                        'Browse the international hero roster.',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
                      ),
                    ],
                  ),
                ),
              ),
              if (heroes.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppEmptyState(
                    icon: Icons.shield_outlined,
                    title: 'No heroes found',
                    message:
                        'Pull to refresh and try loading the roster again.',
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
                    itemCount: heroes.length,
                    itemBuilder: (context, index) {
                      return _HeroCard(hero: heroes[index]);
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
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
