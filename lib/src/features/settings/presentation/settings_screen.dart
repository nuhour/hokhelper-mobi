import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/regions.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import 'settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsValue = ref.watch(appSettingsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
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
                  title: 'Region',
                  subtitle: 'Changes region_id for roster, content, and tools.',
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
                  title: 'Language',
                  subtitle: 'Applies the app locale for supported UI strings.',
                  selected: settings.languageCode,
                  values: const ['en', 'zh', 'id'],
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
                  title: 'Theme',
                  subtitle: 'Switches between hokx dark and light palettes.',
                  selected: settings.theme,
                  values: AppThemeMode.values,
                  labelBuilder: (mode) => mode.label,
                  onChanged: (mode) {
                    ref
                        .read(appSettingsControllerProvider.notifier)
                        .setTheme(mode);
                  },
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
      _ => 'EN',
    };
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
