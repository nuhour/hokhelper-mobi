import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/providers/core_providers.dart';
import '../../auth/domain/auth_user.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/profile_repository.dart';
import '../domain/user_profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(apiClient: ref.watch(apiClientProvider));
});

final currentUserProfileProvider = FutureProvider<UserProfile>((ref) {
  return ref.watch(profileRepositoryProvider).loadProfile();
});

class MeScreen extends ConsumerWidget {
  const MeScreen({this.initialFollowListTab, super.key});

  final String? initialFollowListTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authValue = ref.watch(authControllerProvider);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const AppSectionHeader(title: 'Me'),
        const SizedBox(height: 24),
        AppAsyncView<AuthUser?>(
          value: authValue,
          data: (user) {
            if (user == null) {
              return const _SignedOutProfile();
            }

            return _SignedInProfile(
              user: user,
              initialFollowListType: _meFollowListTypeFromRoute(
                initialFollowListTab,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SignedOutProfile extends StatelessWidget {
  const _SignedOutProfile();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton.icon(
        onPressed: () => context.push('/login'),
        icon: const Icon(Icons.login),
        label: const Text('Login'),
      ),
    );
  }
}

class _SignedInProfile extends ConsumerWidget {
  const _SignedInProfile({required this.user, this.initialFollowListType});

  final AuthUser user;
  final _MeFollowListType? initialFollowListType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileValue = ref.watch(currentUserProfileProvider);

    return profileValue.when(
      data: (profile) => _ProfileCard(
        user: user,
        profile: profile,
        initialFollowListType: initialFollowListType,
      ),
      loading: () => _ProfileCard(user: user),
      error: (error, stackTrace) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _ProfileCard(user: user),
          const SizedBox(height: 12),
          Text(
            error.toString(),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          TextButton.icon(
            onPressed: () => ref.invalidate(currentUserProfileProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry profile'),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends ConsumerWidget {
  const _ProfileCard({
    required this.user,
    this.profile,
    this.initialFollowListType,
  });

  final AuthUser user;
  final UserProfile? profile;
  final _MeFollowListType? initialFollowListType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName = profile?.displayName.isNotEmpty == true
        ? profile!.displayName
        : user.displayName?.isNotEmpty == true
        ? user.displayName!
        : user.username;
    final email = profile?.email.isNotEmpty == true
        ? profile!.email
        : user.email;
    final avatarInitial = displayName.isNotEmpty
        ? displayName.substring(0, 1).toUpperCase()
        : '?';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panel,
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppTheme.gold.withValues(alpha: 0.16),
              child: Text(
                avatarInitial,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.gold,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              displayName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.text,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              email,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
            ),
            if (profile != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  _LevelBadge(
                    profile: profile!,
                    onTap: () => _showPointsRulesSheet(context, profile!),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _ProgressBar(profile: profile!)),
                ],
              ),
              const SizedBox(height: 18),
              _AutoOpenMeFollowList(
                profile: profile!,
                initialFollowListType: initialFollowListType,
                child: _StatsGrid(
                  stats: profile!.stats,
                  onPostsTap: () => context.go('/content/community?tab=my'),
                  onFollowingTap: () => _showFollowListSheet(
                    context,
                    userId: profile!.id,
                    type: _MeFollowListType.following,
                  ),
                  onFollowersTap: () => _showFollowListSheet(
                    context,
                    userId: profile!.id,
                    type: _MeFollowListType.followers,
                  ),
                ),
              ),
              if (profile!.bio.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  profile!.bio,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppTheme.text),
                ),
              ],
              if (profile!.socialLinks.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  profile!.socialLinks.entries
                      .map((entry) => '${entry.key}: ${entry.value}')
                      .join('  ·  '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                ),
              ],
              const SizedBox(height: 18),
              const _FavoriteShortcuts(),
            ],
            const SizedBox(height: 24),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (profile != null)
                  FilledButton.icon(
                    onPressed: () => _showEditProfileSheet(context, profile!),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit profile'),
                  ),
                OutlinedButton.icon(
                  onPressed: () => _showChangePasswordSheet(context),
                  icon: const Icon(Icons.lock_reset),
                  label: const Text('Change password'),
                ),
                OutlinedButton.icon(
                  key: const Key('profile-notifications-button'),
                  onPressed: () => context.push('/notifications'),
                  icon: const Icon(Icons.notifications_none_outlined),
                  label: const Text('Notifications'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    ref.read(authControllerProvider.notifier).logout();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileSheet(BuildContext context, UserProfile profile) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _EditProfileSheet(profile: profile),
    );
  }

  void _showChangePasswordSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _ChangePasswordSheet(),
    );
  }

  void _showPointsRulesSheet(BuildContext context, UserProfile profile) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _PointsRulesSheet(profile: profile),
    );
  }
}

void _showFollowListSheet(
  BuildContext context, {
  required int userId,
  required _MeFollowListType type,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.panel,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _MeFollowListSheet(type: type, userId: userId),
  );
}

enum _MeFollowListType { following, followers }

_MeFollowListType? _meFollowListTypeFromRoute(String? value) {
  return switch ((value ?? '').trim()) {
    'following' => _MeFollowListType.following,
    'followers' => _MeFollowListType.followers,
    _ => null,
  };
}

class _AutoOpenMeFollowList extends StatefulWidget {
  const _AutoOpenMeFollowList({
    required this.profile,
    required this.child,
    this.initialFollowListType,
  });

  final UserProfile profile;
  final Widget child;
  final _MeFollowListType? initialFollowListType;

  @override
  State<_AutoOpenMeFollowList> createState() => _AutoOpenMeFollowListState();
}

class _AutoOpenMeFollowListState extends State<_AutoOpenMeFollowList> {
  _MeFollowListType? _openedInitialFollowListType;

  @override
  Widget build(BuildContext context) {
    final initialFollowListType = widget.initialFollowListType;
    if (initialFollowListType != null &&
        _openedInitialFollowListType != initialFollowListType) {
      _openedInitialFollowListType = initialFollowListType;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showFollowListSheet(
            context,
            userId: widget.profile.id,
            type: initialFollowListType,
          );
        }
      });
    }
    return widget.child;
  }
}

class _MeFollowListSheet extends ConsumerStatefulWidget {
  const _MeFollowListSheet({required this.type, required this.userId});

  final _MeFollowListType type;
  final int userId;

  @override
  ConsumerState<_MeFollowListSheet> createState() => _MeFollowListSheetState();
}

class _MeFollowListSheetState extends ConsumerState<_MeFollowListSheet> {
  late Future<ProfileFollowList> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<ProfileFollowList> _load() {
    final repository = ref.read(profileRepositoryProvider);
    return widget.type == _MeFollowListType.following
        ? repository.loadFollowing(userId: widget.userId)
        : repository.loadFollowers(userId: widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.type == _MeFollowListType.following
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
                          widget.type == _MeFollowListType.following
                              ? 'No following yet'
                              : 'No followers yet',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.muted),
                        ),
                      );
                    }
                    return ListView.separated(
                      itemBuilder: (context, index) =>
                          _MeFollowUserTile(user: users[index]),
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

class _MeFollowUserTile extends StatelessWidget {
  const _MeFollowUserTile({required this.user});

  final ProfileFollowUser user;

  @override
  Widget build(BuildContext context) {
    final name = user.displayName.isNotEmpty ? user.displayName : user.username;
    final initial = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
    final tile = DecoratedBox(
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
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.text,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (user.bio.isNotEmpty) ...[
                    const SizedBox(height: 4),
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
            if (user.isFollowing)
              const _ProfilePill(label: 'Following')
            else if (!user.isSelf)
              const _ProfilePill(label: 'Not following'),
          ],
        ),
      ),
    );
    if (user.id <= 0 || user.isSelf) {
      return tile;
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.of(context).pop();
        context.go('/profile/${user.id}');
      },
      child: tile,
    );
  }
}

class _ProfilePill extends StatelessWidget {
  const _ProfilePill({required this.label});

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
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppTheme.gold,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _FavoriteShortcuts extends StatelessWidget {
  const _FavoriteShortcuts();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Favorites',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppTheme.text,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Column(
          children: const [
            _FavoriteShortcutTile(
              icon: Icons.forum_outlined,
              label: 'Posts',
              route: '/content/community?tab=likes',
            ),
            SizedBox(height: 8),
            _FavoriteShortcutTile(
              icon: Icons.bolt_outlined,
              label: 'Builds',
              route: '/tools/build-sim?filter=favorites',
            ),
            SizedBox(height: 8),
            _FavoriteShortcutTile(
              icon: Icons.auto_awesome_outlined,
              label: 'Prompts',
              route: '/tools/prompts?tab=favorites',
            ),
          ],
        ),
      ],
    );
  }
}

class _FavoriteShortcutTile extends StatelessWidget {
  const _FavoriteShortcutTile({
    required this.icon,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final String label;
  final String route;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push(route),
        child: Ink(
          decoration: BoxDecoration(
            color: AppTheme.panelAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.gold, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.text,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppTheme.muted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditProfileSheet extends ConsumerStatefulWidget {
  const _EditProfileSheet({required this.profile});

  final UserProfile profile;

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _displayNameController;
  late final TextEditingController _avatarController;
  late final TextEditingController _bioController;
  late final TextEditingController _discordController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(
      text: widget.profile.displayName,
    );
    _avatarController = TextEditingController(text: widget.profile.avatar);
    _bioController = TextEditingController(text: widget.profile.bio);
    _discordController = TextEditingController(
      text: widget.profile.socialLinks['discord']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _avatarController.dispose();
    _bioController.dispose();
    _discordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _SheetHandle(title: 'Edit profile'),
              const SizedBox(height: 18),
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(labelText: 'Display name'),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Display name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _avatarController,
                decoration: const InputDecoration(labelText: 'Avatar URL'),
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(labelText: 'Bio'),
                minLines: 3,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _discordController,
                decoration: const InputDecoration(labelText: 'Discord'),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: const Text('Save profile'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    setState(() => _saving = true);
    try {
      final discord = _discordController.text.trim();
      await ref
          .read(profileRepositoryProvider)
          .updateProfile(
            displayName: _displayNameController.text.trim(),
            avatar: _avatarController.text.trim(),
            bio: _bioController.text.trim(),
            socialLinks: discord.isEmpty ? const {} : {'discord': discord},
          );
      ref.invalidate(currentUserProfileProvider);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

class _ChangePasswordSheet extends ConsumerStatefulWidget {
  const _ChangePasswordSheet();

  @override
  ConsumerState<_ChangePasswordSheet> createState() =>
      _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _SheetHandle(title: 'Change password'),
              const SizedBox(height: 18),
              TextFormField(
                controller: _oldPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Current password',
                ),
                obscureText: true,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if ((value ?? '').isEmpty) {
                    return 'Current password is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _newPasswordController,
                decoration: const InputDecoration(labelText: 'New password'),
                obscureText: true,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if ((value ?? '').length < 8) {
                    return 'Use at least 8 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirm new password',
                ),
                obscureText: true,
                textInputAction: TextInputAction.done,
                validator: (value) {
                  if (value != _newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.lock_reset),
                  label: const Text('Update password'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    setState(() => _saving = true);
    try {
      await ref
          .read(profileRepositoryProvider)
          .changePassword(
            oldPassword: _oldPasswordController.text,
            newPassword: _newPasswordController.text,
          );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Password updated')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const SizedBox(width: 40, height: 4),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.text,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _PointsRulesSheet extends StatelessWidget {
  const _PointsRulesSheet({required this.profile});

  final UserProfile profile;

  static const _rules = [
    _PointsRule('Daily Login', 5),
    _PointsRule('Post Content', 15),
    _PointsRule('Comment Content', 8),
    _PointsRule('Create Build', 20),
    _PointsRule('Create Tier List', 30),
    _PointsRule('Create Prompt', 20),
    _PointsRule('Like/Favorite', 2),
  ];

  @override
  Widget build(BuildContext context) {
    final current = profile.xpCurrentLevel;
    final next = profile.xpCurrentLevel + profile.xpToNextLevel;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SheetHandle(title: 'Points Rules'),
            const SizedBox(height: 8),
            Text(
              profile.levelCap ? 'MAX' : '$current/$next XP',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
            ),
            const SizedBox(height: 16),
            ..._rules.map(
              (rule) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        rule.action,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '+${rule.points}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppTheme.gold,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PointsRule {
  const _PointsRule(this.action, this.points);

  final String action;
  final int points;
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.profile, this.onTap});

  final UserProfile profile;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final badge = DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.gold.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          'LV.${profile.level}',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppTheme.gold,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
    if (onTap == null) {
      return badge;
    }
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: badge,
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
    this.onPostsTap,
    this.onFollowingTap,
    this.onFollowersTap,
  });

  final ProfileStats stats;
  final VoidCallback? onPostsTap;
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
        _StatTile(label: 'Posts', value: stats.posts, onTap: onPostsTap),
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
    final tile = DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panelAlt,
        border: onTap == null
            ? null
            : Border.all(color: AppTheme.gold.withValues(alpha: 0.24)),
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
    if (onTap == null) {
      return tile;
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: tile,
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
