import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../settings/presentation/settings_controller.dart';
import '../data/community_repository.dart';
import '../domain/community_post_summary.dart';
import '../domain/leak_post_summary.dart';

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return CommunityRepository(apiClient: ref.watch(apiClientProvider));
});

final communityPostsProvider = FutureProvider<List<CommunityPostSummary>>((
  ref,
) async {
  final settings = await ref.watch(appSettingsControllerProvider.future);
  return ref
      .watch(communityRepositoryProvider)
      .loadPosts(settings.region.regionId);
});

final leakPostsProvider = FutureProvider<List<LeakPostSummary>>((ref) async {
  final settings = await ref.watch(appSettingsControllerProvider.future);
  return ref
      .watch(communityRepositoryProvider)
      .loadLeaks(settings.region.regionId);
});

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({this.initialTabIndex = 0, super.key});

  final int initialTabIndex;

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
              _PostsTab(value: ref.watch(communityPostsProvider)),
              _LeaksTab(value: ref.watch(leakPostsProvider)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostsTab extends ConsumerWidget {
  const _PostsTab({required this.value});

  final AsyncValue<List<CommunityPostSummary>> value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppAsyncView<List<CommunityPostSummary>>(
      value: value,
      retry: () => ref.invalidate(communityPostsProvider),
      data: (posts) {
        if (posts.isEmpty) {
          return const AppEmptyState(
            icon: Icons.forum_outlined,
            title: 'No community posts found',
            message: 'Pull to refresh or switch region in settings.',
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.refresh(communityPostsProvider.future),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount: posts.length,
            itemBuilder: (context, index) => _PostCard(post: posts[index]),
            separatorBuilder: (context, index) => const SizedBox(height: 12),
          ),
        );
      },
    );
  }
}

class _LeaksTab extends ConsumerWidget {
  const _LeaksTab({required this.value});

  final AsyncValue<List<LeakPostSummary>> value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppAsyncView<List<LeakPostSummary>>(
      value: value,
      retry: () => ref.invalidate(leakPostsProvider),
      data: (leaks) {
        if (leaks.isEmpty) {
          return const AppEmptyState(
            icon: Icons.campaign_outlined,
            title: 'No leaks found',
            message: 'Pull to refresh or switch region in settings.',
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.refresh(leakPostsProvider.future),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount: leaks.length,
            itemBuilder: (context, index) => _LeakCard(leak: leaks[index]),
            separatorBuilder: (context, index) => const SizedBox(height: 12),
          ),
        );
      },
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post});

  final CommunityPostSummary post;

  @override
  Widget build(BuildContext context) {
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
                _Pill(label: post.metricText),
                ...post.tags.take(3).map((tag) => _Pill(label: tag)),
              ],
            ),
          ],
        ),
      ),
    );
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
