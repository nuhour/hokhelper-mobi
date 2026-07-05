import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_section_header.dart';
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
              data: (profile) => _PublicProfileCard(profile: profile),
            ),
          ],
        ),
      ),
    );
  }
}

class _PublicProfileCard extends StatelessWidget {
  const _PublicProfileCard({required this.profile});

  final UserProfile profile;

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
            _StatsGrid(stats: profile.stats),
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
                  icon: profile.isFollowing
                      ? Icons.check_circle_outline
                      : Icons.person_add_alt_1_outlined,
                  label: profile.isFollowing
                      ? 'Already following'
                      : 'Not following',
                ),
                _StatePill(
                  icon: profile.isLiked
                      ? Icons.favorite
                      : Icons.favorite_border_outlined,
                  label: profile.isLiked ? 'Liked' : 'Not liked',
                ),
              ],
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
  const _StatsGrid({required this.stats});

  final ProfileStats stats;

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
        _StatTile(label: 'Following', value: stats.following),
        _StatTile(label: 'Followers', value: stats.followers),
        _StatTile(label: 'Likes', value: stats.likes),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panelAlt,
        borderRadius: BorderRadius.circular(12),
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
