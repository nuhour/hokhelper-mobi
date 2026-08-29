import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/feedback/app_notice.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/network/api_error.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_list_footer.dart';
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

class TierListToolScreen extends ConsumerStatefulWidget {
  const TierListToolScreen({super.key});

  @override
  ConsumerState<TierListToolScreen> createState() => _TierListToolScreenState();
}

class _TierListToolScreenState extends ConsumerState<TierListToolScreen> {
  static const _schemesPageSize = 20;

  List<TierListSchemeSummary>? _localSchemes;
  var _isCreating = false;

  // 第 2 页起追加的方案；第 1 页仍走既有 provider。
  final List<TierListSchemeSummary> _extraSchemes = [];
  int _loadedPages = 1;
  bool _loadingMore = false;
  bool _reachedEnd = false;

  void _resetPagination() {
    _extraSchemes.clear();
    _loadedPages = 1;
    _loadingMore = false;
    _reachedEnd = false;
  }

  // 本地增删以合并后的完整列表为基线，避免丢掉已追加的分页数据。
  List<TierListSchemeSummary> _mergedSchemes() {
    final base =
        _localSchemes ??
        ref.read(tierListToolSchemesProvider).valueOrNull ??
        const <TierListSchemeSummary>[];
    final merged = [...base, ..._extraSchemes];
    _extraSchemes.clear();
    return merged;
  }

  Future<void> _loadMoreSchemes(int loadedCount) async {
    if (_loadingMore) {
      return;
    }
    setState(() => _loadingMore = true);
    try {
      final page = await ref
          .read(tierListToolRepositoryProvider)
          .loadSchemesPage(page: _loadedPages + 1, pageSize: _schemesPageSize);
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingMore = false;
        _loadedPages += 1;
        _extraSchemes.addAll(page.schemes);
        final total = page.total;
        if (page.schemes.length < _schemesPageSize ||
            (total != null && loadedCount + page.schemes.length >= total)) {
          _reachedEnd = true;
        }
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _loadingMore = false);
      AppNotice.failure(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(tierListToolSchemesProvider);
    final l10n = AppLocalizations.of(context);

    return AppAsyncView<List<TierListSchemeSummary>>(
      value: value,
      retry: () => ref.invalidate(tierListToolSchemesProvider),
      data: (schemes) {
        final visibleSchemes = [
          ...(_localSchemes ?? schemes),
          ..._extraSchemes,
        ];
        final hasMore = !_reachedEnd && schemes.length >= _schemesPageSize;
        return RefreshIndicator(
          onRefresh: () async {
            _localSchemes = null;
            _resetPagination();
            await ref.refresh(tierListToolSchemesProvider.future).then((_) {});
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _isCreating ? null : () => _openCreateSheet(),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.translate('tierCreate')),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.translate('tierDescription'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.hokTheme.onSurfaceMuted,
                ),
              ),
              const SizedBox(height: 18),
              if (visibleSchemes.isEmpty)
                SizedBox(
                  height: 420,
                  child: AppEmptyState(
                    icon: Icons.format_list_numbered_outlined,
                    title: l10n.translate('tierEmpty'),
                    message: l10n.translate('tierDescription'),
                  ),
                )
              else ...[
                ...visibleSchemes.map(
                  (scheme) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _TierListSchemeCard(
                      scheme: scheme,
                      onDelete: () => _confirmDeleteScheme(scheme),
                    ),
                  ),
                ),
                if (hasMore || visibleSchemes.length > 10)
                  AppListFooter(
                    hasMore: hasMore,
                    loading: _loadingMore,
                    onLoadMore: () => _loadMoreSchemes(visibleSchemes.length),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _openCreateSheet() async {
    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.hokTheme.surfaceSlate,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _TierListCreateSheet(),
    );
    if (name == null || !mounted) {
      return;
    }
    setState(() => _isCreating = true);
    try {
      final created = await ref
          .read(tierListToolRepositoryProvider)
          .createScheme(name: name);
      if (!mounted) {
        return;
      }
      setState(() {
        _localSchemes = [created, ..._mergedSchemes()];
        _isCreating = false;
      });
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('Tier list created')),
      );
      context.go('/tools/tier-list/${created.id}');
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isCreating = false);
      if (error is ApiError &&
          (error.kind == ApiErrorKind.authExpired ||
              error.kind == ApiErrorKind.forbidden)) {
        AppNotice.failure(context, fallbackKey: 'authSignInToSaveTierLists');
      } else {
        AppNotice.error(context, error);
      }
    }
  }

  Future<void> _confirmDeleteScheme(TierListSchemeSummary scheme) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          AppLocalizations.of(dialogContext).translate('tierDeleteTitle'),
        ),
        content: Text('Delete "${scheme.name}" from your tier lists.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              AppLocalizations.of(dialogContext).translate('commonCancel'),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              AppLocalizations.of(dialogContext).translate('commonDelete'),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    try {
      await ref.read(tierListToolRepositoryProvider).deleteScheme(scheme.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _localSchemes = _mergedSchemes()
            .where((item) => item.id != scheme.id)
            .toList(growable: false);
      });
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('Tier list deleted')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      if (error is ApiError &&
          (error.kind == ApiErrorKind.authExpired ||
              error.kind == ApiErrorKind.forbidden)) {
        AppNotice.failure(context, fallbackKey: 'authSignInToSaveTierLists');
      } else {
        AppNotice.error(context, error);
      }
    }
  }
}

class _TierListCreateSheet extends StatefulWidget {
  const _TierListCreateSheet();

  @override
  State<_TierListCreateSheet> createState() => _TierListCreateSheetState();
}

class _TierListCreateSheetState extends State<_TierListCreateSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 18, 20, bottom + 20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.translate('tierCreate'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: context.hokTheme.onSurfaceStrong,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.translate('tierName'),
                ),
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'Enter a name' : null,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.translate('commonCancel')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _submit,
                      child: Text(l10n.translate('commonCreate')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    Navigator.of(context).pop(_nameController.text.trim());
  }
}

class _TierListSchemeCard extends StatelessWidget {
  const _TierListSchemeCard({required this.scheme, required this.onDelete});

  final TierListSchemeSummary scheme;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/tools/tier-list/${scheme.id}'),
        child: Ink(
          decoration: BoxDecoration(
            color: context.hokTheme.surfaceSlate,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.hokTheme.outlineSoft),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.format_list_numbered_outlined,
                      color: AppTheme.gold,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            scheme.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: context.hokTheme.onSurfaceStrong,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          Text(
                            'Updated ${scheme.updatedDateText}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: context.hokTheme.onSurfaceMuted,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _Badge(label: scheme.heroCountText, isPrimary: true),
                    IconButton(
                      tooltip: AppLocalizations.of(
                        context,
                      ).translate('tierDeleteTitle'),
                      onPressed: onDelete,
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: context.hokTheme.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
                if (scheme.rows.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _RowPreview(
                      rows: scheme.rows.take(5).toList(growable: false),
                    ),
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
                    color: context.hokTheme.onSurfaceMuted,
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
              const SizedBox(width: 8),
              SizedBox(
                width: 18,
                child: Text(
                  '${row.heroCount}',
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: context.hokTheme.onSurfaceMuted,
                    fontWeight: FontWeight.w800,
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
    final color = isPrimary ? AppTheme.gold : context.hokTheme.onSurfaceMuted;
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
