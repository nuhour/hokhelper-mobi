import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../settings/presentation/settings_controller.dart';
import '../domain/content_item_summary.dart';
import '../domain/skin_detail.dart';
import 'content_screen.dart';

final skinGalleryProvider = FutureProvider<List<ContentItemSummary>>((
  ref,
) async {
  final settings = await ref.watch(appSettingsControllerProvider.future);
  return ref
      .watch(contentRepositoryProvider)
      .loadSkins(settings.region.regionId, pageSize: 60);
});

final skinDetailProvider = FutureProvider.family<SkinDetail, int>((
  ref,
  skinId,
) {
  return ref.watch(contentRepositoryProvider).loadSkinDetail(skinId);
});

class SkinGalleryScreen extends ConsumerStatefulWidget {
  const SkinGalleryScreen({
    this.initialSkinId,
    this.initialSearchQuery,
    super.key,
  });

  final int? initialSkinId;
  final String? initialSearchQuery;

  @override
  ConsumerState<SkinGalleryScreen> createState() => _SkinGalleryScreenState();
}

class _SkinGalleryScreenState extends ConsumerState<SkinGalleryScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  _SkinSort _sort = _SkinSort.latest;
  int? _openedInitialSkinId;

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
    final galleryValue = ref.watch(skinGalleryProvider);
    final initialSkinId = widget.initialSkinId;

    if (initialSkinId != null && _openedInitialSkinId != initialSkinId) {
      _openedInitialSkinId = initialSkinId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _openDetail(context, initialSkinId);
        }
      });
    }

    return Material(
      color: AppTheme.bg,
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(skinGalleryProvider);
          await ref.read(skinGalleryProvider.future);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            const AppSectionHeader(title: 'Skin Gallery'),
            const SizedBox(height: 10),
            Text(
              'Browse hero skins, posters, splash art, ratings, and source links.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppTheme.muted),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              style: const TextStyle(color: AppTheme.text),
              decoration: InputDecoration(
                hintText: 'Search skin or hero',
                prefixIcon: const Icon(Icons.search, color: AppTheme.muted),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close, color: AppTheme.muted),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<_SkinSort>(
              segments: const [
                ButtonSegment(
                  value: _SkinSort.latest,
                  label: Text('Latest'),
                  icon: Icon(Icons.schedule),
                ),
                ButtonSegment(
                  value: _SkinSort.name,
                  label: Text('Name'),
                  icon: Icon(Icons.sort_by_alpha),
                ),
                ButtonSegment(
                  value: _SkinSort.rating,
                  label: Text('Rating'),
                  icon: Icon(Icons.star_border),
                ),
              ],
              selected: {_sort},
              onSelectionChanged: (value) =>
                  setState(() => _sort = value.first),
            ),
            const SizedBox(height: 18),
            AppAsyncView<List<ContentItemSummary>>(
              value: galleryValue,
              retry: () => ref.invalidate(skinGalleryProvider),
              data: (items) {
                final skins = _filterAndSort(items);
                if (skins.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.collections_outlined,
                    title: 'No skins found',
                    message: 'Try another hero or skin name.',
                  );
                }

                return GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: skins.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.64,
                  ),
                  itemBuilder: (context, index) {
                    return _SkinCard(
                      skin: skins[index],
                      onTap: () => _openDetail(context, skins[index].id),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<ContentItemSummary> _filterAndSort(List<ContentItemSummary> items) {
    final normalizedQuery = _query.trim().toLowerCase();
    final filtered = items
        .where((skin) {
          if (normalizedQuery.isEmpty) {
            return true;
          }
          return skin.title.toLowerCase().contains(normalizedQuery) ||
              skin.heroName.toLowerCase().contains(normalizedQuery) ||
              skin.subtitle.toLowerCase().contains(normalizedQuery);
        })
        .toList(growable: false);

    return [...filtered]..sort((left, right) {
      return switch (_sort) {
        _SkinSort.name => left.title.compareTo(right.title),
        _SkinSort.rating => right.rating.compareTo(left.rating),
        _SkinSort.latest => right.id.compareTo(left.id),
      };
    });
  }

  void _openDetail(BuildContext context, int skinId) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppTheme.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _SkinDetailSheet(skinId: skinId),
    );
  }
}

class _SkinCard extends StatelessWidget {
  const _SkinCard({required this.skin, required this.onTap});

  final ContentItemSummary skin;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panel,
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 178,
                  width: double.infinity,
                  child: AppImage(
                    url: skin.imageUrl,
                    width: double.infinity,
                    height: 178,
                    borderRadius: 12,
                    semanticLabel: skin.title,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  skin.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppTheme.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  skin.heroName.isEmpty ? skin.subtitle : skin.heroName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                ),
                const Spacer(),
                Text(
                  '${skin.rating.toStringAsFixed(1)} · ${skin.ratingCount} ratings',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.gold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SkinDetailSheet extends ConsumerWidget {
  const _SkinDetailSheet({required this.skinId});

  final int skinId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailValue = ref.watch(skinDetailProvider(skinId));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.86,
      minChildSize: 0.5,
      maxChildSize: 0.94,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.muted.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const AppSectionHeader(title: 'Skin Detail'),
            const SizedBox(height: 14),
            AppAsyncView<SkinDetail>(
              value: detailValue,
              retry: () => ref.invalidate(skinDetailProvider(skinId)),
              data: (detail) => _SkinDetailContent(detail: detail),
            ),
          ],
        );
      },
    );
  }
}

class _SkinDetailContent extends StatelessWidget {
  const _SkinDetailContent({required this.detail});

  final SkinDetail detail;

  @override
  Widget build(BuildContext context) {
    final images = [
      detail.portraitUrl,
      if (detail.landscapeUrl != detail.portraitUrl) detail.landscapeUrl,
    ].where((url) => url.isNotEmpty).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (images.isNotEmpty)
          SizedBox(
            height: 320,
            child: PageView.builder(
              itemCount: images.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: AppImage(
                    url: images[index],
                    width: double.infinity,
                    height: 320,
                    borderRadius: 18,
                    semanticLabel: detail.title,
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 18),
        Text(
          detail.heroName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppTheme.muted),
        ),
        const SizedBox(height: 4),
        Text(
          detail.title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppTheme.text,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (detail.seriesName.isNotEmpty)
              _DetailChip(label: detail.seriesName),
            if (detail.regionName.isNotEmpty)
              _DetailChip(label: detail.regionName),
            _DetailChip(label: detail.rating.toStringAsFixed(1)),
            _DetailChip(label: '${detail.ratingCount} ratings'),
          ],
        ),
        if (detail.linkUrl.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            detail.linkUrl,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
          ),
        ],
      ],
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.gold.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppTheme.gold,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

enum _SkinSort { latest, name, rating }
