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

final cgGalleryProvider = FutureProvider<List<ContentItemSummary>>((ref) async {
  final settings = await ref.watch(appSettingsControllerProvider.future);
  return ref
      .watch(contentRepositoryProvider)
      .loadCgs(settings.region.regionId, pageSize: 60);
});

final cgDetailProvider = FutureProvider.family<CgDetail, int>((ref, cgId) {
  return ref.watch(contentRepositoryProvider).loadCgDetail(cgId);
});

final cgCommentsProvider = FutureProvider.family<List<CgCommentSummary>, int>((
  ref,
  cgId,
) {
  return ref.watch(contentRepositoryProvider).loadCgComments(cgId);
});

class CgGalleryScreen extends ConsumerStatefulWidget {
  const CgGalleryScreen({this.initialCgId, super.key});

  final int? initialCgId;

  @override
  ConsumerState<CgGalleryScreen> createState() => _CgGalleryScreenState();
}

class _CgGalleryScreenState extends ConsumerState<CgGalleryScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  _CgSort _sort = _CgSort.updated;
  int? _openedInitialCgId;

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
                final cgs = _filterAndSort(items);
                if (cgs.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.movie_creation_outlined,
                    title: 'No CGs found',
                    message: 'Try another hero or title.',
                  );
                }

                return ListView.separated(
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

class _CgDetailSheet extends ConsumerWidget {
  const _CgDetailSheet({required this.cgId});

  final int cgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailValue = ref.watch(cgDetailProvider(cgId));
    final commentsValue = ref.watch(cgCommentsProvider(cgId));

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
              retry: () => ref.invalidate(cgDetailProvider(cgId)),
              data: (detail) => _CgDetailContent(detail: detail),
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
            AppAsyncView<List<CgCommentSummary>>(
              value: commentsValue,
              retry: () => ref.invalidate(cgCommentsProvider(cgId)),
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
}

class _CgDetailContent extends StatelessWidget {
  const _CgDetailContent({required this.detail});

  final CgDetail detail;

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
            _DetailChip(label: '${_compact(detail.viewCount)} views'),
            _DetailChip(label: detail.rating.toStringAsFixed(1)),
            _DetailChip(label: '${detail.ratingCount} ratings'),
          ],
        ),
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
