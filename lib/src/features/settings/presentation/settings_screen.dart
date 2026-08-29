import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/cache/app_cache_service.dart';
import '../../../core/feedback/app_notice.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/platform/app_update_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_image.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../community/data/community_repository.dart';
import 'settings_controller.dart';

final blockedCommunityUsersProvider =
    FutureProvider.autoDispose<List<CommunityBlockedUser>>((ref) async {
      final authUser = await ref.watch(authControllerProvider.future);
      if (authUser == null) {
        return const [];
      }
      return ref.watch(communityRepositoryProvider).loadBlockedUsers();
    });

final appCacheServiceProvider = Provider<AppCacheService>((ref) {
  return AppCacheService();
});

final appUpdateServiceProvider = Provider<AppUpdateService>((ref) {
  return AppUpdateService();
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsValue = ref.watch(appSettingsControllerProvider);
    final isSignedIn = ref.watch(authControllerProvider).asData?.value != null;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: AppAsyncView<AppSettings>(
          value: settingsValue,
          retry: () => ref.invalidate(appSettingsControllerProvider),
          data: (settings) {
            final colors = _SettingsColors.of(context);
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SettingsActionTile(
                  tileKey: const ValueKey('settings-profile-tile'),
                  icon: Icons.manage_accounts_outlined,
                  title: l10n.profileAccountTitle,
                  subtitle: l10n.profileAccountSubtitle,
                  actionLabel: l10n.profileManage,
                  onTap: () => context.push('/settings/profile'),
                ),
                const SizedBox(height: 10),
                _SettingsSegment<String>(
                  icon: Icons.language_outlined,
                  title: l10n.settingsLanguageTitle,
                  subtitle: l10n.settingsLanguageSubtitle,
                  selected: settings.languageCode,
                  values: AppLocalizations.supportedLanguageCodes,
                  dropdown: true,
                  labelBuilder: _languageLabel,
                  onChanged: (languageCode) {
                    ref
                        .read(appSettingsControllerProvider.notifier)
                        .setLanguageCode(languageCode);
                  },
                ),
                const SizedBox(height: 10),
                _SettingsSegment<AppThemeMode>(
                  icon: Icons.palette_outlined,
                  title: l10n.settingsThemeTitle,
                  subtitle: l10n.settingsThemeSubtitle,
                  selected: settings.theme,
                  values: AppThemeMode.values,
                  labelBuilder: (mode) => _themeLabel(mode, l10n),
                  onChanged: (mode) {
                    ref
                        .read(appSettingsControllerProvider.notifier)
                        .setTheme(mode);
                  },
                ),
                const SizedBox(height: 10),
                // 维护类操作合并为一张分组卡，提升信息密度。
                Material(
                  color: colors.panel,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: colors.border),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      if (isSignedIn) ...[
                        _SettingsActionTile(
                          tileKey: const ValueKey(
                            'settings-blocked-users-tile',
                          ),
                          icon: Icons.person_off_outlined,
                          title: l10n.translate('settingsBlockedUsersTitle'),
                          subtitle: l10n.translate(
                            'settingsBlockedUsersSubtitle',
                          ),
                          actionLabel: l10n.translate(
                            'settingsManageBlockedUsers',
                          ),
                          grouped: true,
                          onTap: () => _showBlockedUsers(context),
                        ),
                        Divider(height: 1, color: colors.border),
                      ],
                      _SettingsActionTile(
                        tileKey: const ValueKey('settings-clear-cache-tile'),
                        icon: Icons.cleaning_services_outlined,
                        title: l10n.settingsClearCacheTitle,
                        subtitle: l10n.settingsClearCacheSubtitle,
                        actionLabel: l10n.settingsClearCacheAction,
                        grouped: true,
                        onTap: () => unawaited(_clearCache(context, ref, l10n)),
                      ),
                      Divider(height: 1, color: colors.border),
                      _SettingsActionTile(
                        tileKey: const ValueKey('settings-check-updates-tile'),
                        icon: Icons.system_update_alt_outlined,
                        title: l10n.settingsUpdatesTitle,
                        subtitle: l10n.settingsUpdatesSubtitle,
                        actionLabel: l10n.settingsCheckUpdatesAction,
                        grouped: true,
                        onTap: () =>
                            unawaited(_checkUpdates(context, ref, l10n)),
                      ),
                      Divider(height: 1, color: colors.border),
                      _SettingsActionTile(
                        tileKey: const ValueKey('settings-about-tile'),
                        icon: Icons.info_outline,
                        title: l10n.settingsAboutTitle,
                        subtitle: l10n.settingsAboutSubtitle,
                        actionLabel: l10n.settingsAboutAction,
                        grouped: true,
                        onTap: () => _showAbout(context, l10n),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static String _languageLabel(String languageCode) {
    return switch (languageCode) {
      'zh' => '中文',
      'id' => 'Bahasa Indonesia',
      'fil' => 'Filipino',
      'pt' => 'Português',
      'es' => 'Español',
      'ar' => 'العربية',
      'ru' => 'Русский',
      'ms' => 'Bahasa Melayu',
      _ => 'English',
    };
  }

  static String _themeLabel(AppThemeMode mode, AppLocalizations l10n) {
    return switch (mode) {
      AppThemeMode.classic => l10n.themeLight,
      AppThemeMode.versus => l10n.themeDark,
    };
  }

  static Future<void> _clearCache(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    AppCacheUsage usage;
    try {
      usage = await ref.read(appCacheServiceProvider).measure();
    } on Object {
      usage = const AppCacheUsage.empty();
    }
    if (!context.mounted) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const ValueKey('settings-clear-cache-dialog'),
        title: Text(l10n.settingsClearCacheConfirmTitle),
        content: Text(
          l10n.format('settingsClearCacheConfirmBody', <String, String>{
            'size': usage.formattedSize,
            'files': '${usage.fileCount}',
          }),
        ),
        actions: [
          TextButton(
            key: const ValueKey('settings-clear-cache-cancel-button'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.settingsClose),
          ),
          FilledButton(
            key: const ValueKey('settings-clear-cache-confirm-button'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.settingsClearCacheConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }

    try {
      await ref.read(appCacheServiceProvider).clear();
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              l10n.format('settingsCacheClearedWithSize', {
                'size': usage.formattedSize,
              }),
            ),
          ),
        );
    } on Object {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.settingsCacheClearFailed)));
    }
  }

  static Future<void> _checkUpdates(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final openedUri = await ref
        .read(appUpdateServiceProvider)
        .openStoreListing();
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            openedUri == null
                ? l10n.settingsUpdateOpenFailed
                : l10n.settingsUpdateStoreOpened,
          ),
        ),
      );
  }

  static void _showBlockedUsers(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const _BlockedUsersSheet(),
    );
  }

  static void _showAbout(BuildContext context, AppLocalizations l10n) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.settingsAboutDialogTitle),
          content: Text(l10n.settingsAboutDialogBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.settingsClose),
            ),
          ],
        );
      },
    );
  }
}

class _BlockedUsersSheet extends ConsumerWidget {
  const _BlockedUsersSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final users = ref.watch(blockedCommunityUsersProvider);
    final colors = _SettingsColors.of(context);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.72,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.translate('settingsBlockedUsersTitle'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colors.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.close,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.border),
          Expanded(
            child: users.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: FilledButton.icon(
                    onPressed: () =>
                        ref.invalidate(blockedCommunityUsersProvider),
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.retry),
                  ),
                ),
              ),
              data: (rows) {
                if (rows.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        l10n.translate('settingsNoBlockedUsers'),
                        style: TextStyle(color: colors.muted),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: rows.length,
                  separatorBuilder: (_, _) =>
                      Divider(height: 1, color: colors.border),
                  itemBuilder: (context, index) {
                    final user = rows[index];
                    return ListTile(
                      leading: AppImage(
                        url: user.avatar,
                        width: 44,
                        height: 44,
                        borderRadius: 22,
                        semanticLabel: user.username,
                      ),
                      title: Text(
                        user.username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: TextButton(
                        onPressed: () => _unblock(context, ref, user),
                        child: Text(l10n.translate('settingsUnblockUser')),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _unblock(
    BuildContext context,
    WidgetRef ref,
    CommunityBlockedUser user,
  ) async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref
          .read(communityRepositoryProvider)
          .setUserBlocked(user.id, blocked: false);
      ref.invalidate(blockedCommunityUsersProvider);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.translate('settingsUserUnblocked'))),
        );
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      AppNotice.failure(context, fallbackKey: 'settingsUnblockFailed');
    }
  }
}

class _SettingsSegment<T> extends StatelessWidget {
  const _SettingsSegment({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.values,
    required this.labelBuilder,
    required this.onChanged,
    this.dropdown = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final T selected;
  final List<T> values;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onChanged;
  final bool dropdown;

  @override
  Widget build(BuildContext context) {
    final colors = _SettingsColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.panel,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: colors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _segmentControl(colors),
          ],
        ),
      ),
    );
  }

  Widget _segmentControl(_SettingsColors colors) {
    if (dropdown) {
      return DropdownButtonFormField<T>(
        key: const ValueKey('settings-language-dropdown'),
        initialValue: selected,
        isExpanded: true,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colors.primary, width: 1.5),
          ),
        ),
        dropdownColor: colors.panel,
        style: TextStyle(color: colors.text, fontWeight: FontWeight.w700),
        items: [
          for (final value in values)
            DropdownMenuItem<T>(
              value: value,
              child: Text(
                labelBuilder(value),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: (value) {
          if (value != null) {
            onChanged(value);
          }
        },
      );
    }

    final control = SegmentedButton<T>(
      showSelectedIcon: false,
      segments: [
        for (final value in values)
          ButtonSegment<T>(
            value: value,
            label: Text(
              labelBuilder(value),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      selected: {selected},
      onSelectionChanged: (selection) {
        final value = selection.singleOrNull;
        if (value != null) {
          onChanged(value);
        }
      },
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(44, 44)),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? colors.onPrimary
              : colors.text;
        }),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? colors.primary
              : Colors.transparent;
        }),
        side: WidgetStatePropertyAll(BorderSide(color: colors.border)),
      ),
    );

    return SizedBox(width: double.infinity, child: control);
  }
}

class _SettingsActionTile extends StatelessWidget {
  const _SettingsActionTile({
    required this.tileKey,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
    this.grouped = false,
  });

  final Key tileKey;
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;
  final bool grouped;

  @override
  Widget build(BuildContext context) {
    final colors = _SettingsColors.of(context);
    final tile = ListTile(
      key: tileKey,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: grouped ? 2 : 8,
      ),
      leading: Icon(icon, color: colors.primary),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: colors.text, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: colors.muted),
      ),
      trailing: TextButton(onPressed: onTap, child: Text(actionLabel)),
      onTap: onTap,
    );
    if (grouped) {
      return tile;
    }
    return Material(
      color: colors.panel,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: tile,
    );
  }
}

class _SettingsColors {
  const _SettingsColors({
    required this.panel,
    required this.border,
    required this.primary,
    required this.onPrimary,
    required this.text,
    required this.muted,
  });

  final Color panel;
  final Color border;
  final Color primary;
  final Color onPrimary;
  final Color text;
  final Color muted;

  static _SettingsColors of(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    return _SettingsColors(
      panel: colorScheme.surface,
      border: colorScheme.outlineVariant,
      primary: colorScheme.primary,
      onPrimary: colorScheme.onPrimary,
      text: colorScheme.onSurface,
      muted: isLight ? AppTheme.lightMuted : context.hokTheme.onSurfaceMuted,
    );
  }
}
