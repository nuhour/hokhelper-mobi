import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/routing/portal_link.dart';
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
    this.lanePosition,
  });

  final _SkinSort sort;
  final String search;
  final int? lanePosition;

  bool get isDefault =>
      sort == _SkinSort.latest && search.trim().isEmpty && lanePosition == null;

  @override
  bool operator ==(Object other) {
    return other is _SkinGalleryQuery &&
        other.sort == sort &&
        other.search == search &&
        other.lanePosition == lanePosition;
  }

  @override
  int get hashCode => Object.hash(sort, search, lanePosition);
}

class SkinGalleryScreen extends ConsumerStatefulWidget {
  const SkinGalleryScreen({
    this.initialSkinId,
    this.initialLanePosition,
    this.initialSearchQuery,
    super.key,
  });

  final int? initialSkinId;
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
            const SizedBox(height: 14),
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
            const SizedBox(height: 10),
            _LaneFilterBar(
              lanePosition: _lanePosition,
              onChanged: (value) => setState(() {
                _lanePosition = value;
                _resetLoadedPages();
              }),
            ),
            if (widget.initialLanePosition != null) ...[
              const SizedBox(height: 12),
              _FocusedSkinFilterBanner(lanePosition: _lanePosition),
            ],
            const SizedBox(height: 18),
            AppAsyncView<List<ContentItemSummary>>(
              value: galleryValue,
              retry: () =>
                  ref.invalidate(skinGalleryQueryProvider(galleryQuery)),
              loadingStyle: AppAsyncLoadingStyle.gallery,
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
    final router = GoRouter.maybeOf(context);
    final listPath = router == null
        ? null
        : _skinGalleryListPath(router.routeInformationProvider.value.uri);
    if (router != null && listPath != null) {
      _syncDetailRoute(router: router, listPath: listPath, skinId: skinId);
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppTheme.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _SkinDetailSheet(skinId: skinId),
    ).whenComplete(() {
      if (mounted && router != null && listPath != null) {
        final currentPath = router.routeInformationProvider.value.uri.path;
        if (currentPath == '$listPath/$skinId') {
          _syncDetailRoute(router: router, listPath: listPath, skinId: null);
        }
      }
    });
  }

  String _skinGalleryListPath(Uri uri) {
    return uri.path.startsWith('/content/skins')
        ? '/content/skins'
        : '/skin-gallery';
  }

  void _syncDetailRoute({
    required GoRouter router,
    required String listPath,
    required int? skinId,
  }) {
    final currentUri = router.routeInformationProvider.value.uri;
    final nextUri = currentUri.replace(
      path: skinId == null ? listPath : '$listPath/$skinId',
    );
    if (nextUri == currentUri) {
      return;
    }
    router.go(nextUri.toString());
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
                key: ValueKey('skin-lane-${option.value ?? 'all'}'),
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
                        : AppTheme.panel,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: lanePosition == option.value
                          ? AppTheme.gold
                          : Colors.white.withValues(alpha: 0.08),
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

class _FocusedSkinFilterBanner extends StatelessWidget {
  const _FocusedSkinFilterBanner({required this.lanePosition});

  final int? lanePosition;

  @override
  Widget build(BuildContext context) {
    final labels = <String>[
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
          key: ValueKey('skin-card-${skin.id}'),
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          onLongPress: isRating ? null : () => _showRatingSheet(context),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AppImage(
                url: imageUrl,
                width: double.infinity,
                height: double.infinity,
                borderRadius: 0,
                semanticLabel: skin.title,
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x11000000),
                      Colors.transparent,
                      Color(0xE6000000),
                    ],
                    stops: [0, 0.35, 1],
                  ),
                ),
              ),
              if (skin.subtitle.isNotEmpty)
                Positioned(
                  top: 9,
                  right: 9,
                  child: _SkinSeriesPill(label: skin.subtitle),
                ),
              Positioned(
                left: 11,
                right: 11,
                bottom: 10,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            skin.title,
                            maxLines: isSplash ? 1 : 2,
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
                          if (skin.heroName.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              skin.heroName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _SkinRatingBadge(rating: skin.rating),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRatingSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _SkinCardRatingSheet(
        skinTitle: skin.title,
        rating: skin.rating,
        isRating: isRating,
        onRate: (rating) {
          Navigator.of(sheetContext).pop();
          onRate(rating);
        },
      ),
    );
  }
}

class _SkinSeriesPill extends StatelessWidget {
  const _SkinSeriesPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _SkinRatingBadge extends StatelessWidget {
  const _SkinRatingBadge({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, color: AppTheme.gold, size: 17),
        const SizedBox(width: 2),
        Text(
          rating > 0 ? rating.toStringAsFixed(1) : '--',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppTheme.gold,
            fontWeight: FontWeight.w900,
            shadows: const [Shadow(color: Colors.black, blurRadius: 6)],
          ),
        ),
      ],
    );
  }
}

class _SkinCardRatingSheet extends StatelessWidget {
  const _SkinCardRatingSheet({
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
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              skinTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.text,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var index = 1; index <= 5; index++)
                  IconButton(
                    tooltip: 'Rate $skinTitle $index stars',
                    constraints: const BoxConstraints.tightFor(
                      width: 48,
                      height: 48,
                    ),
                    onPressed: isRating ? null : () => onRate(index.toDouble()),
                    icon: Icon(
                      index <= roundedRating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: AppTheme.gold,
                      size: 30,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
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
          FilledButton.icon(
            onPressed: () => context.go(externalLinkRoute(detail.linkUrl)),
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('Open source'),
          ),
          const SizedBox(height: 8),
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
