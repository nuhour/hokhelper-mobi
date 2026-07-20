import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_rating_stars.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/app_video_player_sheet.dart';
import '../../settings/presentation/settings_controller.dart';
import '../domain/cg_detail.dart';
import '../domain/content_item_summary.dart';
import 'content_screen.dart';

const _cgGalleryPageSize = 60;

final cgGalleryRegionProvider = FutureProvider<int>((ref) async {
  final settings = await ref.watch(appSettingsControllerProvider.future);
  return settings.region.regionId;
});

final cgGalleryProvider = FutureProvider<List<ContentItemSummary>>((ref) async {
  final regionId = await ref.watch(cgGalleryRegionProvider.future);
  return ref
      .watch(contentRepositoryProvider)
      .loadCgs(regionId, pageSize: _cgGalleryPageSize);
});

final cgGalleryQueryProvider =
    FutureProvider.family<List<ContentItemSummary>, _CgGalleryQuery>((
      ref,
      query,
    ) async {
      if (query.isDefault) {
        return ref.watch(cgGalleryProvider.future);
      }
      final regionId = await ref.watch(cgGalleryRegionProvider.future);
      return ref
          .watch(contentRepositoryProvider)
          .loadCgs(
            regionId,
            pageSize: _cgGalleryPageSize,
            sort: query.sort.apiValue,
            order: query.order.apiValue,
            search: query.search,
            heroId: query.heroId,
          );
    });

final cgDetailProvider = FutureProvider.family<CgDetail, int>((ref, cgId) {
  return ref.watch(contentRepositoryProvider).loadCgDetail(cgId);
});

final cgCommentsProvider =
    FutureProvider.family<List<CgCommentSummary>, Object>((ref, query) {
      final commentsQuery = query is CgCommentsQuery
          ? query
          : CgCommentsQuery(query as int);
      return ref
          .watch(contentRepositoryProvider)
          .loadCgComments(commentsQuery.cgId, order: commentsQuery.order);
    });

class CgCommentsQuery {
  const CgCommentsQuery(this.cgId, {this.order = 'desc'});

  final int cgId;
  final String order;

  @override
  bool operator ==(Object other) {
    return other is CgCommentsQuery &&
        other.cgId == cgId &&
        other.order == order;
  }

  @override
  int get hashCode => Object.hash(cgId, order);
}

class _CgGalleryQuery {
  const _CgGalleryQuery({
    this.sort = _CgSort.updated,
    this.order = _CgSortOrder.desc,
    this.search = '',
    this.heroId,
  });

  final _CgSort sort;
  final _CgSortOrder order;
  final String search;
  final int? heroId;

  bool get isDefault =>
      sort == _CgSort.updated &&
      order == _CgSortOrder.desc &&
      search.trim().isEmpty &&
      heroId == null;

  @override
  bool operator ==(Object other) {
    return other is _CgGalleryQuery &&
        other.sort == sort &&
        other.order == order &&
        other.search == search &&
        other.heroId == heroId;
  }

  @override
  int get hashCode => Object.hash(sort, order, search, heroId);
}

class CgGalleryScreen extends ConsumerStatefulWidget {
  const CgGalleryScreen({
    this.initialCgId,
    this.initialHeroId,
    this.initialSearchQuery,
    super.key,
  });

  final int? initialCgId;
  final int? initialHeroId;
  final String? initialSearchQuery;

  @override
  ConsumerState<CgGalleryScreen> createState() => _CgGalleryScreenState();
}

class _CgGalleryScreenState extends ConsumerState<CgGalleryScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  _CgSort _sort = _CgSort.updated;
  _CgSortOrder _sortOrder = _CgSortOrder.desc;
  int? _heroId;
  int? _openedInitialCgId;
  final _extraCgs = <ContentItemSummary>[];
  var _nextPage = 2;
  var _hasMoreCgs = true;
  var _isLoadingMoreCgs = false;

  @override
  void initState() {
    super.initState();
    final initialQuery = widget.initialSearchQuery?.trim() ?? '';
    if (initialQuery.isNotEmpty) {
      _query = initialQuery;
      _searchController.text = initialQuery;
    }
    _heroId = widget.initialHeroId;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _CgGalleryQuery(
      sort: _sort,
      order: _sortOrder,
      search: _query,
      heroId: _heroId,
    );
    final galleryValue = ref.watch(cgGalleryQueryProvider(query));
    final initialCgId = widget.initialCgId;

    if (initialCgId != null && _openedInitialCgId != initialCgId) {
      _openedInitialCgId = initialCgId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _openDetail(context, initialCgId);
        }
      });
    }

    return Material(
      color: context.hokTheme.backgroundDeep,
      child: RefreshIndicator(
        onRefresh: () async {
          _resetLoadedPages();
          ref.invalidate(cgGalleryQueryProvider(query));
          await ref.read(cgGalleryQueryProvider(query).future);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            const AppSectionHeader(title: 'CG Center'),
            const SizedBox(height: 14),
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() {
                _query = value;
                _resetLoadedPages();
              }),
              style: TextStyle(color: context.hokTheme.onSurfaceStrong),
              decoration: InputDecoration(
                hintText: 'Search CG or hero',
                prefixIcon: Icon(
                  Icons.search,
                  color: context.hokTheme.onSurfaceMuted,
                ),
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
                        icon: Icon(
                          Icons.close,
                          color: context.hokTheme.onSurfaceMuted,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            _CgSortBar(
              selected: _sort,
              onSelected: (value) => setState(() {
                _sort = value;
                _resetLoadedPages();
              }),
            ),
            const SizedBox(height: 12),
            SegmentedButton<_CgSortOrder>(
              segments: const [
                ButtonSegment(
                  value: _CgSortOrder.desc,
                  label: Text('Descending'),
                  icon: Icon(Icons.south),
                ),
                ButtonSegment(
                  value: _CgSortOrder.asc,
                  label: Text('Ascending'),
                  icon: Icon(Icons.north),
                ),
              ],
              selected: {_sortOrder},
              onSelectionChanged: (value) => setState(() {
                _sortOrder = value.first;
                _resetLoadedPages();
              }),
            ),
            const SizedBox(height: 18),
            AppAsyncView<List<ContentItemSummary>>(
              value: galleryValue,
              retry: () => ref.invalidate(cgGalleryQueryProvider(query)),
              data: (items) {
                final allItems = [...items, ..._extraCgs];
                final heroOptions = _heroFilterOptions(allItems);
                final cgs = _filterAndSort(allItems);
                if (cgs.isEmpty) {
                  return Column(
                    children: [
                      _HeroFilterDropdown(
                        heroId: _heroId,
                        options: heroOptions,
                        onChanged: _changeHeroFilter,
                      ),
                      const SizedBox(height: 12),
                      const AppEmptyState(
                        icon: Icons.movie_creation_outlined,
                        title: 'No CGs found',
                        message: 'Try another hero or title.',
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    _HeroFilterDropdown(
                      heroId: _heroId,
                      options: heroOptions,
                      onChanged: _changeHeroFilter,
                    ),
                    if (_heroId != null) ...[
                      const SizedBox(height: 12),
                      _FocusedHeroBanner(heroId: _heroId!),
                    ],
                    const SizedBox(height: 12),
                    ListView.separated(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: cgs.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _CgCard(
                          cg: cgs[index],
                          onTap: () => _openDetail(context, cgs[index].id),
                        );
                      },
                    ),
                    if (_hasMoreCgs && items.length >= _cgGalleryPageSize)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: FilledButton.icon(
                          onPressed: _isLoadingMoreCgs ? null : _loadMoreCgs,
                          icon: _isLoadingMoreCgs
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.expand_more),
                          label: Text(
                            _isLoadingMoreCgs ? 'Loading...' : 'Load more',
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
    final heroId = _heroId;
    final filtered = items
        .where((cg) {
          if (heroId != null && cg.heroId != heroId) {
            return false;
          }
          if (normalizedQuery.isEmpty) {
            return true;
          }
          return cg.title.toLowerCase().contains(normalizedQuery) ||
              cg.heroName.toLowerCase().contains(normalizedQuery);
        })
        .toList(growable: false);

    return [...filtered]..sort((left, right) {
      final comparison = switch (_sort) {
        _CgSort.rating => left.rating.compareTo(right.rating),
        _CgSort.views => left.viewCount.compareTo(right.viewCount),
        _CgSort.updated || _CgSort.created => left.id.compareTo(right.id),
      };
      return _sortOrder == _CgSortOrder.asc ? comparison : -comparison;
    });
  }

  List<_CgHeroFilterOption> _heroFilterOptions(List<ContentItemSummary> items) {
    final optionsById = <int, _CgHeroFilterOption>{};
    for (final cg in items) {
      final heroId = cg.heroId;
      if (heroId == null || optionsById.containsKey(heroId)) {
        continue;
      }
      optionsById[heroId] = _CgHeroFilterOption(
        heroId: heroId,
        label: cg.heroName.isEmpty ? 'Hero #$heroId' : cg.heroName,
      );
    }
    final selectedHeroId = _heroId;
    if (selectedHeroId != null && !optionsById.containsKey(selectedHeroId)) {
      optionsById[selectedHeroId] = _CgHeroFilterOption(
        heroId: selectedHeroId,
        label: 'Hero #$selectedHeroId',
      );
    }
    final options = optionsById.values.toList(growable: false);
    return [...options]
      ..sort((left, right) => left.label.compareTo(right.label));
  }

  void _changeHeroFilter(int? heroId) {
    setState(() {
      _heroId = heroId;
      _resetLoadedPages();
    });
  }

  void _openDetail(BuildContext context, int cgId) {
    final router = GoRouter.maybeOf(context);
    final listPath = router == null
        ? null
        : _cgGalleryListPath(router.routeInformationProvider.value.uri);
    if (router != null && listPath != null) {
      _syncDetailRoute(router: router, listPath: listPath, cgId: cgId);
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.hokTheme.backgroundDeep,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _CgDetailSheet(cgId: cgId),
    ).whenComplete(() {
      if (mounted && router != null && listPath != null) {
        final currentPath = router.routeInformationProvider.value.uri.path;
        if (currentPath == '$listPath/$cgId') {
          _syncDetailRoute(router: router, listPath: listPath, cgId: null);
        }
      }
    });
  }

  String _cgGalleryListPath(Uri uri) {
    return uri.path.startsWith('/content/cgs') ? '/content/cgs' : '/cg';
  }

  void _syncDetailRoute({
    required GoRouter router,
    required String listPath,
    required int? cgId,
  }) {
    final currentUri = router.routeInformationProvider.value.uri;
    final nextUri = currentUri.replace(
      path: cgId == null ? listPath : '$listPath/$cgId',
    );
    if (nextUri == currentUri) {
      return;
    }
    router.go(nextUri.toString());
  }

  void _resetLoadedPages() {
    _extraCgs.clear();
    _nextPage = 2;
    _hasMoreCgs = true;
    _isLoadingMoreCgs = false;
  }

  Future<void> _loadMoreCgs() async {
    if (_isLoadingMoreCgs || !_hasMoreCgs) {
      return;
    }

    setState(() => _isLoadingMoreCgs = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final regionId = await ref.read(cgGalleryRegionProvider.future);
      final nextItems = await ref
          .read(contentRepositoryProvider)
          .loadCgs(
            regionId,
            page: _nextPage,
            pageSize: _cgGalleryPageSize,
            sort: _sort.apiValue,
            order: _sortOrder.apiValue,
            search: _query,
            heroId: _heroId,
          );

      if (!mounted) {
        return;
      }

      setState(() {
        _nextPage += 1;
        _extraCgs.addAll(nextItems);
        _hasMoreCgs = nextItems.length >= _cgGalleryPageSize;
        _isLoadingMoreCgs = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoadingMoreCgs = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to load more CGs: $error')),
      );
    }
  }
}

class _HeroFilterDropdown extends StatelessWidget {
  const _HeroFilterDropdown({
    required this.heroId,
    required this.options,
    required this.onChanged,
  });

  final int? heroId;
  final List<_CgHeroFilterOption> options;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int?>(
      initialValue: heroId,
      decoration: const InputDecoration(
        labelText: 'Hero filter',
        prefixIcon: Icon(Icons.person_search_outlined),
      ),
      items: [
        const DropdownMenuItem<int?>(value: null, child: Text('All heroes')),
        for (final option in options)
          DropdownMenuItem<int?>(
            value: option.heroId,
            child: Text(option.label),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

class _CgHeroFilterOption {
  const _CgHeroFilterOption({required this.heroId, required this.label});

  final int heroId;
  final String label;
}

class _FocusedHeroBanner extends StatelessWidget {
  const _FocusedHeroBanner({required this.heroId});

  final int heroId;

  @override
  Widget build(BuildContext context) {
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
            const Icon(Icons.person_search_outlined, color: AppTheme.gold),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Focused hero CGs',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: context.hokTheme.onSurfaceStrong,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '#$heroId',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: context.hokTheme.onSurfaceMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CgSortBar extends StatelessWidget {
  const _CgSortBar({required this.selected, required this.onSelected});

  final _CgSort selected;
  final ValueChanged<_CgSort> onSelected;

  @override
  Widget build(BuildContext context) {
    const entries = [
      (_CgSort.updated, Icons.update, 'Updated'),
      (_CgSort.rating, Icons.star_outline_rounded, 'Rating'),
      (_CgSort.created, Icons.calendar_today_outlined, 'Created'),
      (_CgSort.views, Icons.visibility_outlined, 'Views'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final entry in entries) ...[
            ChoiceChip(
              avatar: Icon(entry.$2, size: 16),
              label: Text(entry.$3),
              selected: selected == entry.$1,
              onSelected: (_) => onSelected(entry.$1),
            ),
            if (entry != entries.last) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _CgCard extends StatelessWidget {
  const _CgCard({required this.cg, required this.onTap});

  final ContentItemSummary cg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final heroAvatarUrl = cg.heroId == null
        ? ''
        : 'https://hokhelper.com/static/game/hero/${cg.heroId}.png';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.hokTheme.surfaceSlate,
        border: Border.all(color: context.hokTheme.outlineSoft),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    alignment: Alignment.center,
                    children: [
                      AppImage(
                        url: cg.imageUrl,
                        width: double.infinity,
                        height: double.infinity,
                        borderRadius: 0,
                        semanticLabel: cg.title,
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.24),
                        ),
                      ),
                      Center(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.56),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(10),
                            child: Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppImage(
                      url: heroAvatarUrl,
                      width: 38,
                      height: 38,
                      borderRadius: 19,
                      semanticLabel: cg.heroName,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            cg.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: context.hokTheme.onSurfaceStrong,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            cg.heroName.isEmpty ? 'Video' : cg.heroName,
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
                    AppRatingStars(
                      rating: cg.rating,
                      ratingCount: cg.ratingCount,
                      size: 11,
                      showCount: false,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(60, 0, 12, 12),
                child: Text(
                  '${_compact(cg.viewCount)} views · ${cg.ratingCount} ratings',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: context.hokTheme.onSurfaceMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CgDetailSheet extends ConsumerStatefulWidget {
  const _CgDetailSheet({required this.cgId});

  final int cgId;

  @override
  ConsumerState<_CgDetailSheet> createState() => _CgDetailSheetState();
}

class _CgDetailSheetState extends ConsumerState<_CgDetailSheet> {
  final _commentController = TextEditingController();
  var _isPosting = false;
  var _isRating = false;
  var _commentOrder = 'desc';
  int? _viewCountOverride;
  double? _ratingOverride;
  int? _ratingCountOverride;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_recordView);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commentsQuery = CgCommentsQuery(widget.cgId, order: _commentOrder);
    final detailValue = ref.watch(cgDetailProvider(widget.cgId));
    final commentsValue = ref.watch(cgCommentsProvider(commentsQuery));

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
                  color: context.hokTheme.onSurfaceMuted.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const AppSectionHeader(title: 'CG Detail'),
            const SizedBox(height: 14),
            AppAsyncView<CgDetail>(
              value: detailValue,
              retry: () => ref.invalidate(cgDetailProvider(widget.cgId)),
              data: (detail) => _CgDetailContent(
                detail: detail,
                viewCount: _viewCountOverride ?? detail.viewCount,
                rating: _ratingOverride ?? detail.rating,
                ratingCount: _ratingCountOverride ?? detail.ratingCount,
                isRating: _isRating,
                onRate: _rateCg,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Comments',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: context.hokTheme.onSurfaceStrong,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            _CgCommentOrderSelector(
              order: _commentOrder,
              onChanged: (order) => setState(() => _commentOrder = order),
            ),
            const SizedBox(height: 10),
            _CgCommentComposer(
              controller: _commentController,
              isPosting: _isPosting,
              onSubmit: _postComment,
            ),
            const SizedBox(height: 14),
            AppAsyncView<List<CgCommentSummary>>(
              value: commentsValue,
              retry: () => ref.invalidate(cgCommentsProvider(commentsQuery)),
              data: (comments) {
                if (comments.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.chat_bubble_outline,
                    title: 'No comments yet',
                    message: 'Community comments will appear here.',
                  );
                }
                return ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: comments.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      _CgCommentCard(comment: comments[index]),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _postComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty || _isPosting) {
      return;
    }

    setState(() => _isPosting = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ref
          .read(contentRepositoryProvider)
          .createCgComment(widget.cgId, content);
      _commentController.clear();
      ref.invalidate(
        cgCommentsProvider(CgCommentsQuery(widget.cgId, order: _commentOrder)),
      );
      messenger.showSnackBar(const SnackBar(content: Text('Comment posted')));
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to post comment: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  Future<void> _recordView() async {
    try {
      final viewCount = await ref
          .read(contentRepositoryProvider)
          .recordCgView(widget.cgId);
      if (!mounted || viewCount <= 0) {
        return;
      }
      setState(() => _viewCountOverride = viewCount);
      ref.invalidate(cgGalleryProvider);
      ref.invalidate(cgDetailProvider(widget.cgId));
    } catch (_) {
      // Viewing should never block reading the CG detail.
    }
  }

  Future<void> _rateCg(double rating) async {
    if (_isRating) {
      return;
    }

    setState(() => _isRating = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final result = await ref
          .read(contentRepositoryProvider)
          .rateCg(widget.cgId, rating);
      setState(() {
        _ratingOverride = result.rating;
        _ratingCountOverride = result.ratingCount;
      });
      ref.invalidate(cgGalleryProvider);
      ref.invalidate(cgDetailProvider(widget.cgId));
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

class _CgCommentComposer extends StatelessWidget {
  const _CgCommentComposer({
    required this.controller,
    required this.isPosting,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool isPosting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.hokTheme.surfaceSlate,
        border: Border.all(color: context.hokTheme.outlineSoft),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: controller,
              minLines: 2,
              maxLines: 4,
              enabled: !isPosting,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                labelText: 'Write a comment',
                hintText: 'Share your thoughts on this CG...',
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: isPosting ? null : onSubmit,
                icon: isPosting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: const Text('Post comment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CgCommentOrderSelector extends StatelessWidget {
  const _CgCommentOrderSelector({required this.order, required this.onChanged});

  final String order;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: const Text('Newest first'),
          selected: order == 'desc',
          onSelected: (_) => onChanged('desc'),
          avatar: const Icon(Icons.south, size: 16),
        ),
        ChoiceChip(
          label: const Text('Oldest first'),
          selected: order == 'asc',
          onSelected: (_) => onChanged('asc'),
          avatar: const Icon(Icons.north, size: 16),
        ),
      ],
    );
  }
}

class _CgDetailContent extends StatelessWidget {
  const _CgDetailContent({
    required this.detail,
    required this.viewCount,
    required this.rating,
    required this.ratingCount,
    required this.isRating,
    required this.onRate,
  });

  final CgDetail detail;
  final int viewCount;
  final double rating;
  final int ratingCount;
  final bool isRating;
  final ValueChanged<double> onRate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: detail.playUrl.isEmpty
                ? null
                : () => showAppVideoPlayer(
                    context,
                    url: detail.playUrl,
                    title: detail.title,
                  ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AppImage(
                  url: detail.coverUrl,
                  width: double.infinity,
                  height: 210,
                  borderRadius: 18,
                  semanticLabel: detail.title,
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.56),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.32),
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          detail.heroName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: context.hokTheme.onSurfaceMuted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          detail.title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: context.hokTheme.onSurfaceStrong,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [_DetailChip(label: '${_compact(viewCount)} views')],
        ),
        const SizedBox(height: 14),
        AppRatingStars(rating: rating, ratingCount: ratingCount, size: 18),
        const SizedBox(height: 14),
        _CgRatingControl(rating: rating, isRating: isRating, onRate: onRate),
        if (detail.playUrl.isNotEmpty) ...[
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => showAppVideoPlayer(
              context,
              url: detail.playUrl,
              title: detail.title,
            ),
            icon: const Icon(Icons.play_circle_outline, size: 18),
            label: const Text('Play video'),
          ),
        ],
      ],
    );
  }
}

class _CgCommentCard extends StatelessWidget {
  const _CgCommentCard({required this.comment});

  final CgCommentSummary comment;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.hokTheme.surfaceSlate,
        border: Border.all(color: context.hokTheme.outlineSoft),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppImage(
                  url: comment.authorAvatarUrl,
                  width: 32,
                  height: 32,
                  borderRadius: 11,
                  semanticLabel: comment.authorName,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    comment.authorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: context.hokTheme.onSurfaceStrong,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              comment.content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.hokTheme.onSurfaceStrong,
                height: 1.35,
              ),
            ),
            if (comment.createdAt.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                _formatCgCommentTime(comment.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.hokTheme.onSurfaceMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _formatCgCommentTime(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value;
  }
  String twoDigits(int number) => number.toString().padLeft(2, '0');
  return '${parsed.year}-${twoDigits(parsed.month)}-${twoDigits(parsed.day)} '
      '${twoDigits(parsed.hour)}:${twoDigits(parsed.minute)}';
}

class _CgRatingControl extends StatelessWidget {
  const _CgRatingControl({
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
        color: context.hokTheme.surfaceSlate,
        border: Border.all(color: context.hokTheme.outlineSoft),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Rate this CG',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.hokTheme.onSurfaceStrong,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            for (var index = 1; index <= 5; index++)
              IconButton(
                tooltip: 'Rate $index stars',
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

String _compact(int value) {
  return value.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );
}

enum _CgSort {
  updated('updated_at'),
  rating('rating'),
  created('created_at'),
  views('view_count');

  const _CgSort(this.apiValue);

  final String apiValue;
}

enum _CgSortOrder {
  desc('desc'),
  asc('asc');

  const _CgSortOrder(this.apiValue);

  final String apiValue;
}
