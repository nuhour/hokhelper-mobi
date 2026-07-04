import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_section_header.dart';
import '../data/bp_repository.dart';
import '../domain/bp_scheme_summary.dart';

final bpRepositoryProvider = Provider<BpRepository>((ref) {
  return BpRepository(apiClient: ref.watch(apiClientProvider));
});

final bpSchemesProvider = FutureProvider<List<BpSchemeSummary>>((ref) {
  return ref.watch(bpRepositoryProvider).loadSchemes();
});

class BpDashboardScreen extends ConsumerWidget {
  const BpDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(bpSchemesProvider);

    return AppAsyncView<List<BpSchemeSummary>>(
      value: value,
      retry: () => ref.invalidate(bpSchemesProvider),
      data: (schemes) {
        return RefreshIndicator(
          onRefresh: () => ref.refresh(bpSchemesProvider.future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            children: [
              const AppSectionHeader(title: 'BP Simulator'),
              const SizedBox(height: 8),
              Text(
                'Review saved pick/ban schemes and continue draft preparation.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
              ),
              const SizedBox(height: 18),
              if (schemes.isEmpty)
                const SizedBox(
                  height: 420,
                  child: AppEmptyState(
                    icon: Icons.account_tree_outlined,
                    title: 'No BP schemes found',
                    message:
                        'Create schemes on the portal or sign in to sync drafts.',
                  ),
                )
              else
                ...schemes.map(
                  (scheme) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _BpSchemeCard(scheme: scheme),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _BpSchemeCard extends StatelessWidget {
  const _BpSchemeCard({required this.scheme});

  final BpSchemeSummary scheme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
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
                const Icon(Icons.account_tree_outlined, color: AppTheme.gold),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    scheme.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.text,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _MetricBadge(label: scheme.boModeText, isPrimary: true),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              scheme.matchupText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.text,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetricBadge(label: scheme.progressText),
                _MetricBadge(label: scheme.historyCountText),
                _MetricBadge(label: scheme.phaseSummaryText),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricBadge extends StatelessWidget {
  const _MetricBadge({required this.label, this.isPrimary = false});

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
