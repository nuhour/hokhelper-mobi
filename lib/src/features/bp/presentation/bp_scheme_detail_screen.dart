import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_section_header.dart';
import '../domain/bp_scheme_summary.dart';
import 'bp_dashboard_screen.dart';

final bpSchemeDetailProvider = FutureProvider.family<BpSchemeSummary, String>((
  ref,
  schemeId,
) {
  return ref.watch(bpRepositoryProvider).loadScheme(schemeId);
});

class BpSchemeDetailScreen extends ConsumerWidget {
  const BpSchemeDetailScreen({required this.schemeId, super.key});

  final String schemeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(bpSchemeDetailProvider(schemeId));

    return Material(
      color: AppTheme.bg,
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(bpSchemeDetailProvider(schemeId));
          await ref.read(bpSchemeDetailProvider(schemeId).future);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            const AppSectionHeader(title: 'BP Scheme'),
            const SizedBox(height: 8),
            Text(
              'Review this pick/ban scheme from a shared portal link.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
            ),
            const SizedBox(height: 18),
            AppAsyncView<BpSchemeSummary>(
              value: value,
              retry: () => ref.invalidate(bpSchemeDetailProvider(schemeId)),
              data: (scheme) => _BpSchemeDetailCard(scheme: scheme),
            ),
          ],
        ),
      ),
    );
  }
}

class _BpSchemeDetailCard extends StatelessWidget {
  const _BpSchemeDetailCard({required this.scheme});

  final BpSchemeSummary scheme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.text,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              scheme.matchupText,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.text,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetricBadge(label: scheme.boModeText, isPrimary: true),
                _MetricBadge(label: scheme.progressText),
                _MetricBadge(label: scheme.historyCountText),
                _MetricBadge(label: scheme.phaseSummaryText),
              ],
            ),
            const SizedBox(height: 18),
            _DraftCountGrid(scheme: scheme),
          ],
        ),
      ),
    );
  }
}

class _DraftCountGrid extends StatelessWidget {
  const _DraftCountGrid({required this.scheme});

  final BpSchemeSummary scheme;

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
        _DraftCountTile(label: 'Blue bans', value: scheme.blueBanCount),
        _DraftCountTile(label: 'Red bans', value: scheme.redBanCount),
        _DraftCountTile(label: 'Blue picks', value: scheme.bluePickCount),
        _DraftCountTile(label: 'Red picks', value: scheme.redPickCount),
      ],
    );
  }
}

class _DraftCountTile extends StatelessWidget {
  const _DraftCountTile({required this.label, required this.value});

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
              '$value',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.text,
                fontWeight: FontWeight.w900,
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
