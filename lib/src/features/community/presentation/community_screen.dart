import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/formatters/app_time_formatter.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_video_player_sheet.dart';
import '../../activity/presentation/event_assistance_screen.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../settings/presentation/settings_controller.dart';
import '../data/community_repository.dart';
import '../domain/community_post_summary.dart';
import '../domain/leak_post_summary.dart';
import '../domain/community_sticker.dart';
import 'community_composer_assets.dart';

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return CommunityRepository(apiClient: ref.watch(apiClientProvider));
});

const _communityPostsPageSize = 30;
const _leakPostsPageSize = 30;
const _recommendedPostTags = [
  'Ranked Tips',
  'Hero Matchups',
  'Patch Meta',
  'Item Build Ideas',
  'Team Comp',
  'Jungle Pathing',
  'Lane Tricks',
  'Teamfight Review',
  'Esports Watch',
  'Squad Finder',
];

final communityPostsRegionProvider = FutureProvider<int>((ref) async {
  final settings = await ref.watch(appSettingsControllerProvider.future);
  return settings.region.regionId;
});

final communityPostTagsProvider = FutureProvider<List<String>>((ref) async {
  final regionId = await ref.watch(communityPostsRegionProvider.future);
  return ref.watch(communityRepositoryProvider).loadPostTags(regionId);
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
            tag: query.tag,
            sort: query.sort,
          );
    });

final leakPostsProvider = FutureProvider<List<LeakPostSummary>>((ref) async {
  final regionId = await ref.watch(leakPostsRegionProvider.future);
  return ref
      .watch(communityRepositoryProvider)
      .loadLeaks(regionId, pageSize: _leakPostsPageSize);
});

final leakPostsQueryProvider =
    FutureProvider.family<List<LeakPostSummary>, LeakPostsQuery>((
      ref,
      query,
    ) async {
      if (query.isDefault) {
        return ref.watch(leakPostsProvider.future);
      }
      final regionId = await ref.watch(leakPostsRegionProvider.future);
      return ref
          .watch(communityRepositoryProvider)
          .loadLeaks(
            regionId,
            pageSize: _leakPostsPageSize,
            category: query.category,
            platform: query.platform,
          );
    });

final leakPostsRegionProvider = FutureProvider<int>((ref) async {
  final settings = await ref.watch(appSettingsControllerProvider.future);
  return settings.region.regionId;
});

class LeakPostsQuery {
  const LeakPostsQuery({this.category = 'all', this.platform = 'all'});

  final String category;
  final String platform;

  bool get isDefault => category == 'all' && platform == 'all';

  @override
  bool operator ==(Object other) {
    return other is LeakPostsQuery &&
        other.category == category &&
        other.platform == platform;
  }

  @override
  int get hashCode => Object.hash(category, platform);
}

class CommunityPostsQuery {
  const CommunityPostsQuery({
    this.search = '',
    this.tag = '',
    this.sort = CommunityPostSort.newest,
  });

  final String search;
  final String tag;
  final CommunityPostSort sort;

  bool get isDefault =>
      search.trim().isEmpty &&
      tag.trim().isEmpty &&
      sort == CommunityPostSort.newest;

  @override
  bool operator ==(Object other) {
    return other is CommunityPostsQuery &&
        other.search == search &&
        other.tag == tag &&
        other.sort == sort;
  }

  @override
  int get hashCode => Object.hash(search, tag, sort);
}

enum CommunityInitialView { hot, myPosts, likedPosts }

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({
    this.initialTabIndex = 1,
    this.initialView = CommunityInitialView.hot,
    this.initialLeakQuery,
    this.initialLeakCategory,
    this.initialLeakPlatform,
    this.initialPostTag,
    super.key,
  });

  final int initialTabIndex;
  final CommunityInitialView initialView;
  final String? initialLeakQuery;
  final String? initialLeakCategory;
  final String? initialLeakPlatform;
  final String? initialPostTag;

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  late final PageController _pageController;
  late int _selectedPage;

  @override
  void initState() {
    super.initState();
    _selectedPage = widget.initialTabIndex.clamp(0, 2);
    _pageController = PageController(initialPage: _selectedPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _selectPage(int index) {
    if (_selectedPage != index) {
      setState(() {
        _selectedPage = index;
      });
    }
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
    _syncCommunityRoute(index);
  }

  void _syncCommunityRoute(int index) {
    try {
      final router = GoRouter.of(context);
      final location = switch (index) {
        0 => '/content/community?tab=leaks',
        2 => '/content/community?tab=events',
        _ => '/content/community',
      };
      if (router.routeInformationProvider.value.uri.toString() != location) {
        router.go(location);
      }
    } catch (_) {
      // CommunityScreen is also rendered directly in widget tests/previews.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: _CommunityTopTabs(
              selectedIndex: _selectedPage,
              onSelected: _selectPage,
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              allowImplicitScrolling: true,
              onPageChanged: (index) {
                final changed = index != _selectedPage;
                setState(() {
                  _selectedPage = index;
                });
                if (changed) _syncCommunityRoute(index);
              },
              children: [
                _LeaksTab(
                  initialQuery: widget.initialLeakQuery,
                  initialCategory: widget.initialLeakCategory,
                  initialPlatform: widget.initialLeakPlatform,
                ),
                _PostsTab(
                  initialView: widget.initialView,
                  initialTag: widget.initialPostTag,
                ),
                const EventAssistanceScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityTopTabs extends StatelessWidget {
  const _CommunityTopTabs({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = [
      l10n.communityTabLeaks,
      l10n.communityTabForum,
      l10n.communityTabEvents,
    ];

    return Center(
      child: SingleChildScrollView(
        key: const ValueKey('community-top-tab-strip'),
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < labels.length; index++) ...[
              _CommunityTabButton(
                index: index,
                label: labels[index],
                selected: index == selectedIndex,
                onTap: () => onSelected(index),
              ),
              if (index != labels.length - 1) const SizedBox(width: 24),
            ],
          ],
        ),
      ),
    );
  }
}

class _CommunityTabButton extends StatelessWidget {
  const _CommunityTabButton({
    required this.index,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final int index;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: selected ? AppTheme.text : AppTheme.muted,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            AnimatedContainer(
              key: selected
                  ? ValueKey('community-top-tab-indicator-$index')
                  : null,
              duration: const Duration(milliseconds: 180),
              width: selected ? 20 : 0,
              height: 3,
              decoration: BoxDecoration(
                color: AppTheme.gold,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
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
  final _customTagController = TextEditingController();
  final _searchController = TextEditingController();
  final _titleController = TextEditingController();
  final _createdPosts = <CommunityPostSummary>[];
  final _extraPosts = <CommunityPostSummary>[];
  final _deletedPostIds = <String>{};
  final _createdPostIds = <String>{};
  final _likedPostIds = <String>{};
  final _unlikedPostIds = <String>{};
  final _selectedPostTags = <String>{_recommendedPostTags.first};
  var _search = '';
  var _sort = CommunityPostSort.newest;
  var _createSubmitting = false;
  var _nextPostsPage = 2;
  var _hasMorePosts = true;
  var _isLoadingMorePosts = false;
  late CommunityInitialView _activeView;
  late String _activeTag;

  @override
  void initState() {
    super.initState();
    _activeView = widget.initialView;
    _activeTag = widget.initialTag?.trim() ?? '';
  }

  @override
  void dispose() {
    _contentController.dispose();
    _customTagController.dispose();
    _searchController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(authControllerProvider).valueOrNull;
    final tag = _activeTag;
    final query = CommunityPostsQuery(search: _search, tag: tag, sort: _sort);
    final postsValue = ref.watch(communityPostsQueryProvider(query));
    final tags = ref.watch(communityPostTagsProvider).valueOrNull ?? const [];
    return AppAsyncView<List<CommunityPostSummary>>(
      value: postsValue,
      retry: () => ref.invalidate(communityPostsQueryProvider(query)),
      loadingStyle: AppAsyncLoadingStyle.list,
      data: (posts) {
        final combinedPosts = [...posts, ..._extraPosts];
        final allPosts = _mergeCreatedPosts(combinedPosts)
            .where((post) => !_deletedPostIds.contains(post.id))
            .toList(growable: false);
        final modePosts = switch (_activeView) {
          CommunityInitialView.myPosts =>
            allPosts
                .where(
                  (post) =>
                      _createdPostIds.contains(post.id) ||
                      (post.authorId > 0 && post.authorId == authUser?.id),
                )
                .toList(growable: false),
          CommunityInitialView.likedPosts =>
            allPosts
                .where(
                  (post) =>
                      !_unlikedPostIds.contains(post.id) &&
                      (post.isLiked || _likedPostIds.contains(post.id)),
                )
                .toList(growable: false),
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
            key: const ValueKey('community-posts-scroll-view'),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              _PostSearchSortBar(
                controller: _searchController,
                search: _search,
                sort: _sort,
                activeTag: tag,
                activeView: _activeView,
                tags: tags,
                onCreate: () => _showCreatePostSheet(context),
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
                onTagChanged: (value) {
                  setState(() {
                    _activeTag = value;
                    _resetLoadedPages();
                  });
                },
                onViewChanged: (value) {
                  if (value != CommunityInitialView.hot && authUser == null) {
                    context.push('/login');
                    return;
                  }
                  setState(() => _activeView = value);
                },
              ),
              const SizedBox(height: 12),
              if (_activeView == CommunityInitialView.myPosts) ...[
                const _ModePill(
                  icon: Icons.person_outline,
                  label: 'My Posts',
                  message: 'Showing posts authored by your signed-in account.',
                ),
                const SizedBox(height: 12),
              ],
              if (_activeView == CommunityInitialView.likedPosts) ...[
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
                _PostsEmptyState(tag: tag, initialView: _activeView)
              else
                for (final post in visiblePosts) ...[
                  _PostCard(
                    onDelete: _activeView == CommunityInitialView.myPosts
                        ? () => _deletePost(context, post.id)
                        : null,
                    post: post,
                    onLikeChanged: (liked) {
                      setState(() {
                        if (liked) {
                          _likedPostIds.add(post.id);
                          _unlikedPostIds.remove(post.id);
                        } else {
                          _unlikedPostIds.add(post.id);
                          _likedPostIds.remove(post.id);
                        }
                      });
                    },
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
            tag: _activeTag,
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

  Future<bool> _createPost(BuildContext context) async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty || content.isEmpty) {
      return false;
    }
    setState(() => _createSubmitting = true);
    try {
      final settings = await ref.read(appSettingsControllerProvider.future);
      final createdPost = await ref
          .read(communityRepositoryProvider)
          .createPost(
            title: title,
            content: content,
            tags: _selectedPostTags.isEmpty
                ? [_recommendedPostTags.first]
                : _selectedPostTags.toList(growable: false),
            regionId: settings.region.regionId,
          );
      if (!mounted || !context.mounted) {
        return false;
      }
      _titleController.clear();
      _contentController.clear();
      _customTagController.clear();
      setState(() {
        _createdPosts.insert(0, createdPost);
        _createdPostIds.add(createdPost.id);
        _createSubmitting = false;
        _selectedPostTags
          ..clear()
          ..add(_recommendedPostTags.first);
      });
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(const SnackBar(content: Text('Post created')));
      return true;
    } catch (_) {
      if (!mounted || !context.mounted) {
        return false;
      }
      setState(() => _createSubmitting = false);
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to create post')),
      );
      return false;
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

  void _togglePostTag(String tag) {
    setState(() {
      if (_selectedPostTags.contains(tag)) {
        _selectedPostTags.remove(tag);
      } else {
        _selectedPostTags.add(tag);
      }
      if (_selectedPostTags.isEmpty) {
        _selectedPostTags.add(_recommendedPostTags.first);
      }
    });
  }

  void _addCustomTag() {
    final tag = _customTagController.text.trim();
    if (tag.isEmpty) {
      return;
    }
    setState(() {
      _selectedPostTags.add(tag);
      _customTagController.clear();
    });
  }

  Future<void> _showCreatePostSheet(BuildContext context) async {
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) {
      context.push('/login');
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 12,
                right: 12,
                bottom: MediaQuery.viewInsetsOf(context).bottom + 12,
              ),
              child: SafeArea(
                top: false,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.82,
                  ),
                  child: SingleChildScrollView(
                    child: _CreatePostCard(
                      contentController: _contentController,
                      customTagController: _customTagController,
                      isExpanded: true,
                      isSubmitting: _createSubmitting,
                      onExpand: () {},
                      onCustomTagAdd: () {
                        _addCustomTag();
                        setSheetState(() {});
                      },
                      onSubmit: () async {
                        final created = await _createPost(context);
                        if (mounted && created && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      onTagToggled: (tag) {
                        _togglePostTag(tag);
                        setSheetState(() {});
                      },
                      selectedTags: _selectedPostTags,
                      titleController: _titleController,
                      loadStickers: _loadStickers,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<List<CommunitySticker>> _loadStickers() async {
    final regionId = await ref.read(communityPostsRegionProvider.future);
    return ref.read(communityRepositoryProvider).loadStickers(regionId);
  }
}

class _PostSearchSortBar extends StatelessWidget {
  const _PostSearchSortBar({
    required this.controller,
    required this.search,
    required this.sort,
    required this.activeTag,
    required this.activeView,
    required this.tags,
    required this.onCreate,
    required this.onSearchChanged,
    required this.onSortChanged,
    required this.onTagChanged,
    required this.onViewChanged,
  });

  final TextEditingController controller;
  final String search;
  final CommunityPostSort sort;
  final String activeTag;
  final CommunityInitialView activeView;
  final List<String> tags;
  final VoidCallback onCreate;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<CommunityPostSort> onSortChanged;
  final ValueChanged<String> onTagChanged;
  final ValueChanged<CommunityInitialView> onViewChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onSearchChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  isDense: true,
                  hintText: 'Search posts',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: search.trim().isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            controller.clear();
                            onSearchChanged('');
                          },
                          icon: const Icon(Icons.close_rounded, size: 18),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.edit_square, size: 18),
              label: const Text('Create Post'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _CompactSegment<CommunityInitialView>(
                value: activeView,
                options: const [
                  (
                    CommunityInitialView.hot,
                    'Hot',
                    Icons.local_fire_department_outlined,
                  ),
                  (
                    CommunityInitialView.myPosts,
                    'Mine',
                    Icons.person_outline_rounded,
                  ),
                  (
                    CommunityInitialView.likedPosts,
                    'Liked',
                    Icons.favorite_border_rounded,
                  ),
                ],
                onChanged: onViewChanged,
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<CommunityPostSort>(
              tooltip: 'Sort posts',
              initialValue: sort,
              onSelected: onSortChanged,
              itemBuilder: (context) => CommunityPostSort.values
                  .map(
                    (option) => PopupMenuItem(
                      value: option,
                      child: Row(
                        children: [
                          Icon(option.icon, size: 18),
                          const SizedBox(width: 10),
                          Text(option.label),
                        ],
                      ),
                    ),
                  )
                  .toList(growable: false),
              child: _SquareControl(icon: sort.icon),
            ),
          ],
        ),
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: tags.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final tag = index == 0 ? '' : tags[index - 1];
                final selected = tag == activeTag;
                return FilterChip(
                  label: Text(index == 0 ? 'All topics' : tag),
                  selected: selected,
                  showCheckmark: false,
                  onSelected: (_) => onTagChanged(tag),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _CompactSegment<T> extends StatelessWidget {
  const _CompactSegment({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final T value;
  final List<(T, String, IconData)> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panel,
        border: Border.all(color: AppTheme.outline),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: options
            .map((option) {
              final selected = option.$1 == value;
              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(9),
                  onTap: () => onChanged(option.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    height: 40,
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.gold : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(option.$3, size: 16),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            option.$2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}

class _SquareControl extends StatelessWidget {
  const _SquareControl({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppTheme.panel,
        border: Border.all(color: AppTheme.outline),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 19),
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
    required this.customTagController,
    required this.isExpanded,
    required this.isSubmitting,
    required this.onCustomTagAdd,
    required this.onExpand,
    required this.onSubmit,
    required this.onTagToggled,
    required this.selectedTags,
    required this.titleController,
    required this.loadStickers,
  });

  final TextEditingController contentController;
  final TextEditingController customTagController;
  final bool isExpanded;
  final bool isSubmitting;
  final VoidCallback onCustomTagAdd;
  final VoidCallback onExpand;
  final VoidCallback onSubmit;
  final ValueChanged<String> onTagToggled;
  final Set<String> selectedTags;
  final TextEditingController titleController;
  final Future<List<CommunitySticker>> Function() loadStickers;

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
              const SizedBox(height: 4),
              CommunityComposerAssets(
                controller: contentController,
                loadStickers: loadStickers,
              ),
              const SizedBox(height: 10),
              Text(
                'Tags',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tag in _recommendedPostTags)
                    ChoiceChip(
                      label: Text(tag),
                      selected: selectedTags.contains(tag),
                      onSelected: (_) => onTagToggled(tag),
                      avatar: selectedTags.contains(tag)
                          ? const Icon(Icons.check, size: 16)
                          : const Icon(Icons.tag_outlined, size: 16),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: customTagController,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => onCustomTagAdd(),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        labelText: 'Custom tag',
                        prefixIcon: Icon(Icons.add_circle_outline, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: onCustomTagAdd,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Tag'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final tag in selectedTags) _Pill(label: tag),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
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
  const _LeaksTab({
    required this.initialQuery,
    required this.initialCategory,
    required this.initialPlatform,
  });

  final String? initialQuery;
  final String? initialCategory;
  final String? initialPlatform;

  @override
  ConsumerState<_LeaksTab> createState() => _LeaksTabState();
}

class _LeaksTabState extends ConsumerState<_LeaksTab> {
  final _extraLeaks = <LeakPostSummary>[];
  late final _searchController = TextEditingController(
    text: widget.initialQuery?.trim() ?? '',
  );
  late var _query = widget.initialQuery?.trim() ?? '';
  late var _category = _normalizeInitialFilter(widget.initialCategory, {
    'all',
    'hero',
    'skin',
  });
  late var _platform = _normalizeInitialFilter(widget.initialPlatform, {
    'all',
    'twitter',
    'youtube',
    'instagram',
    'facebook',
    'telegram',
    'tiktok',
    'reddit',
  });
  var _nextLeaksPage = 2;
  var _hasMoreLeaks = true;
  var _isLoadingMoreLeaks = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final leakQuery = LeakPostsQuery(category: _category, platform: _platform);
    final leakValue = ref.watch(leakPostsQueryProvider(leakQuery));
    return AppAsyncView<List<LeakPostSummary>>(
      value: leakValue,
      retry: () => ref.invalidate(leakPostsQueryProvider(leakQuery)),
      data: (leaks) {
        final query = _query;
        final allLeaks = [...leaks, ..._extraLeaks];
        final filteredLeaks = allLeaks
            .where(_matchesSelectedFilters)
            .toList(growable: false);
        final visibleLeaks = query.isEmpty
            ? filteredLeaks
            : filteredLeaks
                  .where((leak) => _matchesQuery(leak, query))
                  .toList(growable: false);

        if (visibleLeaks.isEmpty) {
          return ListView(
            key: const ValueKey('community-leaks-scroll-view'),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              _LeakFilterControls(
                controller: _searchController,
                query: _query,
                category: _category,
                platform: _platform,
                onCategoryChanged: _setCategory,
                onPlatformChanged: _setPlatform,
                onQueryChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 12),
              AppEmptyState(
                icon: Icons.campaign_outlined,
                title: query.isEmpty ? 'No leaks found' : 'No matching leaks',
                message: query.isEmpty
                    ? 'Pull to refresh, switch filters, or change region in settings.'
                    : 'No leaks matched "$query" in this region.',
              ),
            ],
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            _resetLoadedPages();
            return ref.refresh(leakPostsQueryProvider(leakQuery).future);
          },
          child: ListView(
            key: const ValueKey('community-leaks-scroll-view'),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              _LeakFilterControls(
                controller: _searchController,
                query: _query,
                category: _category,
                platform: _platform,
                onCategoryChanged: _setCategory,
                onPlatformChanged: _setPlatform,
                onQueryChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 12),
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

  bool _matchesSelectedFilters(LeakPostSummary leak) {
    final leakCategory = leak.category.trim().toLowerCase();
    final leakPlatform = _normalizeLeakPlatform(leak.platform);
    return (_category == 'all' || leakCategory == _category) &&
        (_platform == 'all' || leakPlatform == _platform);
  }

  String _normalizeLeakPlatform(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'x' ? 'twitter' : normalized;
  }

  String _normalizeInitialFilter(String? value, Set<String> allowedValues) {
    final normalized = value?.trim().toLowerCase() ?? '';
    if (normalized == 'x') {
      return allowedValues.contains('twitter') ? 'twitter' : 'all';
    }
    return allowedValues.contains(normalized) ? normalized : 'all';
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
            category: _category,
            platform: _platform,
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

  void _setCategory(String value) {
    setState(() {
      _category = value;
      _resetLoadedPages();
    });
  }

  void _setPlatform(String value) {
    setState(() {
      _platform = value;
      _resetLoadedPages();
    });
  }
}

class _LeakFilterControls extends StatelessWidget {
  const _LeakFilterControls({
    required this.controller,
    required this.query,
    required this.category,
    required this.platform,
    required this.onCategoryChanged,
    required this.onPlatformChanged,
    required this.onQueryChanged,
  });

  final TextEditingController controller;
  final String query;
  final String category;
  final String platform;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onPlatformChanged;
  final ValueChanged<String> onQueryChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          onChanged: onQueryChanged,
          decoration: InputDecoration(
            hintText: 'Search leaks, heroes or creators',
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      controller.clear();
                      onQueryChanged('');
                    },
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _CompactSegment<String>(
                value: category,
                options: const [
                  ('all', 'All', Icons.dynamic_feed_outlined),
                  ('hero', 'Hero', Icons.shield_outlined),
                  ('skin', 'Skin', Icons.auto_awesome_outlined),
                ],
                onChanged: onCategoryChanged,
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              tooltip: 'Filter platform',
              initialValue: platform,
              onSelected: onPlatformChanged,
              itemBuilder: (context) => _leakPlatforms
                  .map(
                    (item) => PopupMenuItem(
                      value: item.$1,
                      child: Row(
                        children: [
                          _PlatformIcon(platform: item.$1, size: 18),
                          const SizedBox(width: 10),
                          Text(item.$2),
                        ],
                      ),
                    ),
                  )
                  .toList(growable: false),
              child: _SquareControl(
                icon: platform == 'all'
                    ? Icons.public_outlined
                    : _platformFallbackIcon(platform),
              ),
            ),
          ],
        ),
        if (platform != 'all') ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: InputChip(
              avatar: _PlatformIcon(platform: platform, size: 16),
              label: Text(_platformLabel(platform)),
              onDeleted: () => onPlatformChanged('all'),
            ),
          ),
        ],
      ],
    );
  }
}

class _PostCard extends ConsumerStatefulWidget {
  const _PostCard({
    required this.post,
    required this.onLikeChanged,
    this.onDelete,
  });

  final CommunityPostSummary post;
  final VoidCallback? onDelete;
  final ValueChanged<bool> onLikeChanged;

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
                _PostAuthorAvatar(
                  authorAvatarUrl: post.authorAvatarUrl,
                  authorId: post.authorId,
                  authorName: post.authorName,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PostAuthorName(
                        authorId: post.authorId,
                        authorName: post.authorName,
                      ),
                      if (post.createdAt.isNotEmpty)
                        Text(
                          AppTimeFormatter.relative(context, post.createdAt),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: AppTheme.muted),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.muted,
                  size: 20,
                ),
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
            if (post.tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 28,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: post.tags.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 6),
                  itemBuilder: (context, index) =>
                      _Pill(label: '#${post.tags[index]}', compact: true),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                _MetricAction(
                  icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                  value: _likeCount,
                  active: _isLiked,
                  onTap: _likeSubmitting ? null : () => _likePost(context),
                ),
                const SizedBox(width: 18),
                _MetricAction(
                  icon: Icons.chat_bubble_outline_rounded,
                  value: post.commentCount,
                ),
                const SizedBox(width: 18),
                _MetricAction(
                  icon: Icons.visibility_outlined,
                  value: post.viewCount,
                ),
                const Spacer(),
                if (widget.onDelete != null)
                  IconButton(
                    tooltip: 'Delete post',
                    visualDensity: VisualDensity.compact,
                    onPressed: widget.onDelete,
                    icon: const Icon(Icons.delete_outline_rounded, size: 19),
                  ),
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
      widget.onLikeChanged(result.isLiked);
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

class _PostAuthorAvatar extends StatelessWidget {
  const _PostAuthorAvatar({
    required this.authorAvatarUrl,
    required this.authorId,
    required this.authorName,
  });

  final String authorAvatarUrl;
  final int authorId;
  final String authorName;

  @override
  Widget build(BuildContext context) {
    final avatar = AppImage(
      url: authorAvatarUrl,
      width: 40,
      height: 40,
      borderRadius: 12,
      semanticLabel: authorName,
    );

    if (authorId <= 0) {
      return avatar;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.go('/profile/$authorId'),
      child: avatar,
    );
  }
}

class _PostAuthorName extends StatelessWidget {
  const _PostAuthorName({required this.authorId, required this.authorName});

  final int authorId;
  final String authorName;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
      color: AppTheme.text,
      fontWeight: FontWeight.w800,
    );

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

class _LeakCard extends StatefulWidget {
  const _LeakCard({required this.leak});

  final LeakPostSummary leak;

  @override
  State<_LeakCard> createState() => _LeakCardState();
}

class _LeakCardState extends State<_LeakCard> {
  late var _isLiked = false;
  late var _likeCount = widget.leak.likeCount;

  @override
  void didUpdateWidget(covariant _LeakCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.leak.id != widget.leak.id ||
        oldWidget.leak.likeCount != widget.leak.likeCount) {
      _isLiked = false;
      _likeCount = widget.leak.likeCount;
    }
  }

  @override
  Widget build(BuildContext context) {
    final leak = widget.leak;
    return Material(
      color: AppTheme.panel,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppTheme.outline),
      ),
      child: InkWell(
        onTap: () => _showLeakDetail(context, leak),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
              child: Row(
                children: [
                  AppImage(
                    url: leak.authorAvatarUrl,
                    width: 38,
                    height: 38,
                    borderRadius: 19,
                    semanticLabel: leak.authorName,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          leak.authorLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: AppTheme.text,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            _PlatformIcon(platform: leak.platform, size: 14),
                            const SizedBox(width: 5),
                            Text(
                              _platformLabel(leak.platform),
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: AppTheme.muted),
                            ),
                            if (leak.publishedAt.isNotEmpty) ...[
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 5),
                                child: Text(
                                  '•',
                                  style: TextStyle(color: AppTheme.muted),
                                ),
                              ),
                              Text(
                                AppTimeFormatter.relative(
                                  context,
                                  leak.publishedAt,
                                ),
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(color: AppTheme.muted),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.open_in_full_rounded,
                    size: 17,
                    color: AppTheme.muted,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 2, 14, 12),
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
                  if (leak.content.isNotEmpty &&
                      leak.content != leak.title) ...[
                    const SizedBox(height: 7),
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
                ],
              ),
            ),
            if (leak.mediaUrl.isNotEmpty)
              Stack(
                alignment: Alignment.center,
                children: [
                  AppImage(
                    url: leak.mediaUrl,
                    width: double.infinity,
                    height: 190,
                    borderRadius: 0,
                    semanticLabel: leak.title,
                  ),
                  if (_isVideoLeak(leak))
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.28),
                        ),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                ],
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 9),
              child: Row(
                children: [
                  _MetricAction(
                    icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                    value: _likeCount,
                    active: _isLiked,
                    onTap: _toggleLike,
                  ),
                  const SizedBox(width: 18),
                  _MetricAction(
                    icon: Icons.visibility_outlined,
                    value: leak.viewCount,
                  ),
                  const Spacer(),
                  _Pill(label: leak.category.toUpperCase(), compact: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _likeCount = widget.leak.likeCount + (_isLiked ? 1 : 0);
    });
  }
}

const _leakPlatforms = <(String, String)>[
  ('all', 'All Platforms'),
  ('twitter', 'Twitter / X'),
  ('youtube', 'YouTube'),
  ('instagram', 'Instagram'),
  ('facebook', 'Facebook'),
  ('telegram', 'Telegram'),
  ('tiktok', 'TikTok'),
  ('reddit', 'Reddit'),
];

String _platformLabel(String value) {
  final normalized = value.toLowerCase() == 'x'
      ? 'twitter'
      : value.toLowerCase();
  for (final item in _leakPlatforms) {
    if (item.$1 == normalized) return item.$2;
  }
  return value.isEmpty ? 'Source' : value;
}

IconData _platformFallbackIcon(String platform) {
  return switch (platform.toLowerCase()) {
    'twitter' || 'x' => Icons.alternate_email_rounded,
    'youtube' => Icons.play_circle_outline_rounded,
    'instagram' => Icons.photo_camera_outlined,
    'facebook' => Icons.facebook_rounded,
    'telegram' => Icons.send_outlined,
    'tiktok' => Icons.music_note_rounded,
    'reddit' => Icons.forum_outlined,
    _ => Icons.public_outlined,
  };
}

Color _platformColor(String platform) {
  return switch (platform.toLowerCase()) {
    'youtube' => const Color(0xFFEF4444),
    'instagram' => const Color(0xFFEC4899),
    'facebook' => const Color(0xFF3B82F6),
    'telegram' => const Color(0xFF38BDF8),
    'tiktok' => const Color(0xFFD946EF),
    'reddit' => const Color(0xFFF97316),
    _ => AppTheme.muted,
  };
}

class _PlatformIcon extends StatelessWidget {
  const _PlatformIcon({required this.platform, this.size = 16});

  final String platform;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(
      _platformFallbackIcon(platform),
      size: size,
      color: _platformColor(platform),
    );
  }
}

bool _isVideoLeak(LeakPostSummary leak) {
  final type = leak.mediaType.toLowerCase();
  return type.contains('video') || leak.videoUrl.isNotEmpty;
}

Future<void> _showLeakDetail(BuildContext context, LeakPostSummary leak) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.82,
        minChildSize: 0.55,
        maxChildSize: 0.95,
        builder: (context, controller) {
          return Material(
            color: AppTheme.panel,
            clipBehavior: Clip.antiAlias,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              side: BorderSide(color: AppTheme.outline),
            ),
            child: ListView(
              controller: controller,
              padding: EdgeInsets.zero,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(top: 9, bottom: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.muted.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 8, 12),
                  child: Row(
                    children: [
                      AppImage(
                        url: leak.authorAvatarUrl,
                        width: 42,
                        height: 42,
                        borderRadius: 21,
                        semanticLabel: leak.authorName,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              leak.authorLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.text,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Row(
                              children: [
                                _PlatformIcon(
                                  platform: leak.platform,
                                  size: 14,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '${_platformLabel(leak.platform)} · ${AppTimeFormatter.relative(context, leak.publishedAt)}',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(color: AppTheme.muted),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                if (leak.mediaUrl.isNotEmpty)
                  InkWell(
                    onTap: () {
                      if (_isVideoLeak(leak) && leak.videoUrl.isNotEmpty) {
                        showAppVideoPlayer(
                          context,
                          url: leak.videoUrl,
                          title: leak.title,
                        );
                      } else {
                        _showFullScreenLeakImage(context, leak);
                      }
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AppImage(
                          url: leak.mediaUrl,
                          width: double.infinity,
                          height: 250,
                          borderRadius: 0,
                          semanticLabel: leak.title,
                        ),
                        if (_isVideoLeak(leak))
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.72),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              size: 32,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        leak.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.text,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (leak.content.isNotEmpty &&
                          leak.content != leak.title) ...[
                        const SizedBox(height: 12),
                        Text(
                          leak.content,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: AppTheme.muted, height: 1.5),
                        ),
                      ],
                      if (leak.keywords.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          children: leak.keywords
                              .map(
                                (keyword) =>
                                    _Pill(label: '#$keyword', compact: true),
                              )
                              .toList(growable: false),
                        ),
                      ],
                      if (leak.sourceUrl.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: () async {
                            final uri = Uri.tryParse(leak.sourceUrl);
                            if (uri != null) {
                              await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          },
                          icon: const Icon(Icons.open_in_new_rounded, size: 18),
                          label: const Text('Open original post'),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Future<void> _showFullScreenLeakImage(
  BuildContext context,
  LeakPostSummary leak,
) async {
  await showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.94),
    builder: (context) => Stack(
      children: [
        Positioned.fill(
          child: InteractiveViewer(
            minScale: 0.7,
            maxScale: 5,
            child: Center(
              child: AppImage(
                url: leak.mediaUrl,
                width: MediaQuery.sizeOf(context).width,
                height: MediaQuery.sizeOf(context).height * 0.82,
                borderRadius: 0,
                semanticLabel: leak.title,
              ),
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.paddingOf(context).top + 8,
          right: 10,
          child: IconButton.filled(
            tooltip: 'Close image',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ),
      ],
    ),
  );
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
  const _Pill({required this.label, this.compact = false});

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panelAlt,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 4 : 6,
        ),
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

class _MetricAction extends StatelessWidget {
  const _MetricAction({
    required this.icon,
    required this.value,
    this.active = false,
    this.onTap,
  });

  final IconData icon;
  final int value;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFFF43F5E) : AppTheme.muted;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 36),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 5),
              Text(
                _compactCount(value),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _compactCount(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(value >= 10000000 ? 0 : 1)}m';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(value >= 10000 ? 0 : 1)}k';
  }
  return '$value';
}
