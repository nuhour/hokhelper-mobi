import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../settings/presentation/settings_controller.dart';
import '../data/content_repository.dart';

final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  return ContentRepository(apiClient: ref.watch(apiClientProvider));
});

final skinsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final settings = await ref.watch(appSettingsControllerProvider.future);
  return ref
      .watch(contentRepositoryProvider)
      .loadSkins(settings.region.regionId);
});

final cgsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final settings = await ref.watch(appSettingsControllerProvider.future);
  return ref.watch(contentRepositoryProvider).loadCgs(settings.region.regionId);
});

class ContentScreen extends ConsumerWidget {
  const ContentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skinsValue = ref.watch(skinsProvider);
    final cgsValue = ref.watch(cgsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(skinsProvider);
        ref.invalidate(cgsProvider);
        await Future.wait([
          ref.read(skinsProvider.future),
          ref.read(cgsProvider.future),
        ]);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const AppSectionHeader(title: 'Content'),
          const SizedBox(height: 12),
          Text(
            'Skins, videos, and official media foundations.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppTheme.muted),
          ),
          const SizedBox(height: 24),
          AppAsyncView<Map<String, dynamic>>(
            value: skinsValue,
            retry: () => ref.invalidate(skinsProvider),
            data: (json) => _ContentStatusCard(
              title: 'Skins',
              subtitle: _readCount(json) == 1
                  ? '1 skin record loaded'
                  : '${_readCount(json)} skin records loaded',
              icon: Icons.collections_outlined,
            ),
          ),
          const SizedBox(height: 12),
          AppAsyncView<Map<String, dynamic>>(
            value: cgsValue,
            retry: () => ref.invalidate(cgsProvider),
            data: (json) => _ContentStatusCard(
              title: 'CGs',
              subtitle: _readCount(json) == 1
                  ? '1 CG record loaded'
                  : '${_readCount(json)} CG records loaded',
              icon: Icons.movie_creation_outlined,
            ),
          ),
        ],
      ),
    );
  }

  int _readCount(Map<String, dynamic> json) {
    final result = json['result'];
    if (result is Map) {
      return _readCountFromMap(result);
    }

    return _readCountFromMap(json);
  }

  int _readCountFromMap(Map<dynamic, dynamic> json) {
    final total = json['total'];
    if (total is int) {
      return total;
    }

    final data = json['data'];
    if (data is List) {
      return data.length;
    }

    final rows = json['rows'];
    if (rows is List) {
      return rows.length;
    }

    return 0;
  }
}

class _ContentStatusCard extends StatelessWidget {
  const _ContentStatusCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panel,
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.gold),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
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
      ),
    );
  }
}
