import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../settings/presentation/settings_controller.dart';
import '../data/content_repository.dart';
import '../domain/content_item_summary.dart';

final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  return ContentRepository(apiClient: ref.watch(apiClientProvider));
});

final skinsProvider = FutureProvider<List<ContentItemSummary>>((ref) async {
  final settings = await ref.watch(appSettingsControllerProvider.future);
  return ref
      .watch(contentRepositoryProvider)
      .loadSkins(settings.region.regionId);
});

final cgsProvider = FutureProvider<List<ContentItemSummary>>((ref) async {
  final settings = await ref.watch(appSettingsControllerProvider.future);
  return ref.watch(contentRepositoryProvider).loadCgs(settings.region.regionId);
});

class ContentScreen extends ConsumerWidget {
  const ContentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skinsValue = ref.watch(skinsProvider);
    final cgsValue = ref.watch(cgsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(skinsProvider);
        ref.invalidate(cgsProvider);
        await Future.wait([
          ref.read(skinsProvider.future),
          ref.read(cgsProvider.future),
        ]);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const AppSectionHeader(title: 'Content'),
          const SizedBox(height: 12),
          Text(
            'Skins, videos, and official media foundations.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppTheme.muted),
          ),
          const SizedBox(height: 24),
          AppAsyncView<List<ContentItemSummary>>(
            value: skinsValue,
            retry: () => ref.invalidate(skinsProvider),
            data: (items) => _ContentRail(
              title: 'Skins',
              icon: Icons.collections_outlined,
              items: items,
            ),
          ),
          const SizedBox(height: 20),
          AppAsyncView<List<ContentItemSummary>>(
            value: cgsValue,
            retry: () => ref.invalidate(cgsProvider),
            data: (items) => _ContentRail(
              title: 'CGs',
              icon: Icons.movie_creation_outlined,
              items: items,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentRail extends StatelessWidget {
  const _ContentRail({
    required this.title,
    required this.icon,
    required this.items,
  });

  final String title;
  final IconData icon;
  final List<ContentItemSummary> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return AppEmptyState(
        icon: icon,
        title: 'No $title found',
        message: 'Pull to refresh or switch region in settings.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppTheme.gold),
            const SizedBox(width: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.text,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              items.length.toString(),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 222,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return _ContentCard(item: items[index]);
            },
          ),
        ),
      ],
    );
  }
}

class _ContentCard extends StatelessWidget {
  const _ContentCard({required this.item});

  final ContentItemSummary item;

  @override
  Widget build(BuildContext context) {
    final metric = item.kind == ContentKind.cg
        ? '${item.viewCount} views'
        : '${item.rating.toStringAsFixed(1)} · ${item.ratingCount} ratings';

    return SizedBox(
      width: 152,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.panel,
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppImage(
                url: item.imageUrl,
                height: 112,
                width: double.infinity,
                borderRadius: 12,
                semanticLabel: item.title,
              ),
              const SizedBox(height: 10),
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.heroName.isEmpty ? item.subtitle : item.heroName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(
                    item.kind == ContentKind.cg
                        ? Icons.visibility_outlined
                        : Icons.star_border_rounded,
                    size: 15,
                    color: AppTheme.gold,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      metric,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
