import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../settings/presentation/settings_controller.dart';
import '../domain/community_post_detail.dart';
import 'community_screen.dart';

final postDetailProvider = FutureProvider.family<CommunityPostDetail, String>((
  ref,
  postId,
) async {
  final settings = await ref.watch(appSettingsControllerProvider.future);
  return ref
      .watch(communityRepositoryProvider)
      .loadPostDetail(postId, regionId: settings.region.regionId);
});

class CommunityPostDetailScreen extends ConsumerWidget {
  const CommunityPostDetailScreen({required this.postId, super.key});

  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailValue = ref.watch(postDetailProvider(postId));

    return Material(
      color: AppTheme.bg,
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(postDetailProvider(postId));
          await ref.read(postDetailProvider(postId).future);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            const AppSectionHeader(title: 'Post Detail'),
            const SizedBox(height: 16),
            AppAsyncView<CommunityPostDetail>(
              value: detailValue,
              retry: () => ref.invalidate(postDetailProvider(postId)),
              data: (detail) {
                return _PostDetailBody(detail: detail);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PostDetailBody extends ConsumerStatefulWidget {
  const _PostDetailBody({required this.detail});

  final CommunityPostDetail detail;

  @override
  ConsumerState<_PostDetailBody> createState() => _PostDetailBodyState();
}

class _PostDetailBodyState extends ConsumerState<_PostDetailBody> {
  late var _likeCount = widget.detail.post.likeCount;
  late var _isLiked = widget.detail.isLiked || widget.detail.post.isLiked;
  var _likeSubmitting = false;

  @override
  void didUpdateWidget(covariant _PostDetailBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detail.post.id != widget.detail.post.id ||
        oldWidget.detail.post.likeCount != widget.detail.post.likeCount ||
        oldWidget.detail.isLiked != widget.detail.isLiked ||
        oldWidget.detail.post.isLiked != widget.detail.post.isLiked) {
      _likeCount = widget.detail.post.likeCount;
      _isLiked = widget.detail.isLiked || widget.detail.post.isLiked;
      _likeSubmitting = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    final post = detail.post;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.panel,
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppImage(
                      url: post.authorAvatarUrl,
                      width: 44,
                      height: 44,
                      borderRadius: 14,
                      semanticLabel: post.authorName,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            post.authorName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: AppTheme.text,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          if (post.createdAt.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              _formatTime(post.createdAt),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppTheme.muted),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  post.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  detail.content.isNotEmpty ? detail.content : post.preview,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.text,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetricChip(label: '${post.viewCount} views'),
                    _MetricChip(label: '$_likeCount likes'),
                    _MetricChip(label: '${post.commentCount} comments'),
                    if (_isLiked) const _MetricChip(label: 'Liked'),
                    OutlinedButton.icon(
                      onPressed: _likeSubmitting
                          ? null
                          : () => _likePost(context),
                      icon: Icon(
                        _isLiked ? Icons.favorite : Icons.favorite_border,
                        size: 16,
                      ),
                      label: const Text('Like'),
                    ),
                    ...post.tags.take(4).map((tag) => _MetricChip(label: tag)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Comments',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.text,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        if (detail.comments.isEmpty)
          const AppEmptyState(
            icon: Icons.chat_bubble_outline,
            title: 'No comments yet',
            message: 'Be the first to join this discussion on web.',
          )
        else
          ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: detail.comments.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              return _CommentCard(comment: detail.comments[index]);
            },
          ),
      ],
    );
  }

  Future<void> _likePost(BuildContext context) async {
    setState(() => _likeSubmitting = true);
    try {
      final result = await ref
          .read(communityRepositoryProvider)
          .togglePostLike(widget.detail.post.id);
      if (!mounted || !context.mounted) {
        return;
      }
      setState(() {
        _isLiked = result.isLiked;
        _likeCount = result.likeCount;
        _likeSubmitting = false;
      });
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text(result.isLiked ? 'Post liked' : 'Post unliked')),
      );
    } catch (_) {
      if (!mounted || !context.mounted) {
        return;
      }
      setState(() => _likeSubmitting = false);
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to like post')),
      );
    }
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({required this.comment});

  final CommunityCommentSummary comment;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: comment.parentId.isEmpty ? AppTheme.panel : AppTheme.panelAlt,
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppImage(
                  url: comment.authorAvatarUrl,
                  width: 34,
                  height: 34,
                  borderRadius: 12,
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
                if (comment.likeCount > 0)
                  _MetricChip(label: '${comment.likeCount} likes'),
              ],
            ),
            if (comment.parentAuthorName.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Reply to ${comment.parentAuthorName}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.gold),
              ),
            ],
            const SizedBox(height: 10),
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

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

String _formatTime(String value) {
  return value.replaceFirst('T', ' ').replaceFirst(RegExp(r'\.\d+Z?$'), '');
}
