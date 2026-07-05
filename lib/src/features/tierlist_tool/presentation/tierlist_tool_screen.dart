import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_section_header.dart';
import '../data/tierlist_tool_repository.dart';
import '../domain/tierlist_scheme_summary.dart';

final tierListToolRepositoryProvider = Provider<TierListToolRepository>((ref) {
  return TierListToolRepository(apiClient: ref.watch(apiClientProvider));
});

final tierListToolSchemesProvider = FutureProvider<List<TierListSchemeSummary>>(
  (ref) {
    return ref.watch(tierListToolRepositoryProvider).loadSchemes();
  },
);

class TierListToolScreen extends ConsumerWidget {
  const TierListToolScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(tierListToolSchemesProvider);

    return AppAsyncView<List<TierListSchemeSummary>>(
      value: value,
      retry: () => ref.invalidate(tierListToolSchemesProvider),
      data: (schemes) {
        return RefreshIndicator(
          onRefresh: () => ref.refresh(tierListToolSchemesProvider.future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            children: [
              const AppSectionHeader(title: 'Tier List Tool'),
              const SizedBox(height: 8),
              Text(
                'Review saved custom tier lists and hero placement rows.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
              ),
              const SizedBox(height: 18),
              if (schemes.isEmpty)
                const SizedBox(
                  height: 420,
                  child: AppEmptyState(
                    icon: Icons.format_list_numbered_outlined,
                    title: 'No tier lists found',
                    message:
                        'Create tier lists on the portal or sign in to sync them.',
                  ),
                )
              else
                ...schemes.map(
                  (scheme) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _TierListSchemeCard(scheme: scheme),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TierListSchemeCard extends StatelessWidget {
  const _TierListSchemeCard({required this.scheme});

  final TierListSchemeSummary scheme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/tools/tier-list/${scheme.id}'),
        child: Ink(
          decoration: BoxDecoration(
            color: AppTheme.panel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.format_list_numbered_outlined,
                      color: AppTheme.gold,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        scheme.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppTheme.text,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _Badge(label: scheme.heroCountText, isPrimary: true),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Updated ${scheme.updatedDateText}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final row in scheme.rows.take(5))
                      _Badge(label: '${row.label} · ${row.heroCount}'),
                  ],
                ),
                if (scheme.rows.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _RowPreview(
                    rows: scheme.rows.take(5).toList(growable: false),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RowPreview extends StatelessWidget {
  const _RowPreview({required this.rows});

  final List<TierListSchemeRowSummary> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final row in rows) ...[
          Row(
            children: [
              SizedBox(
                width: 34,
                child: Text(
                  row.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.muted,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    value: row.heroCount <= 0 ? 0.04 : row.heroCount / 8,
                    color: tierListColor(row.label),
                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, this.isPrimary = false});

  final String label;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final color = isPrimary ? AppTheme.gold : AppTheme.muted;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: (isPrimary ? AppTheme.gold : Colors.white).withValues(
          alpha: isPrimary ? 0.16 : 0.06,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: (isPrimary ? AppTheme.gold : Colors.white).withValues(
            alpha: isPrimary ? 0.32 : 0.08,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

Color tierListColor(String label) {
  return switch (label.toUpperCase()) {
    'T0' => const Color(0xFFFF6B6B),
    'T1' => const Color(0xFFF59E0B),
    'T2' => AppTheme.gold,
    'T3' => const Color(0xFF22C55E),
    _ => AppTheme.cyan,
  };
}
