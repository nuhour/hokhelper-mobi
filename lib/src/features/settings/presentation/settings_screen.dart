import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            _SettingsTile(
              icon: Icons.language_outlined,
              title: 'Language',
              subtitle: 'English, Chinese, Indonesian',
            ),
            SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.public_outlined,
              title: 'Region',
              subtitle: 'China, English, Indonesia',
            ),
            SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.palette_outlined,
              title: 'Theme',
              subtitle: 'Classic and versus presentation',
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
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
      ),
    );
  }
}
