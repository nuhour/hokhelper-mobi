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
import '../data/content_repository.dart';
import '../domain/content_item_summary.dart';
import '../domain/patch_note_summary.dart';

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

final patchNotesRegionProvider = FutureProvider<int>((ref) async {
  final settings = await ref.watch(appSettingsControllerProvider.future);
  return settings.region.regionId;
});

final patchNotesProvider = FutureProvider<List<PatchNoteSummary>>((ref) async {
  final regionId = await ref.watch(patchNotesRegionProvider.future);
  return ref.watch(contentRepositoryProvider).loadPatchNotes(regionId);
});

class ContentScreen extends ConsumerWidget {
  const ContentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skinsValue = ref.watch(skinsProvider);
    final cgsValue = ref.watch(cgsProvider);
    final patchNotesValue = ref.watch(patchNotesProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(skinsProvider);
        ref.invalidate(cgsProvider);
        ref.invalidate(patchNotesProvider);
        await Future.wait([
          ref.read(skinsProvider.future),
          ref.read(cgsProvider.future),
          ref.read(patchNotesProvider.future),
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
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: context.hokTheme.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: 24),
          _CommunityEntryCard(onTap: () => context.go('/content/community')),
          const SizedBox(height: 12),
          _ContentActionCard(
            icon: Icons.collections_outlined,
            title: 'Skin Gallery',
            subtitle: 'Browse hero skins, posters, ratings, and splash art',
            onTap: () => context.go('/content/skins'),
          ),
          const SizedBox(height: 12),
          _ContentActionCard(
            icon: Icons.movie_creation_outlined,
            title: 'CG Gallery',
            subtitle: 'Watch cinematics, trailers, videos, and comments',
            onTap: () => context.go('/content/cgs'),
          ),
          const SizedBox(height: 12),
          _ContentActionCard(
            icon: Icons.event_available_outlined,
            title: 'Event Assistance',
            subtitle: 'Share event codes and teammate requests',
            onTap: () => context.go('/content/event-assistance'),
          ),
          const SizedBox(height: 12),
          _ContentActionCard(
            icon: Icons.newspaper_outlined,
            title: 'Patch Notes',
            subtitle: 'Version timeline and hero adjustments',
            onTap: () => context.go('/content/patch-notes'),
          ),
          const SizedBox(height: 12),
          _ContentActionCard(
            icon: Icons.info_outline,
            title: 'Info Center',
            subtitle: 'About, FAQ, privacy, terms, and partner links',
            onTap: () => context.go('/content/info'),
          ),
          const SizedBox(height: 20),
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
          const SizedBox(height: 20),
          AppAsyncView<List<PatchNoteSummary>>(
            value: patchNotesValue,
            retry: () => ref.invalidate(patchNotesProvider),
            data: (items) => _PatchNotesRail(items: items),
          ),
        ],
      ),
    );
  }
}

class _CommunityEntryCard extends StatelessWidget {
  const _CommunityEntryCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _ContentActionCard(
      icon: Icons.forum_outlined,
      title: 'Community Hub',
      subtitle: 'Hot posts, leaks, and community signals',
      onTap: onTap,
    );
  }
}

class _ContentActionCard extends StatelessWidget {
  const _ContentActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.hokTheme.surfaceSlate,
        border: Border.all(color: context.hokTheme.outlineSoft),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          onTap: onTap,
          leading: Icon(icon, color: AppTheme.gold),
          trailing: Icon(
            Icons.chevron_right,
            color: context.hokTheme.onSurfaceMuted,
          ),
          title: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.hokTheme.onSurfaceStrong,
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: context.hokTheme.onSurfaceMuted),
          ),
        ),
      ),
    );
  }
}

class _PatchNotesRail extends StatelessWidget {
  const _PatchNotesRail({required this.items});

  final List<PatchNoteSummary> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const AppEmptyState(
        icon: Icons.newspaper_outlined,
        title: 'No Patch Notes found',
        message: 'Pull to refresh or switch region in settings.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.newspaper_outlined, color: AppTheme.gold),
            const SizedBox(width: 12),
            Text(
              'Patch Notes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: context.hokTheme.onSurfaceStrong,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              items.length.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.hokTheme.onSurfaceMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: items.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _PatchNoteCard(note: items[index]);
          },
        ),
      ],
    );
  }
}

class _PatchNoteCard extends StatelessWidget {
  const _PatchNoteCard({required this.note});

  final PatchNoteSummary note;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/content/patch-notes?note_id=${note.id}'),
        child: Ink(
          decoration: BoxDecoration(
            color: context.hokTheme.surfaceSlate,
            border: Border.all(color: context.hokTheme.outlineSoft),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    _VersionBadge(version: note.version),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            note.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: context.hokTheme.onSurfaceStrong,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'V${note.version} · ${note.date}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: context.hokTheme.onSurfaceMuted,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right,
                      color: context.hokTheme.onSurfaceMuted,
                      size: 20,
                    ),
                  ],
                ),
                if (note.preview.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    note.preview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.hokTheme.onSurfaceMuted,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _PatchMetaChip(
                      icon: Icons.tune_outlined,
                      label:
                          '${note.changeCount} hero ${note.changeCount == 1 ? 'change' : 'changes'}',
                    ),
                    if (note.tags.isNotEmpty)
                      _PatchMetaChip(
                        icon: Icons.sell_outlined,
                        label: note.tags.first,
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

class _VersionBadge extends StatelessWidget {
  const _VersionBadge({required this.version});

  final String version;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.gold.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SizedBox(
        width: 54,
        height: 54,
        child: Center(
          child: Text(
            version == '-' ? 'V' : 'V$version',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppTheme.gold,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _PatchMetaChip extends StatelessWidget {
  const _PatchMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.hokTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTheme.gold, size: 15),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: context.hokTheme.onSurfaceStrong,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
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
                color: context.hokTheme.onSurfaceStrong,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              items.length.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.hokTheme.onSurfaceMuted,
              ),
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
    final route = item.kind == ContentKind.cg
        ? '/cg/${item.id}'
        : '/skin-gallery/${item.id}';

    return SizedBox(
      width: 152,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.go(route),
          child: Ink(
            decoration: BoxDecoration(
              color: context.hokTheme.surfaceSlate,
              border: Border.all(color: context.hokTheme.outlineSoft),
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
                      color: context.hokTheme.onSurfaceStrong,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.heroName.isEmpty ? item.subtitle : item.heroName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.hokTheme.onSurfaceMuted,
                    ),
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
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: context.hokTheme.onSurfaceMuted,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
