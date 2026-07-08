import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import 'settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsValue = ref.watch(appSettingsControllerProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: SafeArea(
        child: AppAsyncView<AppSettings>(
          value: settingsValue,
          retry: () => ref.invalidate(appSettingsControllerProvider),
          data: (settings) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SettingsSegment<String>(
                  icon: Icons.language_outlined,
                  title: l10n.settingsLanguageTitle,
                  subtitle: l10n.settingsLanguageSubtitle,
                  selected: settings.languageCode,
                  values: AppLocalizations.supportedLanguageCodes,
                  labelBuilder: _languageLabel,
                  onChanged: (languageCode) {
                    ref
                        .read(appSettingsControllerProvider.notifier)
                        .setLanguageCode(languageCode);
                  },
                ),
                const SizedBox(height: 12),
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
                const SizedBox(height: 12),
                _SettingsActionTile(
                  tileKey: const ValueKey('settings-clear-cache-tile'),
                  icon: Icons.cleaning_services_outlined,
                  title: l10n.settingsClearCacheTitle,
                  subtitle: l10n.settingsClearCacheSubtitle,
                  actionLabel: l10n.settingsClearCacheAction,
                  onTap: () => _clearCache(context, l10n),
                ),
                const SizedBox(height: 12),
                _SettingsActionTile(
                  tileKey: const ValueKey('settings-check-updates-tile'),
                  icon: Icons.system_update_alt_outlined,
                  title: l10n.settingsUpdatesTitle,
                  subtitle: l10n.settingsUpdatesSubtitle,
                  actionLabel: l10n.settingsCheckUpdatesAction,
                  onTap: () => _checkUpdates(context, l10n),
                ),
                const SizedBox(height: 12),
                _SettingsActionTile(
                  tileKey: const ValueKey('settings-about-tile'),
                  icon: Icons.info_outline,
                  title: l10n.settingsAboutTitle,
                  subtitle: l10n.settingsAboutSubtitle,
                  actionLabel: l10n.settingsAboutAction,
                  onTap: () => _showAbout(context, l10n),
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
      'id' => 'ID',
      'fil' => 'Filipino',
      'pt' => 'PT',
      'es' => 'ES',
      'ar' => 'العربية',
      'ru' => 'RU',
      'ms' => 'MS',
      _ => 'EN',
    };
  }

  static String _themeLabel(AppThemeMode mode, AppLocalizations l10n) {
    return switch (mode) {
      AppThemeMode.classic => l10n.themeDark,
      AppThemeMode.versus => l10n.themeLight,
    };
  }

  static void _clearCache(BuildContext context, AppLocalizations l10n) {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.settingsCacheCleared)));
  }

  static void _checkUpdates(BuildContext context, AppLocalizations l10n) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.settingsLatestVersion)));
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

class _SettingsSegment<T> extends StatelessWidget {
  const _SettingsSegment({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.values,
    required this.labelBuilder,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final T selected;
  final List<T> values;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onChanged;

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
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<T>(
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
                  side: WidgetStatePropertyAll(
                    BorderSide(color: colors.border),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
  });

  final Key tileKey;
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = _SettingsColors.of(context);
    return Material(
      color: colors.panel,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        key: tileKey,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      ),
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
      muted: isLight ? AppTheme.lightMuted : AppTheme.muted,
    );
  }
}
