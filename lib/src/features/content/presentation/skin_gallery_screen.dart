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

const _skinGalleryPageSize = 60;

final skinGalleryRegionProvider = FutureProvider<int>((ref) async {
  final settings = await ref.watch(appSettingsControllerProvider.future);
  return settings.region.regionId;
});

final skinGalleryProvider = FutureProvider<List<ContentItemSummary>>((
  ref,
) async {
  final regionId = await ref.watch(skinGalleryRegionProvider.future);
  return ref
      .watch(contentRepositoryProvider)
      .loadSkins(regionId, pageSize: _skinGalleryPageSize);
});

final skinGalleryQueryProvider =
    FutureProvider.family<List<ContentItemSummary>, _SkinGalleryQuery>((
      ref,
      query,
    ) async {
      if (query.isDefault) {
        return ref.watch(skinGalleryProvider.future);
      }
      final regionId = await ref.watch(skinGalleryRegionProvider.future);
      return ref
          .watch(contentRepositoryProvider)
          .loadSkins(
            regionId,
            pageSize: _skinGalleryPageSize,
            sort: query.sort.apiValue,
            order: 'desc',
            search: query.search,
            minRating: query.minRating,
            lanePosition: query.lanePosition,
          );
    });

final skinDetailProvider = FutureProvider.family<SkinDetail, int>((
  ref,
  skinId,
) {
  return ref.watch(contentRepositoryProvider).loadSkinDetail(skinId);
});

class _SkinGalleryQuery {
  const _SkinGalleryQuery({
    this.sort = _SkinSort.latest,
    this.search = '',
    this.minRating = 0,
    this.lanePosition,
  });

  final _SkinSort sort;
  final String search;
  final double minRating;
  final int? lanePosition;

  bool get isDefault =>
      sort == _SkinSort.latest &&
      search.trim().isEmpty &&
      minRating <= 0 &&
      lanePosition == null;

  @override
  bool operator ==(Object other) {
    return other is _SkinGalleryQuery &&
        other.sort == sort &&
        other.search == search &&
        other.minRating == minRating &&
        other.lanePosition == lanePosition;
  }

  @override
  int get hashCode => Object.hash(sort, search, minRating, lanePosition);
}

class SkinGalleryScreen extends ConsumerStatefulWidget {
  const SkinGalleryScreen({
    this.initialSkinId,
    this.initialMinRating,
    this.initialLanePosition,
    this.initialSearchQuery,
    super.key,
  });

  final int? initialSkinId;
  final double? initialMinRating;
  final int? initialLanePosition;
  final String? initialSearchQuery;

  @override
  ConsumerState<SkinGalleryScreen> createState() => _SkinGalleryScreenState();
}

class _SkinGalleryScreenState extends ConsumerState<SkinGalleryScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  _SkinViewMode _viewMode = _SkinViewMode.poster;
  _SkinSort _sort = _SkinSort.latest;
  double _minRating = 0;
  int? _lanePosition;
  int? _openedInitialSkinId;
  int? _ratingSkinId;
  final _extraSkins = <ContentItemSummary>[];
  var _nextPage = 2;
  var _hasMoreSkins = true;
  var _isLoadingMoreSkins = false;

  @override
  void initState() {
    super.initState();
    final initialQuery = widget.initialSearchQuery?.trim() ?? '';
    if (initialQuery.isNotEmpty) {
      _query = initialQuery;
      _searchController.text = initialQuery;
    }
    final initialMinRating = widget.initialMinRating;
    if (initialMinRating != null && initialMinRating > 0) {
      _minRating = initialMinRating.clamp(0, 5).toDouble();
    }
    _lanePosition = widget.initialLanePosition;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final galleryQuery = _SkinGalleryQuery(
      sort: _sort,
      search: _query,
      minRating: _minRating,
      lanePosition: _lanePosition,
    );
    final galleryValue = ref.watch(skinGalleryQueryProvider(galleryQuery));
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
          _resetLoadedPages();
          ref.invalidate(skinGalleryQueryProvider(galleryQuery));
          await ref.read(skinGalleryQueryProvider(galleryQuery).future);
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
              onChanged: (value) => setState(() {
                _query = value;
                _resetLoadedPages();
              }),
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
                          setState(() {
                            _query = '';
                            _resetLoadedPages();
                          });
                        },
                        icon: const Icon(Icons.close, color: AppTheme.muted),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<_SkinViewMode>(
              segments: const [
                ButtonSegment(
                  value: _SkinViewMode.poster,
                  label: Text('Poster'),
                  icon: Icon(Icons.view_module_outlined),
                ),
                ButtonSegment(
                  value: _SkinViewMode.splash,
                  label: Text('Splash'),
                  icon: Icon(Icons.panorama_outlined),
                ),
              ],
              selected: {_viewMode},
              onSelectionChanged: (value) =>
                  setState(() => _viewMode = value.first),
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
              onSelectionChanged: (value) => setState(() {
                _sort = value.first;
                _resetLoadedPages();
              }),
            ),
            const SizedBox(height: 12),
            _RatingFilterBar(
              minRating: _minRating,
              onChanged: (value) => setState(() {
                _minRating = value;
                _resetLoadedPages();
              }),
            ),
            const SizedBox(height: 10),
            _LaneFilterBar(
              lanePosition: _lanePosition,
              onChanged: (value) => setState(() {
                _lanePosition = value;
                _resetLoadedPages();
              }),
            ),
            if ((widget.initialMinRating ?? 0) > 0 ||
                widget.initialLanePosition != null) ...[
              const SizedBox(height: 12),
              _FocusedSkinFilterBanner(
                minRating: _minRating,
                lanePosition: _lanePosition,
              ),
            ],
            const SizedBox(height: 18),
            AppAsyncView<List<ContentItemSummary>>(
              value: galleryValue,
              retry: () =>
                  ref.invalidate(skinGalleryQueryProvider(galleryQuery)),
              data: (items) {
                final allItems = [...items, ..._extraSkins];
                final skins = _filterAndSort(allItems);
                if (skins.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.collections_outlined,
                    title: 'No skins found',
                    message: 'Try another hero or skin name.',
                  );
                }

                return Column(
                  children: [
                    GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: skins.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _viewMode == _SkinViewMode.poster
                            ? 2
                            : 1,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: _viewMode == _SkinViewMode.poster
                            ? 0.64
                            : 1.42,
                      ),
                      itemBuilder: (context, index) {
                        return _SkinCard(
                          skin: skins[index],
                          viewMode: _viewMode,
                          isRating: _ratingSkinId == skins[index].id,
                          onRate: (rating) =>
                              _rateSkinFromCard(skins[index], rating),
                          onTap: () => _openDetail(context, skins[index].id),
                        );
                      },
                    ),
                    if (_hasMoreSkins && items.length >= _skinGalleryPageSize)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: FilledButton.icon(
                          onPressed: _isLoadingMoreSkins
                              ? null
                              : _loadMoreSkins,
                          icon: _isLoadingMoreSkins
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.expand_more),
                          label: Text(
                            _isLoadingMoreSkins ? 'Loading...' : 'Load more',
                          ),
                        ),
                      ),
                  ],
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
          if (skin.rating < _minRating) {
            return false;
          }

          if (_lanePosition != null && skin.heroPosition != _lanePosition) {
            return false;
          }

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

  void _resetLoadedPages() {
    _extraSkins.clear();
    _nextPage = 2;
    _hasMoreSkins = true;
    _isLoadingMoreSkins = false;
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

  Future<void> _rateSkinFromCard(ContentItemSummary skin, double rating) async {
    if (_ratingSkinId != null) {
      return;
    }

    setState(() => _ratingSkinId = skin.id);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ref.read(contentRepositoryProvider).rateSkin(skin.id, rating);
      ref.invalidate(skinGalleryProvider);
      messenger.showSnackBar(const SnackBar(content: Text('Rating submitted')));
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to submit rating: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _ratingSkinId = null);
      }
    }
  }

  Future<void> _loadMoreSkins() async {
    if (_isLoadingMoreSkins || !_hasMoreSkins) {
      return;
    }

    setState(() => _isLoadingMoreSkins = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final regionId = await ref.read(skinGalleryRegionProvider.future);
      final nextItems = await ref
          .read(contentRepositoryProvider)
          .loadSkins(
            regionId,
            page: _nextPage,
            pageSize: _skinGalleryPageSize,
            sort: _sort.apiValue,
            order: 'desc',
            search: _query,
            minRating: _minRating,
            lanePosition: _lanePosition,
          );

      if (!mounted) {
        return;
      }

      setState(() {
        _nextPage += 1;
        _extraSkins.addAll(nextItems);
        _hasMoreSkins = nextItems.length >= _skinGalleryPageSize;
        _isLoadingMoreSkins = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoadingMoreSkins = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to load more skins: $error')),
      );
    }
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

class _LaneFilterOption {
  const _LaneFilterOption({required this.label, this.value});

  final String label;
  final int? value;
}

class _FocusedSkinFilterBanner extends StatelessWidget {
  const _FocusedSkinFilterBanner({
    required this.minRating,
    required this.lanePosition,
  });

  final double minRating;
  final int? lanePosition;

  @override
  Widget build(BuildContext context) {
    final labels = <String>[
      if (minRating > 0) '${minRating.toStringAsFixed(1)}+ rating',
      if (lanePosition != null) _lanePositionLabel(lanePosition),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.filter_alt_outlined, color: AppTheme.gold),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Focused skin filters',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (labels.isNotEmpty)
              Flexible(
                child: Text(
                  labels.join(' · '),
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTheme.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _lanePositionLabel(int? value) {
  return switch (value) {
    0 => 'Clash',
    1 => 'Mid',
    2 => 'Farm',
    3 => 'Jungle',
    4 => 'Support',
    _ => 'All lanes',
  };
}

class _RatingFilterBar extends StatelessWidget {
  const _RatingFilterBar({required this.minRating, required this.onChanged});

  final double minRating;
  final ValueChanged<double> onChanged;

  static const _options = [
    _RatingFilterOption(label: 'All ratings', value: 0),
    _RatingFilterOption(label: '4+', value: 4),
    _RatingFilterOption(label: '4.5+', value: 4.5),
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
            avatar: option.value == 0
                ? const Icon(Icons.filter_alt_off, size: 16)
                : const Icon(Icons.star, size: 16),
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
  const _RatingFilterOption({required this.label, required this.value});

  final String label;
  final double value;
}

class _SkinCard extends StatelessWidget {
  const _SkinCard({
    required this.skin,
    required this.viewMode,
    required this.isRating,
    required this.onRate,
    required this.onTap,
  });

  final ContentItemSummary skin;
  final _SkinViewMode viewMode;
  final bool isRating;
  final ValueChanged<double> onRate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSplash = viewMode == _SkinViewMode.splash;
    final imageUrl = isSplash && skin.landscapeImageUrl.isNotEmpty
        ? skin.landscapeImageUrl
        : skin.imageUrl;
    final imageHeight = isSplash ? 150.0 : 178.0;

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
                  height: imageHeight,
                  width: double.infinity,
                  child: AppImage(
                    url: imageUrl,
                    width: double.infinity,
                    height: imageHeight,
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
                const SizedBox(height: 4),
                _SkinCardRatingControl(
                  skinTitle: skin.title,
                  rating: skin.rating,
                  isRating: isRating,
                  onRate: onRate,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SkinCardRatingControl extends StatelessWidget {
  const _SkinCardRatingControl({
    required this.skinTitle,
    required this.rating,
    required this.isRating,
    required this.onRate,
  });

  final String skinTitle;
  final double rating;
  final bool isRating;
  final ValueChanged<double> onRate;

  @override
  Widget build(BuildContext context) {
    final roundedRating = rating.round();
    return Row(
      children: [
        for (var index = 1; index <= 5; index++)
          IconButton(
            tooltip: 'Rate $skinTitle $index stars',
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 28, height: 28),
            padding: EdgeInsets.zero,
            onPressed: isRating ? null : () => onRate(index.toDouble()),
            icon: Icon(
              index <= roundedRating ? Icons.star : Icons.star_border,
              color: AppTheme.gold,
              size: 18,
            ),
          ),
      ],
    );
  }
}

class _SkinDetailSheet extends ConsumerStatefulWidget {
  const _SkinDetailSheet({required this.skinId});

  final int skinId;

  @override
  ConsumerState<_SkinDetailSheet> createState() => _SkinDetailSheetState();
}

class _SkinDetailSheetState extends ConsumerState<_SkinDetailSheet> {
  var _isRating = false;
  double? _ratingOverride;
  int? _ratingCountOverride;

  @override
  Widget build(BuildContext context) {
    final detailValue = ref.watch(skinDetailProvider(widget.skinId));

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
              retry: () => ref.invalidate(skinDetailProvider(widget.skinId)),
              data: (detail) => _SkinDetailContent(
                detail: detail,
                rating: _ratingOverride ?? detail.rating,
                ratingCount: _ratingCountOverride ?? detail.ratingCount,
                isRating: _isRating,
                onRate: _rateSkin,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _rateSkin(double rating) async {
    if (_isRating) {
      return;
    }

    setState(() => _isRating = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final result = await ref
          .read(contentRepositoryProvider)
          .rateSkin(widget.skinId, rating);
      setState(() {
        _ratingOverride = result.rating;
        _ratingCountOverride = result.ratingCount;
      });
      ref.invalidate(skinGalleryProvider);
      ref.invalidate(skinDetailProvider(widget.skinId));
      messenger.showSnackBar(const SnackBar(content: Text('Rating submitted')));
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to submit rating: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isRating = false);
      }
    }
  }
}

class _SkinDetailContent extends StatelessWidget {
  const _SkinDetailContent({
    required this.detail,
    required this.rating,
    required this.ratingCount,
    required this.isRating,
    required this.onRate,
  });

  final SkinDetail detail;
  final double rating;
  final int ratingCount;
  final bool isRating;
  final ValueChanged<double> onRate;

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
            _DetailChip(label: rating.toStringAsFixed(1)),
            _DetailChip(label: '$ratingCount ratings'),
          ],
        ),
        const SizedBox(height: 14),
        _SkinRatingControl(rating: rating, isRating: isRating, onRate: onRate),
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

class _SkinRatingControl extends StatelessWidget {
  const _SkinRatingControl({
    required this.rating,
    required this.isRating,
    required this.onRate,
  });

  final double rating;
  final bool isRating;
  final ValueChanged<double> onRate;

  @override
  Widget build(BuildContext context) {
    final roundedRating = rating.round();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panel,
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Rate this skin',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            for (var index = 1; index <= 5; index++)
              IconButton(
                tooltip: 'Rate skin $index stars',
                onPressed: isRating ? null : () => onRate(index.toDouble()),
                icon: Icon(
                  index <= roundedRating ? Icons.star : Icons.star_border,
                  color: AppTheme.gold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

enum _SkinSort {
  latest('id'),
  name('name'),
  rating('rating');

  const _SkinSort(this.apiValue);

  final String apiValue;
}

enum _SkinViewMode { poster, splash }
