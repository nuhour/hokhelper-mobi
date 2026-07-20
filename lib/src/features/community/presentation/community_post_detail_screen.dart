import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatters/app_time_formatter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_markdown_content.dart';
import '../../../core/widgets/app_share_sheet.dart';
import '../../settings/presentation/settings_controller.dart';
import '../domain/community_post_detail.dart';
import '../domain/community_sticker.dart';
import 'community_composer_assets.dart';
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
    final detailValue = ref.watch(postDetailProvider(widget.postId));
    return Material(
      color: context.hokTheme.backgroundDeep,
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(postDetailProvider(widget.postId));
          await ref.read(postDetailProvider(widget.postId).future);
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
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
            children: [
              AppAsyncView<CommunityPostDetail>(
                value: detailValue,
                retry: () => ref.invalidate(postDetailProvider(widget.postId)),
                data: (detail) => _PostDetailBody(detail: detail),
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
  final _commentController = TextEditingController();
  final _replyController = TextEditingController();
  late var _comments = widget.detail.comments;
  late var _commentCount = widget.detail.post.commentCount;
  late var _likeCount = widget.detail.post.likeCount;
  late var _isLiked = widget.detail.isLiked || widget.detail.post.isLiked;
  final _likedCommentIds = <String>{};
  _CommentSort _commentSort = _CommentSort.newest;
  CommunityCommentSummary? _replyTo;
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
    if (oldWidget.detail != widget.detail) {
      _comments = widget.detail.comments;
      _commentCount = widget.detail.post.commentCount;
      _likeCount = widget.detail.post.likeCount;
      _isLiked = widget.detail.isLiked || widget.detail.post.isLiked;
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.detail.post;
    final commentTree = _buildCommentTree(_comments, _commentSort);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Back',
              onPressed: () => context.canPop()
                  ? context.pop()
                  : context.go('/content/community'),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            ),
            Expanded(
              child: Text(
                'Post',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: context.hokTheme.onSurfaceStrong,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Share post',
              onPressed: () => _sharePost(context),
              icon: const Icon(Icons.ios_share_rounded, size: 21),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _ArticleCard(
          detail: widget.detail,
          likeCount: _likeCount,
          commentCount: _commentCount,
          isLiked: _isLiked,
          likeSubmitting: _likeSubmitting,
          onLike: () => _likePost(context),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(
                    'Comments',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: context.hokTheme.onSurfaceStrong,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$_commentCount',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: context.hokTheme.onSurfaceMuted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 4,
              children: _CommentSort.values
                  .map(
                    (sort) => ChoiceChip(
                      label: Text(sort.label),
                      selected: _commentSort == sort,
                      visualDensity: VisualDensity.compact,
                      onSelected: (_) => setState(() => _commentSort = sort),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _CommentComposer(
          controller: _commentController,
          isSubmitting: _commentSubmitting,
          hintText: 'Join the discussion...',
          submitLabel: 'Post',
          loadStickers: _loadStickers,
          onSubmit: () => _createComment(context),
        ),
        const SizedBox(height: 18),
        if (commentTree.isEmpty)
          const AppEmptyState(
            icon: Icons.chat_bubble_outline,
            title: 'No comments yet',
            message: 'Be the first to join this discussion.',
          )
        else
          for (final node in commentTree)
            _CommentThread(
              node: node,
              depth: 0,
              likedCommentIds: _likedCommentIds,
              replyTo: _replyTo,
              replyController: _replyController,
              replySubmitting: _replySubmitting,
              loadStickers: _loadStickers,
              onLike: _toggleCommentLike,
              onReply: (comment) {
                setState(() {
                  _replyTo = _replyTo?.id == comment.id ? null : comment;
                  _replyController.clear();
                });
              },
              onSubmitReply: () => _createReply(context),
            ),
      ],
    );
  }

  Future<List<CommunitySticker>> _loadStickers() async {
    final settings = await ref.read(appSettingsControllerProvider.future);
    return ref
        .read(communityRepositoryProvider)
        .loadStickers(settings.region.regionId);
  }

  void _toggleCommentLike(String commentId) {
    setState(() {
      if (!_likedCommentIds.remove(commentId)) _likedCommentIds.add(commentId);
    });
  }

  Future<void> _createComment(BuildContext context) async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;
    setState(() => _commentSubmitting = true);
    try {
      final comment = await ref
          .read(communityRepositoryProvider)
          .createComment(widget.detail.post.id, content: content);
      if (!mounted || !context.mounted) return;
      setState(() {
        _comments = [comment, ..._comments];
        _commentCount += 1;
        _commentSubmitting = false;
        _commentController.clear();
      });
      ref.invalidate(communityPostsProvider);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Comment posted')));
    } catch (_) {
      if (!mounted) return;
      setState(() => _commentSubmitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to post comment')));
    }
  }

  Future<void> _createReply(BuildContext context) async {
    final parent = _replyTo;
    final content = _replyController.text.trim();
    if (parent == null || content.isEmpty) return;
    setState(() => _replySubmitting = true);
    try {
      final reply = await ref
          .read(communityRepositoryProvider)
          .createComment(
            widget.detail.post.id,
            content: content,
            parentId: parent.id,
          );
      if (!mounted || !context.mounted) return;
      setState(() {
        _comments = [..._comments, reply];
        _commentCount += 1;
        _replySubmitting = false;
        _replyTo = null;
        _replyController.clear();
      });
      ref.invalidate(communityPostsProvider);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Reply posted')));
    } catch (_) {
      if (!mounted) return;
      setState(() => _replySubmitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to post reply')));
    }
  }

  Future<void> _likePost(BuildContext context) async {
    setState(() => _likeSubmitting = true);
    try {
      final result = await ref
          .read(communityRepositoryProvider)
          .togglePostLike(widget.detail.post.id);
      if (!mounted || !context.mounted) return;
      setState(() {
        _isLiked = result.isLiked;
        _likeCount = result.likeCount;
        _likeSubmitting = false;
      });
      ref.invalidate(communityPostsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.isLiked ? 'Post liked' : 'Post unliked')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _likeSubmitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to like post')));
    }
  }

  Future<void> _sharePost(BuildContext context) {
    return showAppShareSheet(
      context,
      title: widget.detail.post.title,
      url: 'https://hokhelper.com/community/post/${widget.detail.post.id}',
    );
  }
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({
    required this.detail,
    required this.likeCount,
    required this.commentCount,
    required this.isLiked,
    required this.likeSubmitting,
    required this.onLike,
  });

  final CommunityPostDetail detail;
  final int likeCount;
  final int commentCount;
  final bool isLiked;
  final bool likeSubmitting;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    final post = detail.post;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.hokTheme.surfaceSlate,
        border: Border.all(color: context.hokTheme.outlineSoft),
        borderRadius: BorderRadius.circular(16),
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
                  width: 42,
                  height: 42,
                  borderRadius: 13,
                  semanticLabel: post.authorName,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _AuthorNameButton(
                        authorId: post.authorId,
                        authorName: post.authorName,
                        textStyle: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(
                              color: context.hokTheme.onSurfaceStrong,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      Text(
                        AppTimeFormatter.relative(context, post.createdAt),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: context.hokTheme.onSurfaceMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              post.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: context.hokTheme.onSurfaceStrong,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            AppMarkdownContent(
              content: detail.content.isNotEmpty
                  ? detail.content
                  : post.preview,
            ),
            if (post.tags.isNotEmpty) ...[
              const SizedBox(height: 18),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: post.tags
                    .map((tag) => _TagChip(label: '#$tag'))
                    .toList(growable: false),
              ),
            ],
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                _ArticleMetric(
                  icon: Icons.visibility_outlined,
                  value: post.viewCount,
                  label: 'views',
                ),
                const SizedBox(width: 18),
                _ArticleMetric(
                  icon: Icons.chat_bubble_outline_rounded,
                  value: commentCount,
                  label: 'comments',
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: likeSubmitting ? null : onLike,
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked
                        ? const Color(0xFFF43F5E)
                        : context.hokTheme.onSurfaceMuted,
                    size: 19,
                  ),
                  label: Text('$likeCount likes'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentNode {
  _CommentNode(this.comment);

  final CommunityCommentSummary comment;
  final List<_CommentNode> children = [];
}

List<_CommentNode> _buildCommentTree(
  List<CommunityCommentSummary> comments,
  _CommentSort sort,
) {
  final nodes = {
    for (final comment in comments) comment.id: _CommentNode(comment),
  };
  final roots = <_CommentNode>[];
  for (final node in nodes.values) {
    final parent = nodes[node.comment.parentId];
    if (parent == null || parent == node) {
      roots.add(node);
    } else {
      parent.children.add(node);
    }
  }
  int compare(_CommentNode a, _CommentNode b) {
    if (sort == _CommentSort.hot) {
      final likes = b.comment.likeCount.compareTo(a.comment.likeCount);
      if (likes != 0) return likes;
    }
    final aTime =
        DateTime.tryParse(a.comment.createdAt)?.millisecondsSinceEpoch ?? 0;
    final bTime =
        DateTime.tryParse(b.comment.createdAt)?.millisecondsSinceEpoch ?? 0;
    return sort == _CommentSort.oldest
        ? aTime.compareTo(bTime)
        : bTime.compareTo(aTime);
  }

  void sortNodes(List<_CommentNode> values) {
    values.sort(compare);
    for (final value in values) {
      sortNodes(value.children);
    }
  }

  sortNodes(roots);
  return roots;
}

class _CommentThread extends StatelessWidget {
  const _CommentThread({
    required this.node,
    required this.depth,
    required this.likedCommentIds,
    required this.replyTo,
    required this.replyController,
    required this.replySubmitting,
    required this.loadStickers,
    required this.onLike,
    required this.onReply,
    required this.onSubmitReply,
  });

  final _CommentNode node;
  final int depth;
  final Set<String> likedCommentIds;
  final CommunityCommentSummary? replyTo;
  final TextEditingController replyController;
  final bool replySubmitting;
  final Future<List<CommunitySticker>> Function() loadStickers;
  final ValueChanged<String> onLike;
  final ValueChanged<CommunityCommentSummary> onReply;
  final VoidCallback onSubmitReply;

  @override
  Widget build(BuildContext context) {
    final comment = node.comment;
    final clampedDepth = depth.clamp(0, 2);
    final liked = likedCommentIds.contains(comment.id);
    return Padding(
      padding: EdgeInsets.only(left: clampedDepth * 18, bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: depth == 0
              ? context.hokTheme.surfaceSlate
              : context.hokTheme.surfaceRaised,
          border: Border.all(color: context.hokTheme.outlineSoft),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Stack(
          children: [
            if (depth > 0)
              Positioned(
                left: 0,
                top: 12,
                bottom: 12,
                child: Container(
                  width: 2,
                  decoration: BoxDecoration(
                    color: AppTheme.gold,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      AppImage(
                        url: comment.authorAvatarUrl,
                        width: depth == 0 ? 34 : 28,
                        height: depth == 0 ? 34 : 28,
                        borderRadius: 10,
                        semanticLabel: comment.authorName,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: _AuthorNameButton(
                          authorId: comment.authorId,
                          authorName: comment.authorName,
                          textStyle: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: context.hokTheme.onSurfaceStrong,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      Text(
                        AppTimeFormatter.relative(context, comment.createdAt),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: context.hokTheme.onSurfaceMuted,
                        ),
                      ),
                    ],
                  ),
                  if (comment.parentAuthorName.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Text(
                      'Reply to ${comment.parentAuthorName}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.gold,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 9),
                  AppMarkdownContent(content: comment.content),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => onLike(comment.id),
                        icon: Icon(
                          liked ? Icons.thumb_up : Icons.thumb_up_outlined,
                          size: 15,
                        ),
                        label: Text(
                          '${comment.likeCount + (liked ? 1 : 0)} likes',
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => onReply(comment),
                        icon: const Icon(Icons.reply_rounded, size: 16),
                        label: const Text('Reply'),
                      ),
                    ],
                  ),
                  if (replyTo?.id == comment.id) ...[
                    const SizedBox(height: 8),
                    _CommentComposer(
                      controller: replyController,
                      isSubmitting: replySubmitting,
                      hintText: 'Reply to ${comment.authorName}...',
                      submitLabel: 'Reply',
                      compact: true,
                      loadStickers: loadStickers,
                      onSubmit: onSubmitReply,
                    ),
                  ],
                  if (node.children.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    for (final child in node.children)
                      _CommentThread(
                        node: child,
                        depth: depth + 1,
                        likedCommentIds: likedCommentIds,
                        replyTo: replyTo,
                        replyController: replyController,
                        replySubmitting: replySubmitting,
                        loadStickers: loadStickers,
                        onLike: onLike,
                        onReply: onReply,
                        onSubmitReply: onSubmitReply,
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
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
    required this.loadStickers,
    required this.onSubmit,
    this.compact = false,
  });

  final TextEditingController controller;
  final bool isSubmitting;
  final String hintText;
  final String submitLabel;
  final Future<List<CommunitySticker>> Function() loadStickers;
  final VoidCallback onSubmit;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.hokTheme.surfaceSlate,
        border: Border.all(color: context.hokTheme.outlineSoft),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 10 : 12),
        child: Column(
          children: [
            TextField(
              controller: controller,
              minLines: compact ? 1 : 2,
              maxLines: 5,
              decoration: InputDecoration(hintText: hintText),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: CommunityComposerAssets(
                    controller: controller,
                    loadStickers: loadStickers,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: isSubmitting ? null : onSubmit,
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: Text(submitLabel),
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
        overflow: TextOverflow.ellipsis,
        style: textStyle,
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: () => context.push('/profile/$authorId'),
        style: TextButton.styleFrom(
          minimumSize: Size.zero,
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: textStyle,
        ),
        child: Text(authorName, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.hokTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.hokTheme.outlineSoft),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: context.hokTheme.onSurfaceMuted,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ArticleMetric extends StatelessWidget {
  const _ArticleMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: context.hokTheme.onSurfaceMuted, size: 18),
        const SizedBox(width: 5),
        Text(
          '$value $label',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: context.hokTheme.onSurfaceMuted,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

enum _CommentSort {
  newest('Newest'),
  oldest('Oldest'),
  hot('Hot');

  const _CommentSort(this.label);
  final String label;
}
