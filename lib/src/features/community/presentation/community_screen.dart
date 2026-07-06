import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../settings/presentation/settings_controller.dart';
import '../data/community_repository.dart';
import '../domain/community_post_summary.dart';
import '../domain/leak_post_summary.dart';

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return CommunityRepository(apiClient: ref.watch(apiClientProvider));
});

const _communityPostsPageSize = 30;
const _leakPostsPageSize = 30;

final communityPostsRegionProvider = FutureProvider<int>((ref) async {
  final settings = await ref.watch(appSettingsControllerProvider.future);
  return settings.region.regionId;
});

final communityPostsProvider = FutureProvider<List<CommunityPostSummary>>((
  ref,
) async {
  final regionId = await ref.watch(communityPostsRegionProvider.future);
  return ref
      .watch(communityRepositoryProvider)
      .loadPosts(regionId, pageSize: _communityPostsPageSize);
});

final communityPostsQueryProvider =
    FutureProvider.family<List<CommunityPostSummary>, CommunityPostsQuery>((
      ref,
      query,
    ) async {
      if (query.isDefault) {
        return ref.watch(communityPostsProvider.future);
      }
      final regionId = await ref.watch(communityPostsRegionProvider.future);
      return ref
          .watch(communityRepositoryProvider)
          .loadPosts(
            regionId,
            pageSize: _communityPostsPageSize,
            search: query.search,
            sort: query.sort,
          );
    });

final leakPostsProvider = FutureProvider<List<LeakPostSummary>>((ref) async {
  final regionId = await ref.watch(leakPostsRegionProvider.future);
  return ref
      .watch(communityRepositoryProvider)
      .loadLeaks(regionId, pageSize: _leakPostsPageSize);
});

final leakPostsRegionProvider = FutureProvider<int>((ref) async {
  final settings = await ref.watch(appSettingsControllerProvider.future);
  return settings.region.regionId;
});

class CommunityPostsQuery {
  const CommunityPostsQuery({
    this.search = '',
    this.sort = CommunityPostSort.newest,
  });

  final String search;
  final CommunityPostSort sort;

  bool get isDefault =>
      search.trim().isEmpty && sort == CommunityPostSort.newest;

  @override
  bool operator ==(Object other) {
    return other is CommunityPostsQuery &&
        other.search == search &&
        other.sort == sort;
  }

  @override
  int get hashCode => Object.hash(search, sort);
}

enum CommunityInitialView { hot, myPosts, likedPosts }

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({
    this.initialTabIndex = 0,
    this.initialView = CommunityInitialView.hot,
    this.initialLeakQuery,
    this.initialPostTag,
    super.key,
  });

  final int initialTabIndex;
  final CommunityInitialView initialView;
  final String? initialLeakQuery;
  final String? initialPostTag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      initialIndex: initialTabIndex.clamp(0, 1),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppSectionHeader(title: 'Community'),
                      const SizedBox(height: 8),
                      Text(
                        'Read hot posts and track community leak signals.',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
                      ),
                      const SizedBox(height: 16),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppTheme.panel,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const TabBar(
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          labelColor: AppTheme.gold,
                          unselectedLabelColor: AppTheme.muted,
                          tabs: [
                            Tab(text: 'Posts'),
                            Tab(text: 'Leaks'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              _PostsTab(initialView: initialView, initialTag: initialPostTag),
              _LeaksTab(
                value: ref.watch(leakPostsProvider),
                initialQuery: initialLeakQuery,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostsTab extends ConsumerStatefulWidget {
  const _PostsTab({required this.initialView, required this.initialTag});

  final CommunityInitialView initialView;
  final String? initialTag;

  @override
  ConsumerState<_PostsTab> createState() => _PostsTabState();
}

class _PostsTabState extends ConsumerState<_PostsTab> {
  final _contentController = TextEditingController();
  final _searchController = TextEditingController();
  final _titleController = TextEditingController();
  final _createdPosts = <CommunityPostSummary>[];
  final _extraPosts = <CommunityPostSummary>[];
  final _deletedPostIds = <String>{};
  var _search = '';
  var _sort = CommunityPostSort.newest;
  var _isCreateOpen = false;
  var _createSubmitting = false;
  var _nextPostsPage = 2;
  var _hasMorePosts = true;
  var _isLoadingMorePosts = false;

  @override
  void dispose() {
    _contentController.dispose();
    _searchController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(authControllerProvider).valueOrNull;
    final query = CommunityPostsQuery(search: _search, sort: _sort);
    final postsValue = ref.watch(communityPostsQueryProvider(query));
    return AppAsyncView<List<CommunityPostSummary>>(
      value: postsValue,
      retry: () => ref.invalidate(communityPostsQueryProvider(query)),
      data: (posts) {
        final tag = widget.initialTag?.trim() ?? '';
        final combinedPosts = [...posts, ..._extraPosts];
        final allPosts = _mergeCreatedPosts(combinedPosts)
            .where((post) => !_deletedPostIds.contains(post.id))
            .toList(growable: false);
        final modePosts = switch (widget.initialView) {
          CommunityInitialView.myPosts =>
            allPosts
                .where(
                  (post) => post.authorId > 0 && post.authorId == authUser?.id,
                )
                .toList(growable: false),
          CommunityInitialView.likedPosts =>
            allPosts.where((post) => post.isLiked).toList(growable: false),
          CommunityInitialView.hot => allPosts,
        };
        final visiblePosts = tag.isEmpty
            ? modePosts
            : modePosts
                  .where((post) => _matchesTag(post, tag))
                  .toList(growable: false);

        return RefreshIndicator(
          onRefresh: () async {
            _resetLoadedPages();
            return ref.refresh(communityPostsQueryProvider(query).future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              _PostSearchSortBar(
                controller: _searchController,
                search: _search,
                sort: _sort,
                onSearchChanged: (value) {
                  setState(() {
                    _search = value;
                    _resetLoadedPages();
                  });
                },
                onSortChanged: (value) {
                  setState(() {
                    _sort = value;
                    _resetLoadedPages();
                  });
                },
              ),
              const SizedBox(height: 12),
              if (widget.initialView != CommunityInitialView.likedPosts) ...[
                _CreatePostCard(
                  contentController: _contentController,
                  isExpanded: _isCreateOpen,
                  isSubmitting: _createSubmitting,
                  onExpand: () => setState(() => _isCreateOpen = true),
                  onSubmit: () => _createPost(context),
                  titleController: _titleController,
                ),
                const SizedBox(height: 12),
              ],
              if (widget.initialView == CommunityInitialView.myPosts) ...[
                const _ModePill(
                  icon: Icons.person_outline,
                  label: 'My Posts',
                  message: 'Showing posts authored by your signed-in account.',
                ),
                const SizedBox(height: 12),
              ],
              if (widget.initialView == CommunityInitialView.likedPosts) ...[
                const _ModePill(
                  icon: Icons.favorite_border,
                  label: 'Liked Posts',
                  message: 'Showing posts you liked on HOK Helper.',
                ),
                const SizedBox(height: 12),
              ],
              if (tag.isNotEmpty) ...[
                _ModePill(
                  icon: Icons.sell_outlined,
                  label: 'Tag Filter',
                  message: 'Showing posts tagged "$tag".',
                ),
                const SizedBox(height: 12),
              ],
              if (visiblePosts.isEmpty)
                _PostsEmptyState(tag: tag, initialView: widget.initialView)
              else
                for (final post in visiblePosts) ...[
                  _PostCard(
                    onDelete: widget.initialView == CommunityInitialView.myPosts
                        ? () => _deletePost(context, post.id)
                        : null,
                    post: post,
                  ),
                  const SizedBox(height: 12),
                ],
              if (_canLoadMorePosts(posts)) ...[
                const SizedBox(height: 4),
                Center(
                  child: FilledButton.icon(
                    onPressed: _isLoadingMorePosts
                        ? null
                        : () => _loadMorePosts(context),
                    icon: _isLoadingMorePosts
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.expand_more, size: 18),
                    label: Text(
                      _isLoadingMorePosts ? 'Loading...' : 'Load more',
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  bool _canLoadMorePosts(List<CommunityPostSummary> firstPagePosts) {
    return _hasMorePosts && firstPagePosts.length >= _communityPostsPageSize;
  }

  Future<void> _loadMorePosts(BuildContext context) async {
    if (_isLoadingMorePosts || !_hasMorePosts) {
      return;
    }
    setState(() => _isLoadingMorePosts = true);
    try {
      final regionId = await ref.read(communityPostsRegionProvider.future);
      final nextPosts = await ref
          .read(communityRepositoryProvider)
          .loadPosts(
            regionId,
            page: _nextPostsPage,
            pageSize: _communityPostsPageSize,
            search: _search,
            sort: _sort,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _extraPosts.addAll(nextPosts);
        _nextPostsPage += 1;
        _hasMorePosts = nextPosts.length >= _communityPostsPageSize;
        _isLoadingMorePosts = false;
      });
    } catch (_) {
      if (!mounted || !context.mounted) {
        return;
      }
      setState(() => _isLoadingMorePosts = false);
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to load more posts')),
      );
    }
  }

  void _resetLoadedPages() {
    _extraPosts.clear();
    _nextPostsPage = 2;
    _hasMorePosts = true;
    _isLoadingMorePosts = false;
  }

  Future<void> _createPost(BuildContext context) async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty || content.isEmpty) {
      return;
    }
    setState(() => _createSubmitting = true);
    try {
      final settings = await ref.read(appSettingsControllerProvider.future);
      final createdPost = await ref
          .read(communityRepositoryProvider)
          .createPost(
            title: title,
            content: content,
            tags: const ['Guide'],
            regionId: settings.region.regionId,
          );
      if (!mounted || !context.mounted) {
        return;
      }
      _titleController.clear();
      _contentController.clear();
      setState(() {
        _createdPosts.insert(0, createdPost);
        _isCreateOpen = false;
        _createSubmitting = false;
      });
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(const SnackBar(content: Text('Post created')));
    } catch (_) {
      if (!mounted || !context.mounted) {
        return;
      }
      setState(() => _createSubmitting = false);
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to create post')),
      );
    }
  }

  Future<void> _deletePost(BuildContext context, String postId) async {
    try {
      await ref.read(communityRepositoryProvider).deletePost(postId);
      if (!mounted || !context.mounted) {
        return;
      }
      setState(() {
        _deletedPostIds.add(postId);
        _createdPosts.removeWhere((post) => post.id == postId);
      });
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(const SnackBar(content: Text('Post deleted')));
    } catch (_) {
      if (!mounted || !context.mounted) {
        return;
      }
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to delete post')),
      );
    }
  }

  List<CommunityPostSummary> _mergeCreatedPosts(
    List<CommunityPostSummary> posts,
  ) {
    final existingIds = posts.map((post) => post.id).toSet();
    return [
      ..._createdPosts.where((post) => !existingIds.contains(post.id)),
      ...posts,
    ];
  }

  bool _matchesTag(CommunityPostSummary post, String tag) {
    final needle = tag.toLowerCase();
    return post.tags.any((value) => value.toLowerCase() == needle);
  }
}

class _PostSearchSortBar extends StatelessWidget {
  const _PostSearchSortBar({
    required this.controller,
    required this.search,
    required this.sort,
    required this.onSearchChanged,
    required this.onSortChanged,
  });

  final TextEditingController controller;
  final String search;
  final CommunityPostSort sort;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<CommunityPostSort> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panel,
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: controller,
              onChanged: onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                isDense: true,
                labelText: 'Search posts',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: search.trim().isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          controller.clear();
                          onSearchChanged('');
                        },
                        icon: const Icon(Icons.close, size: 18),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in CommunityPostSort.values)
                  ChoiceChip(
                    label: Text(option.label),
                    selected: sort == option,
                    onSelected: (_) => onSortChanged(option),
                    avatar: Icon(option.icon, size: 16),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

extension on CommunityPostSort {
  String get label {
    return switch (this) {
      CommunityPostSort.newest => 'Newest',
      CommunityPostSort.oldest => 'Oldest',
      CommunityPostSort.hot => 'Hot',
    };
  }

  IconData get icon {
    return switch (this) {
      CommunityPostSort.newest => Icons.fiber_new_outlined,
      CommunityPostSort.oldest => Icons.history_outlined,
      CommunityPostSort.hot => Icons.local_fire_department_outlined,
    };
  }
}

class _ModePill extends StatelessWidget {
  const _ModePill({
    required this.icon,
    required this.label,
    required this.message,
  });

  final IconData icon;
  final String label;
  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.gold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.gold, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppTheme.gold,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreatePostCard extends StatelessWidget {
  const _CreatePostCard({
    required this.contentController,
    required this.isExpanded,
    required this.isSubmitting,
    required this.onExpand,
    required this.onSubmit,
    required this.titleController,
  });

  final TextEditingController contentController;
  final bool isExpanded;
  final bool isSubmitting;
  final VoidCallback onExpand;
  final VoidCallback onSubmit;
  final TextEditingController titleController;

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
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Create Post',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.text,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (!isExpanded)
                  FilledButton.icon(
                    onPressed: onExpand,
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Create Post'),
                  ),
              ],
            ),
            if (isExpanded) ...[
              const SizedBox(height: 10),
              TextField(
                controller: titleController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Title',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: contentController,
                minLines: 3,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Content',
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const _Pill(label: 'Guide'),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: isSubmitting ? null : onSubmit,
                    icon: const Icon(Icons.send_outlined, size: 16),
                    label: const Text('Create'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PostsEmptyState extends StatelessWidget {
  const _PostsEmptyState({required this.initialView, required this.tag});

  final CommunityInitialView initialView;
  final String tag;

  @override
  Widget build(BuildContext context) {
    final title = tag.isNotEmpty
        ? 'No matching posts'
        : initialView == CommunityInitialView.myPosts
        ? 'No posts from you yet'
        : initialView == CommunityInitialView.likedPosts
        ? 'No liked posts yet'
        : 'No community posts found';
    final message = tag.isNotEmpty
        ? 'No posts matched "$tag" in this region.'
        : initialView == CommunityInitialView.myPosts
        ? 'Create a community post here or sync one on HOK Helper.'
        : initialView == CommunityInitialView.likedPosts
        ? 'Like posts on HOK Helper to collect them here.'
        : 'Pull to refresh or switch region in settings.';

    return AppEmptyState(
      icon: Icons.forum_outlined,
      title: title,
      message: message,
    );
  }
}

class _LeaksTab extends ConsumerStatefulWidget {
  const _LeaksTab({required this.value, required this.initialQuery});

  final AsyncValue<List<LeakPostSummary>> value;
  final String? initialQuery;

  @override
  ConsumerState<_LeaksTab> createState() => _LeaksTabState();
}

class _LeaksTabState extends ConsumerState<_LeaksTab> {
  final _extraLeaks = <LeakPostSummary>[];
  var _nextLeaksPage = 2;
  var _hasMoreLeaks = true;
  var _isLoadingMoreLeaks = false;

  @override
  Widget build(BuildContext context) {
    return AppAsyncView<List<LeakPostSummary>>(
      value: widget.value,
      retry: () => ref.invalidate(leakPostsProvider),
      data: (leaks) {
        final query = widget.initialQuery?.trim() ?? '';
        final allLeaks = [...leaks, ..._extraLeaks];
        final visibleLeaks = query.isEmpty
            ? allLeaks
            : allLeaks
                  .where((leak) => _matchesQuery(leak, query))
                  .toList(growable: false);

        if (visibleLeaks.isEmpty) {
          return AppEmptyState(
            icon: Icons.campaign_outlined,
            title: query.isEmpty ? 'No leaks found' : 'No matching leaks',
            message: query.isEmpty
                ? 'Pull to refresh or switch region in settings.'
                : 'No leaks matched "$query" in this region.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            _resetLoadedPages();
            return ref.refresh(leakPostsProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              if (query.isNotEmpty) ...[
                _ModePill(
                  icon: Icons.search,
                  label: 'Leak Search',
                  message: 'Showing leaks matching "$query".',
                ),
                const SizedBox(height: 12),
              ],
              for (final leak in visibleLeaks) ...[
                _LeakCard(leak: leak),
                const SizedBox(height: 12),
              ],
              if (_canLoadMoreLeaks(leaks)) ...[
                const SizedBox(height: 4),
                Center(
                  child: FilledButton.icon(
                    onPressed: _isLoadingMoreLeaks
                        ? null
                        : () => _loadMoreLeaks(context),
                    icon: _isLoadingMoreLeaks
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.expand_more, size: 18),
                    label: Text(
                      _isLoadingMoreLeaks ? 'Loading...' : 'Load more',
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  bool _matchesQuery(LeakPostSummary leak, String query) {
    final needle = query.toLowerCase();
    return [
      leak.title,
      leak.content,
      leak.category,
      leak.platform,
      leak.authorName,
      leak.authorHandle,
      ...leak.keywords,
    ].any((value) => value.toLowerCase().contains(needle));
  }

  bool _canLoadMoreLeaks(List<LeakPostSummary> firstPageLeaks) {
    return _hasMoreLeaks && firstPageLeaks.length >= _leakPostsPageSize;
  }

  Future<void> _loadMoreLeaks(BuildContext context) async {
    if (_isLoadingMoreLeaks || !_hasMoreLeaks) {
      return;
    }
    setState(() => _isLoadingMoreLeaks = true);
    try {
      final regionId = await ref.read(leakPostsRegionProvider.future);
      final nextLeaks = await ref
          .read(communityRepositoryProvider)
          .loadLeaks(
            regionId,
            page: _nextLeaksPage,
            pageSize: _leakPostsPageSize,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _extraLeaks.addAll(nextLeaks);
        _nextLeaksPage += 1;
        _hasMoreLeaks = nextLeaks.length >= _leakPostsPageSize;
        _isLoadingMoreLeaks = false;
      });
    } catch (_) {
      if (!mounted || !context.mounted) {
        return;
      }
      setState(() => _isLoadingMoreLeaks = false);
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to load more leaks')),
      );
    }
  }

  void _resetLoadedPages() {
    _extraLeaks.clear();
    _nextLeaksPage = 2;
    _hasMoreLeaks = true;
    _isLoadingMoreLeaks = false;
  }
}

class _PostCard extends ConsumerStatefulWidget {
  const _PostCard({required this.post, this.onDelete});

  final CommunityPostSummary post;
  final VoidCallback? onDelete;

  @override
  ConsumerState<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<_PostCard> {
  late var _likeCount = widget.post.likeCount;
  late var _isLiked = widget.post.isLiked;
  var _likeSubmitting = false;

  @override
  void didUpdateWidget(covariant _PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id ||
        oldWidget.post.likeCount != widget.post.likeCount ||
        oldWidget.post.isLiked != widget.post.isLiked) {
      _likeCount = widget.post.likeCount;
      _isLiked = widget.post.isLiked;
      _likeSubmitting = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.push('/content/community/post/${post.id}'),
      child: _PanelCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppImage(
                  url: post.authorAvatarUrl,
                  width: 40,
                  height: 40,
                  borderRadius: 12,
                  semanticLabel: post.authorName,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    post.authorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _Pill(label: '${post.viewCount} views'),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              post.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.text,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (post.preview.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                post.preview,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.muted,
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Pill(
                  label: '$_likeCount likes · ${post.commentCount} comments',
                ),
                OutlinedButton.icon(
                  onPressed: _likeSubmitting ? null : () => _likePost(context),
                  icon: Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    size: 16,
                  ),
                  label: const Text('Like'),
                ),
                if (widget.onDelete != null)
                  OutlinedButton.icon(
                    onPressed: widget.onDelete,
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Delete'),
                  ),
                ...post.tags.take(3).map((tag) => _Pill(label: tag)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _likePost(BuildContext context) async {
    setState(() => _likeSubmitting = true);
    try {
      final result = await ref
          .read(communityRepositoryProvider)
          .togglePostLike(widget.post.id);
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

class _LeakCard extends StatelessWidget {
  const _LeakCard({required this.leak});

  final LeakPostSummary leak;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppImage(
                url: leak.mediaUrl.isNotEmpty
                    ? leak.mediaUrl
                    : leak.authorAvatarUrl,
                width: 72,
                height: 72,
                borderRadius: 14,
                semanticLabel: leak.title,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      leak.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      leak.authorLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (leak.content.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              leak.content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.muted,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Pill(label: leak.metricText),
              _Pill(label: leak.category),
              if (leak.platform.isNotEmpty) _Pill(label: leak.platform),
              ...leak.keywords.take(3).map((keyword) => _Pill(label: keyword)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PanelCard extends StatelessWidget {
  const _PanelCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panel,
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(padding: const EdgeInsets.all(14), child: child),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panelAlt,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppTheme.text,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
