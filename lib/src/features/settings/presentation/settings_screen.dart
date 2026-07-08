import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/regions.dart';
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
                _SettingsSegment<HokRegion>(
                  icon: Icons.public_outlined,
                  title: l10n.settingsRegionTitle,
                  subtitle: l10n.settingsRegionSubtitle,
                  selected: settings.region,
                  values: HokRegion.values,
                  labelBuilder: (region) => region.label,
                  onChanged: (region) {
                    ref
                        .read(appSettingsControllerProvider.notifier)
                        .setRegion(region);
                  },
                ),
                const SizedBox(height: 12),
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panel,
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.gold),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppTheme.muted),
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
                        ? AppTheme.bg
                        : AppTheme.text;
                  }),
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    return states.contains(WidgetState.selected)
                        ? AppTheme.gold
                        : Colors.transparent;
                  }),
                  side: WidgetStatePropertyAll(
                    BorderSide(color: Colors.white.withValues(alpha: 0.14)),
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
    return Material(
      color: AppTheme.panel,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        key: tileKey,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(icon, color: AppTheme.gold),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppTheme.text,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppTheme.muted),
        ),
        trailing: TextButton(onPressed: onTap, child: Text(actionLabel)),
        onTap: onTap,
      ),
    );
  }
}
