import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_section_header.dart';
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
  const PublicProfileScreen({required this.userId, super.key});

  final int userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileValue = ref.watch(publicUserProfileProvider(userId));
    final signedInUser = ref.watch(authControllerProvider).valueOrNull;

    return Material(
      color: AppTheme.bg,
      child: RefreshIndicator(
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PublicProfileCard extends ConsumerStatefulWidget {
  const _PublicProfileCard({required this.profile, required this.canInteract});

  final UserProfile profile;
  final bool canInteract;

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
    final avatarInitial = profile.displayName.isNotEmpty
        ? profile.displayName.substring(0, 1).toUpperCase()
        : '?';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.gold.withValues(alpha: 0.16),
                  child: Text(
                    avatarInitial,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.gold,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.text,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@${profile.username}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                _LevelBadge(level: profile.level),
                const SizedBox(width: 12),
                Expanded(child: _ProgressBar(profile: profile)),
              ],
            ),
            const SizedBox(height: 18),
            _StatsGrid(
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
            if (profile.bio.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(
                profile.bio,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.text),
              ),
            ],
            if (profile.socialLinks.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                profile.socialLinks.entries
                    .map((entry) => '${entry.key}: ${entry.value}')
                    .join('  ·  '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _StatePill(
                  icon: _isFollowing
                      ? Icons.check_circle_outline
                      : Icons.person_add_alt_1_outlined,
                  label: _isFollowing ? 'Already following' : 'Not following',
                ),
                _StatePill(
                  icon: _isLiked
                      ? Icons.favorite
                      : Icons.favorite_border_outlined,
                  label: _isLiked ? 'Liked' : 'Not liked',
                ),
              ],
            ),
            if (widget.canInteract) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: _followUpdating ? null : _toggleFollow,
                    icon: Icon(
                      _isFollowing
                          ? Icons.check_circle_outline
                          : Icons.person_add_alt_1_outlined,
                      size: 18,
                    ),
                    label: Text(_isFollowing ? 'Following' : 'Follow'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _likeUpdating ? null : _toggleLike,
                    icon: Icon(
                      _isLiked
                          ? Icons.favorite
                          : Icons.favorite_border_outlined,
                      size: 18,
                    ),
                    label: Text(_isLiked ? 'Liked' : 'Like'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
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

  void _showFollowList(BuildContext context, ProfileFollowListType type) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _FollowListSheet(type: type, userId: profile.id),
    );
  }
}

enum ProfileFollowListType { following, followers }

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
                        color: AppTheme.text,
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
                              ?.copyWith(color: AppTheme.muted),
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
                              ?.copyWith(color: AppTheme.muted),
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
        color: AppTheme.panelAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
                      color: AppTheme.text,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (user.bio.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      user.bio,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
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

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.gold.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          'LV.$level',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppTheme.gold,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final progress = (profile.levelProgress / 100).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_formatNumber(profile.points)} XP',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppTheme.text,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            valueColor: const AlwaysStoppedAnimation(AppTheme.gold),
          ),
        ),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.stats,
    this.onFollowingTap,
    this.onFollowersTap,
  });

  final ProfileStats stats;
  final VoidCallback? onFollowingTap;
  final VoidCallback? onFollowersTap;

  @override
  Widget build(BuildContext context) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.6,
      ),
      children: [
        _StatTile(label: 'Posts', value: stats.posts),
        _StatTile(
          label: 'Following',
          value: stats.following,
          onTap: onFollowingTap,
        ),
        _StatTile(
          label: 'Followers',
          value: stats.followers,
          onTap: onFollowersTap,
        ),
        _StatTile(label: 'Likes', value: stats.likes),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, this.onTap});

  final String label;
  final int value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panelAlt,
        borderRadius: BorderRadius.circular(12),
        border: onTap == null
            ? null
            : Border.all(color: AppTheme.gold.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formatNumber(value),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.text,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
            ),
          ],
        ),
      ),
    );
    if (onTap == null) {
      return content;
    }
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: content,
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
