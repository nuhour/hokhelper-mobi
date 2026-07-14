import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_markdown_content.dart';
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

class CommunityPostDetailScreen extends ConsumerStatefulWidget {
  const CommunityPostDetailScreen({required this.postId, super.key});

  final String postId;

  @override
  ConsumerState<CommunityPostDetailScreen> createState() =>
      _CommunityPostDetailScreenState();
}

class _CommunityPostDetailScreenState
    extends ConsumerState<CommunityPostDetailScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postId = widget.postId;
    final detailValue = ref.watch(postDetailProvider(postId));

    return Material(
      color: AppTheme.bg,
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(postDetailProvider(postId));
          await ref.read(postDetailProvider(postId).future);
        },
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          interactive: true,
          thickness: 4,
          radius: const Radius.circular(99),
          child: ListView(
            controller: _scrollController,
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
  late var _comments = widget.detail.comments;
  late var _commentCount = widget.detail.post.commentCount;
  late var _likeCount = widget.detail.post.likeCount;
  late var _isLiked = widget.detail.isLiked || widget.detail.post.isLiked;
  final _commentController = TextEditingController();
  final _replyController = TextEditingController();
  CommunityCommentSummary? _replyTo;
  Set<String> _likedCommentIds = const {};
  _CommentSort _commentSort = _CommentSort.newest;
  var _commentSubmitting = false;
  var _replySubmitting = false;
  var _likeSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _PostDetailBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detail.post.id != widget.detail.post.id ||
        oldWidget.detail.post.commentCount != widget.detail.post.commentCount ||
        oldWidget.detail.comments != widget.detail.comments ||
        oldWidget.detail.post.likeCount != widget.detail.post.likeCount ||
        oldWidget.detail.isLiked != widget.detail.isLiked ||
        oldWidget.detail.post.isLiked != widget.detail.post.isLiked) {
      _comments = widget.detail.comments;
      _commentCount = widget.detail.post.commentCount;
      _likeCount = widget.detail.post.likeCount;
      _isLiked = widget.detail.isLiked || widget.detail.post.isLiked;
      _replyTo = null;
      _likedCommentIds = const {};
      _commentSort = _CommentSort.newest;
      _commentSubmitting = false;
      _replySubmitting = false;
      _likeSubmitting = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    final post = detail.post;
    final sortedComments = _sortedComments();

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
                          _AuthorNameButton(
                            authorId: post.authorId,
                            authorName: post.authorName,
                            textStyle: Theme.of(context).textTheme.titleSmall
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
                AppMarkdownContent(
                  content: detail.content.isNotEmpty
                      ? detail.content
                      : post.preview,
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetricChip(label: '${post.viewCount} views'),
                    _MetricChip(label: '$_likeCount likes'),
                    _MetricChip(label: '$_commentCount comments'),
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
                    OutlinedButton.icon(
                      onPressed: () => _sharePost(context),
                      icon: const Icon(Icons.ios_share_outlined, size: 16),
                      label: const Text('Share'),
                    ),
                    ...post.tags.take(4).map((tag) => _MetricChip(label: tag)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        _CommentComposer(
          controller: _commentController,
          isSubmitting: _commentSubmitting,
          hintText: 'Write a comment...',
          submitLabel: 'Post',
          onSubmit: () => _createComment(context),
        ),
        const SizedBox(height: 22),
        Text(
          'Comments',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.text,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _CommentSort.values
              .map((sort) {
                return ChoiceChip(
                  label: Text(sort.label),
                  selected: _commentSort == sort,
                  onSelected: (_) => setState(() => _commentSort = sort),
                );
              })
              .toList(growable: false),
        ),
        const SizedBox(height: 12),
        if (_replyTo != null) ...[
          _CommentComposer(
            controller: _replyController,
            isSubmitting: _replySubmitting,
            hintText: 'Reply to ${_replyTo!.authorName}...',
            submitLabel: 'Reply',
            leading: Row(
              children: [
                Expanded(
                  child: Text(
                    'Replying to ${_replyTo!.authorName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.gold,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _replyTo = null;
                      _replyController.clear();
                    });
                  },
                  child: const Text('Cancel'),
                ),
              ],
            ),
            onSubmit: () => _createReply(context),
          ),
          const SizedBox(height: 12),
        ],
        if (sortedComments.isEmpty)
          const AppEmptyState(
            icon: Icons.chat_bubble_outline,
            title: 'No comments yet',
            message: 'Be the first to join this discussion.',
          )
        else
          ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: sortedComments.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final comment = sortedComments[index];
              return _CommentCard(
                comment: comment,
                isLiked: _likedCommentIds.contains(comment.id),
                onToggleLike: () => _toggleCommentLike(comment.id),
                onReply: () {
                  setState(() {
                    _replyTo = comment;
                    _replyController.clear();
                  });
                },
              );
            },
          ),
      ],
    );
  }

  List<CommunityCommentSummary> _sortedComments() {
    final sorted = [..._comments];
    sorted.sort((a, b) {
      switch (_commentSort) {
        case _CommentSort.hot:
          final likeCompare = b.likeCount.compareTo(a.likeCount);
          if (likeCompare != 0) {
            return likeCompare;
          }
          return _compareCreatedDesc(a, b);
        case _CommentSort.oldest:
          return _compareCreatedAsc(a, b);
        case _CommentSort.newest:
          return _compareCreatedDesc(a, b);
      }
    });
    return sorted;
  }

  void _toggleCommentLike(String commentId) {
    setState(() {
      final next = Set<String>.from(_likedCommentIds);
      if (next.contains(commentId)) {
        next.remove(commentId);
      } else {
        next.add(commentId);
      }
      _likedCommentIds = next;
    });
  }

  Future<void> _createReply(BuildContext context) async {
    final parent = _replyTo;
    final content = _replyController.text.trim();
    if (parent == null || content.isEmpty) {
      return;
    }
    setState(() => _replySubmitting = true);
    try {
      final reply = await ref
          .read(communityRepositoryProvider)
          .createComment(
            widget.detail.post.id,
            content: content,
            parentId: parent.id,
          );
      if (!mounted || !context.mounted) {
        return;
      }
      _replyController.clear();
      setState(() {
        _comments = [..._comments, reply];
        _commentCount += 1;
        _replyTo = null;
        _replySubmitting = false;
      });
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(const SnackBar(content: Text('Reply posted')));
    } catch (_) {
      if (!mounted || !context.mounted) {
        return;
      }
      setState(() => _replySubmitting = false);
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to post reply')),
      );
    }
  }

  Future<void> _createComment(BuildContext context) async {
    final content = _commentController.text.trim();
    if (content.isEmpty) {
      return;
    }
    setState(() => _commentSubmitting = true);
    try {
      final comment = await ref
          .read(communityRepositoryProvider)
          .createComment(widget.detail.post.id, content: content);
      if (!mounted || !context.mounted) {
        return;
      }
      _commentController.clear();
      setState(() {
        _comments = [..._comments, comment];
        _commentCount += 1;
        _commentSubmitting = false;
      });
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(const SnackBar(content: Text('Comment posted')));
    } catch (_) {
      if (!mounted || !context.mounted) {
        return;
      }
      setState(() => _commentSubmitting = false);
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to post comment')),
      );
    }
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

  Future<void> _sharePost(BuildContext context) async {
    await Clipboard.setData(
      ClipboardData(text: '/community/post/${widget.detail.post.id}'),
    );
    if (!mounted || !context.mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(const SnackBar(content: Text('Post link copied')));
  }
}

enum _CommentSort {
  newest('Newest'),
  oldest('Oldest'),
  hot('Hot');

  const _CommentSort(this.label);

  final String label;
}

int _compareCreatedDesc(CommunityCommentSummary a, CommunityCommentSummary b) {
  return _createdMillis(b).compareTo(_createdMillis(a));
}

int _compareCreatedAsc(CommunityCommentSummary a, CommunityCommentSummary b) {
  return _createdMillis(a).compareTo(_createdMillis(b));
}

int _createdMillis(CommunityCommentSummary comment) {
  return DateTime.tryParse(comment.createdAt)?.millisecondsSinceEpoch ?? 0;
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({
    required this.comment,
    required this.isLiked,
    required this.onToggleLike,
    required this.onReply,
  });

  final CommunityCommentSummary comment;
  final bool isLiked;
  final VoidCallback onToggleLike;
  final VoidCallback onReply;

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
                  child: _AuthorNameButton(
                    authorId: comment.authorId,
                    authorName: comment.authorName,
                    textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
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
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onToggleLike,
                  icon: Icon(
                    isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                    size: 16,
                  ),
                  label: Text('${comment.likeCount + (isLiked ? 1 : 0)} likes'),
                ),
                const SizedBox(width: 6),
                TextButton.icon(
                  onPressed: onReply,
                  icon: const Icon(Icons.reply_outlined, size: 16),
                  label: const Text('Reply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthorNameButton extends StatelessWidget {
  const _AuthorNameButton({
    required this.authorId,
    required this.authorName,
    required this.textStyle,
  });

  final int authorId;
  final String authorName;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    if (authorId <= 0) {
      return Text(
        authorName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: textStyle,
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: () => context.go('/profile/$authorId'),
        style: TextButton.styleFrom(
          foregroundColor: AppTheme.text,
          minimumSize: Size.zero,
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: textStyle,
        ),
        child: Text(authorName, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class _CommentComposer extends StatelessWidget {
  const _CommentComposer({
    required this.controller,
    required this.isSubmitting,
    required this.hintText,
    required this.submitLabel,
    required this.onSubmit,
    this.leading,
  });

  final TextEditingController controller;
  final bool isSubmitting;
  final String hintText;
  final String submitLabel;
  final VoidCallback onSubmit;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panel,
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (leading != null) ...[leading!, const SizedBox(height: 8)],
            TextField(
              controller: controller,
              minLines: 2,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: hintText,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: isSubmitting ? null : onSubmit,
                icon: const Icon(Icons.send_outlined, size: 16),
                label: Text(submitLabel),
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
