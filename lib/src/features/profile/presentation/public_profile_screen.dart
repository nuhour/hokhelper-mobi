import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/app_share_sheet.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/profile_repository.dart';
import '../domain/user_profile.dart';
import 'me_screen.dart';

final publicUserProfileProvider = FutureProvider.family<UserProfile, int>((
  ref,
  userId,
) {
  return ref.watch(profileRepositoryProvider).loadProfile(userId: userId);
});

class PublicProfileScreen extends ConsumerWidget {
  const PublicProfileScreen({
    required this.userId,
    this.initialFollowListType,
    super.key,
  });

  final int userId;
  final ProfileFollowListType? initialFollowListType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileValue = ref.watch(publicUserProfileProvider(userId));
    final signedInUser = ref.watch(authControllerProvider).valueOrNull;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(publicUserProfileProvider(userId));
          await ref.read(publicUserProfileProvider(userId).future);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            const AppSectionHeader(title: 'Public Profile'),
            const SizedBox(height: 16),
            AppAsyncView<UserProfile>(
              value: profileValue,
              retry: () => ref.invalidate(publicUserProfileProvider(userId)),
              data: (profile) => _PublicProfileCard(
                profile: profile,
                canInteract: signedInUser != null && !profile.isSelf,
                initialFollowListType: initialFollowListType,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PublicProfileCard extends ConsumerStatefulWidget {
  const _PublicProfileCard({
    required this.profile,
    required this.canInteract,
    this.initialFollowListType,
  });

  final UserProfile profile;
  final bool canInteract;
  final ProfileFollowListType? initialFollowListType;

  @override
  ConsumerState<_PublicProfileCard> createState() => _PublicProfileCardState();
}

class _PublicProfileCardState extends ConsumerState<_PublicProfileCard> {
  late bool _isFollowing;
  late bool _isLiked;
  late int _followers;
  late int _likes;
  bool _followUpdating = false;
  bool _likeUpdating = false;
  ProfileFollowListType? _openedInitialFollowListType;

  UserProfile get profile => widget.profile;

  @override
  void initState() {
    super.initState();
    _syncFromProfile();
  }

  @override
  void didUpdateWidget(covariant _PublicProfileCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile.id != widget.profile.id) {
      _syncFromProfile();
    }
  }

  void _syncFromProfile() {
    _isFollowing = widget.profile.isFollowing;
    _isLiked = widget.profile.isLiked;
    _followers = widget.profile.stats.followers;
    _likes = widget.profile.stats.likes;
  }

  @override
  Widget build(BuildContext context) {
    final initialFollowListType = widget.initialFollowListType;
    if (initialFollowListType != null &&
        _openedInitialFollowListType != initialFollowListType) {
      _openedInitialFollowListType = initialFollowListType;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showFollowList(context, initialFollowListType);
        }
      });
    }

    final avatarInitial = profile.displayName.isNotEmpty
        ? profile.displayName.substring(0, 1).toUpperCase()
        : '?';
    final scheme = Theme.of(context).colorScheme;
    final muted = Theme.of(context).brightness == Brightness.light
        ? AppTheme.lightMuted
        : context.hokTheme.onSurfaceMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 108,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  ProfileAvatar(
                    avatarUrl: profile.avatar,
                    fallback: avatarInitial,
                  ),
                  Positioned(
                    left: constraints.maxWidth / 2 + 58,
                    top: 23,
                    child: _PublicLikesCount(count: _likes),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Text(
          profile.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '@${profile.username}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: muted),
        ),
        const SizedBox(height: 12),
        Text(
          profile.bio.isEmpty ? 'No personal signature yet' : profile.bio,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: profile.bio.isEmpty ? muted : scheme.onSurface,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 14),
        ProfileSocialLinksDropdown(links: profile.socialLinks),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              ProfileLevelBadge(profile: profile),
              const SizedBox(width: 12),
              Expanded(child: ProfileProgressBar(profile: profile)),
            ],
          ),
        ),
        const SizedBox(height: 22),
        ProfileStatsRow(
          stats: ProfileStats(
            posts: profile.stats.posts,
            following: profile.stats.following,
            followers: _followers,
            likes: _likes,
          ),
          onFollowingTap: () =>
              _showFollowList(context, ProfileFollowListType.following),
          onFollowersTap: () =>
              _showFollowList(context, ProfileFollowListType.followers),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            if (widget.canInteract) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _followUpdating ? null : _toggleFollow,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  icon: Icon(
                    _isFollowing
                        ? Icons.check_circle_outline
                        : Icons.person_add_alt_1_outlined,
                    size: 18,
                  ),
                  label: Text(_isFollowing ? 'Following' : 'Follow'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _likeUpdating ? null : _toggleLike,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  icon: Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border_outlined,
                    size: 18,
                  ),
                  label: Text(_isLiked ? 'Liked' : 'Like'),
                ),
              ),
              const SizedBox(width: 10),
            ],
            OutlinedButton(
              key: const ValueKey('public-profile-share-button'),
              onPressed: () => _shareProfile(context),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(48, 48),
                padding: const EdgeInsets.symmetric(horizontal: 13),
              ),
              child: const Icon(Icons.ios_share_outlined, size: 19),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _toggleFollow() async {
    if (_followUpdating || profile.id <= 0) {
      return;
    }
    setState(() {
      _followUpdating = true;
    });
    try {
      final result = _isFollowing
          ? await ref.read(profileRepositoryProvider).unfollowUser(profile.id)
          : await ref.read(profileRepositoryProvider).followUser(profile.id);
      if (!mounted) {
        return;
      }
      setState(() {
        final wasFollowing = _isFollowing;
        _isFollowing = result.isFollowing;
        if (wasFollowing != _isFollowing) {
          _followers = (_followers + (_isFollowing ? 1 : -1)).clamp(0, 1 << 31);
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _followUpdating = false;
        });
      }
    }
  }

  Future<void> _toggleLike() async {
    if (_likeUpdating || profile.id <= 0) {
      return;
    }
    setState(() {
      _likeUpdating = true;
    });
    try {
      final result = await ref
          .read(profileRepositoryProvider)
          .toggleProfileLike(profile.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _isLiked = result.isLiked;
        _likes = result.likesCount;
      });
    } finally {
      if (mounted) {
        setState(() {
          _likeUpdating = false;
        });
      }
    }
  }

  Future<void> _shareProfile(BuildContext context) {
    return showAppShareSheet(
      context,
      title: profile.displayName.isEmpty
          ? profile.username
          : profile.displayName,
      url: 'https://hokhelper.com/profile/${profile.id}',
    );
  }

  void _showFollowList(BuildContext context, ProfileFollowListType type) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.hokTheme.surfaceSlate,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _FollowListSheet(type: type, userId: profile.id),
    );
  }
}

class _PublicLikesCount extends StatelessWidget {
  const _PublicLikesCount({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final foreground = isLight ? AppTheme.lightText : Colors.white;
    return Material(
      color: Colors.white.withValues(alpha: isLight ? 0.72 : 0.12),
      borderRadius: BorderRadius.circular(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 56, maxWidth: 82),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite_rounded, color: foreground, size: 19),
              const SizedBox(height: 3),
              Text(
                _formatNumber(count),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum ProfileFollowListType { following, followers }

ProfileFollowListType? profileFollowListTypeFromRoute(String? value) {
  return switch ((value ?? '').trim()) {
    'following' => ProfileFollowListType.following,
    'followers' => ProfileFollowListType.followers,
    _ => null,
  };
}

class _FollowListSheet extends ConsumerStatefulWidget {
  const _FollowListSheet({required this.type, required this.userId});

  final ProfileFollowListType type;
  final int userId;

  @override
  ConsumerState<_FollowListSheet> createState() => _FollowListSheetState();
}

class _FollowListSheetState extends ConsumerState<_FollowListSheet> {
  late Future<ProfileFollowList> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<ProfileFollowList> _load() {
    final repository = ref.read(profileRepositoryProvider);
    return widget.type == ProfileFollowListType.following
        ? repository.loadFollowing(userId: widget.userId)
        : repository.loadFollowers(userId: widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.type == ProfileFollowListType.following
        ? 'Following users'
        : 'Followers';
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: context.hokTheme.onSurfaceStrong,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: FutureBuilder<ProfileFollowList>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Failed to load users',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: context.hokTheme.onSurfaceMuted,
                              ),
                        ),
                      );
                    }
                    final users = snapshot.data?.users ?? const [];
                    if (users.isEmpty) {
                      return Center(
                        child: Text(
                          widget.type == ProfileFollowListType.following
                              ? 'No following yet'
                              : 'No followers yet',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: context.hokTheme.onSurfaceMuted,
                              ),
                        ),
                      );
                    }
                    return ListView.separated(
                      itemBuilder: (context, index) {
                        return _FollowUserTile(user: users[index]);
                      },
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemCount: users.length,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FollowUserTile extends StatelessWidget {
  const _FollowUserTile({required this.user});

  final ProfileFollowUser user;

  @override
  Widget build(BuildContext context) {
    final initial = user.displayName.isNotEmpty
        ? user.displayName.substring(0, 1).toUpperCase()
        : '?';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.hokTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.hokTheme.outlineSoft),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppTheme.cyan.withValues(alpha: 0.16),
              child: Text(
                initial,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.cyan,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName.isNotEmpty
                        ? user.displayName
                        : user.username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: context.hokTheme.onSurfaceStrong,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (user.bio.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      user.bio,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.hokTheme.onSurfaceMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!user.isSelf)
              _StatePill(
                icon: user.isFollowing
                    ? Icons.check_circle_outline
                    : Icons.person_add_alt_1_outlined,
                label: user.isFollowing ? 'Following' : 'Follow',
              ),
          ],
        ),
      ),
    );
  }
}

class _StatePill extends StatelessWidget {
  const _StatePill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.cyan.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTheme.cyan, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppTheme.cyan,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatNumber(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final remaining = text.length - i;
    buffer.write(text[i]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}
