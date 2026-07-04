import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../settings/presentation/settings_controller.dart';
import '../data/builds_repository.dart';
import '../domain/build_scheme_summary.dart';

final buildsRepositoryProvider = Provider<BuildsRepository>((ref) {
  return BuildsRepository(apiClient: ref.watch(apiClientProvider));
});

final publicBuildSchemesProvider = FutureProvider<List<BuildSchemeSummary>>((
  ref,
) async {
  final settings = await ref.watch(appSettingsControllerProvider.future);
  return ref
      .watch(buildsRepositoryProvider)
      .loadPublicSchemes(settings.region.regionId);
});

class BuildExplorerScreen extends ConsumerWidget {
  const BuildExplorerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schemesValue = ref.watch(publicBuildSchemesProvider);

    return AppAsyncView<List<BuildSchemeSummary>>(
      value: schemesValue,
      retry: () => ref.invalidate(publicBuildSchemesProvider),
      data: (schemes) {
        return RefreshIndicator(
          onRefresh: () => ref.refresh(publicBuildSchemesProvider.future),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppSectionHeader(title: 'Build Explorer'),
                      const SizedBox(height: 8),
                      Text(
                        'Browse public hero builds from the community.',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
                      ),
                    ],
                  ),
                ),
              ),
              if (schemes.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppEmptyState(
                    icon: Icons.construction_outlined,
                    title: 'No public builds',
                    message: 'Pull to refresh or switch region in settings.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  sliver: SliverList.separated(
                    itemCount: schemes.length,
                    itemBuilder: (context, index) {
                      return BuildSchemeCard(scheme: schemes[index]);
                    },
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class BuildSchemeCard extends StatelessWidget {
  const BuildSchemeCard({required this.scheme, super.key});

  final BuildSchemeSummary scheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final heroName = scheme.heroName.isEmpty ? 'Any hero' : scheme.heroName;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panel,
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        scheme.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppTheme.text,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$heroName · ${scheme.authorName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _PublicBadge(isPublic: scheme.isPublic),
              ],
            ),
            const SizedBox(height: 14),
            _EquipmentStrip(icons: scheme.equipmentIcons),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetricChip(
                  icon: Icons.thumb_up_outlined,
                  value: scheme.likeCount,
                ),
                _MetricChip(
                  icon: Icons.star_border_rounded,
                  value: scheme.favoriteCount,
                ),
                _MetricChip(
                  icon: Icons.copy_all_outlined,
                  value: scheme.cloneCount,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EquipmentStrip extends StatelessWidget {
  const _EquipmentStrip({required this.icons});

  final List<String> icons;

  @override
  Widget build(BuildContext context) {
    final visibleIcons = icons.take(6).toList(growable: false);
    if (visibleIcons.isEmpty) {
      return Text(
        'No equipment preview',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
      );
    }

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: visibleIcons.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return AppImage(
            url: visibleIcons[index],
            width: 42,
            height: 42,
            borderRadius: 10,
            semanticLabel: 'Build equipment ${index + 1}',
          );
        },
      ),
    );
  }
}

class _PublicBadge extends StatelessWidget {
  const _PublicBadge({required this.isPublic});

  final bool isPublic;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.gold.withValues(alpha: isPublic ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppTheme.gold.withValues(alpha: isPublic ? 0.35 : 0.18),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          isPublic ? 'Public' : 'Private',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: isPublic ? AppTheme.gold : AppTheme.muted,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.icon, required this.value});

  final IconData icon;
  final int value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panelAlt,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppTheme.muted),
            const SizedBox(width: 5),
            Text(
              value.toString(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppTheme.text,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
