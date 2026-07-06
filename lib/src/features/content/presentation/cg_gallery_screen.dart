import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_section_header.dart';
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

class CgGalleryScreen extends ConsumerStatefulWidget {
  const CgGalleryScreen({this.initialCgId, this.initialSearchQuery, super.key});

  final int? initialCgId;
  final String? initialSearchQuery;

  @override
  ConsumerState<CgGalleryScreen> createState() => _CgGalleryScreenState();
}

class _CgGalleryScreenState extends ConsumerState<CgGalleryScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  _CgSort _sort = _CgSort.updated;
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
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final galleryValue = ref.watch(cgGalleryProvider);
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
      color: AppTheme.bg,
      child: RefreshIndicator(
        onRefresh: () async {
          _resetLoadedPages();
          ref.invalidate(cgGalleryProvider);
          await ref.read(cgGalleryProvider.future);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            const AppSectionHeader(title: 'CG Gallery'),
            const SizedBox(height: 10),
            Text(
              'Watch HOK cinematics, trailers, hero videos, ratings, and comments.',
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
                hintText: 'Search CG or hero',
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
            SegmentedButton<_CgSort>(
              segments: const [
                ButtonSegment(
                  value: _CgSort.updated,
                  label: Text('Updated'),
                  icon: Icon(Icons.update),
                ),
                ButtonSegment(
                  value: _CgSort.rating,
                  label: Text('Rating'),
                  icon: Icon(Icons.star_border),
                ),
                ButtonSegment(
                  value: _CgSort.views,
                  label: Text('Views'),
                  icon: Icon(Icons.visibility_outlined),
                ),
              ],
              selected: {_sort},
              onSelectionChanged: (value) =>
                  setState(() => _sort = value.first),
            ),
            const SizedBox(height: 18),
            AppAsyncView<List<ContentItemSummary>>(
              value: galleryValue,
              retry: () => ref.invalidate(cgGalleryProvider),
              data: (items) {
                final allItems = [...items, ..._extraCgs];
                final cgs = _filterAndSort(allItems);
                if (cgs.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.movie_creation_outlined,
                    title: 'No CGs found',
                    message: 'Try another hero or title.',
                  );
                }

                return Column(
                  children: [
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
    final filtered = items
        .where((cg) {
          if (normalizedQuery.isEmpty) {
            return true;
          }
          return cg.title.toLowerCase().contains(normalizedQuery) ||
              cg.heroName.toLowerCase().contains(normalizedQuery);
        })
        .toList(growable: false);

    return [...filtered]..sort((left, right) {
      return switch (_sort) {
        _CgSort.rating => right.rating.compareTo(left.rating),
        _CgSort.views => right.viewCount.compareTo(left.viewCount),
        _CgSort.updated => right.id.compareTo(left.id),
      };
    });
  }

  void _openDetail(BuildContext context, int cgId) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppTheme.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _CgDetailSheet(cgId: cgId),
    );
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
          .loadCgs(regionId, page: _nextPage, pageSize: _cgGalleryPageSize);

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

class _CgCard extends StatelessWidget {
  const _CgCard({required this.cg, required this.onTap});

  final ContentItemSummary cg;
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
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    AppImage(
                      url: cg.imageUrl,
                      width: 104,
                      height: 68,
                      borderRadius: 12,
                      semanticLabel: cg.title,
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(
                          Icons.play_arrow,
                          color: AppTheme.gold,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        cg.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppTheme.text,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        cg.heroName.isEmpty ? 'Video' : cg.heroName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_compact(cg.viewCount)} views · ${cg.rating.toStringAsFixed(1)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppTheme.gold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
                  color: AppTheme.muted.withValues(alpha: 0.5),
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
                color: AppTheme.text,
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
        color: AppTheme.panel,
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
        Stack(
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
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.play_arrow, color: AppTheme.gold, size: 34),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
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
            _DetailChip(label: '${_compact(viewCount)} views'),
            _DetailChip(label: rating.toStringAsFixed(1)),
            _DetailChip(label: '$ratingCount ratings'),
          ],
        ),
        const SizedBox(height: 14),
        _CgRatingControl(rating: rating, isRating: isRating, onRate: onRate),
        if (detail.playUrl.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            detail.playUrl,
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

class _CgCommentCard extends StatelessWidget {
  const _CgCommentCard({required this.comment});

  final CgCommentSummary comment;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panel,
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
                      color: AppTheme.text,
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
                color: AppTheme.text,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
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
                'Rate this CG',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.text,
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

enum _CgSort { updated, rating, views }
