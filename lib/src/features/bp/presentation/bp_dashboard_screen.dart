import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_error.dart';
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

class BpDashboardScreen extends ConsumerStatefulWidget {
  const BpDashboardScreen({super.key});

  @override
  ConsumerState<BpDashboardScreen> createState() => _BpDashboardScreenState();
}

class _BpDashboardScreenState extends ConsumerState<BpDashboardScreen> {
  List<BpSchemeSummary>? _localSchemes;
  var _isCreating = false;

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(bpSchemesProvider);

    return AppAsyncView<List<BpSchemeSummary>>(
      value: value,
      retry: () => ref.invalidate(bpSchemesProvider),
      data: (schemes) {
        final visibleSchemes = _localSchemes ?? schemes;
        return RefreshIndicator(
          onRefresh: () async {
            _localSchemes = null;
            await ref.refresh(bpSchemesProvider.future).then((_) {});
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            children: [
              AppSectionHeader(
                title: 'BP Simulator',
                action: FilledButton.icon(
                  onPressed: _isCreating ? null : () => _openCreateSheet(),
                  icon: const Icon(Icons.add),
                  label: const Text('Create BP'),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Review saved pick/ban schemes and continue draft preparation.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
              ),
              const SizedBox(height: 18),
              if (visibleSchemes.isEmpty)
                SizedBox(
                  height: 420,
                  child: AppEmptyState(
                    icon: Icons.account_tree_outlined,
                    title: 'No BP schemes found',
                    message:
                        'Create schemes on the portal or sign in to sync drafts.',
                  ),
                )
              else
                ...visibleSchemes.map(
                  (scheme) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _BpSchemeCard(
                      scheme: scheme,
                      onDelete: () => _confirmDeleteScheme(scheme),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openCreateSheet() async {
    final draft = await showModalBottomSheet<_BpCreateDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _BpCreateSheet(),
    );
    if (draft == null || !mounted) {
      return;
    }
    setState(() => _isCreating = true);
    try {
      final created = await ref
          .read(bpRepositoryProvider)
          .createScheme(
            name: draft.name,
            boMode: draft.boMode,
            teamAName: draft.teamAName,
            teamBName: draft.teamBName,
            sideSelectionRule: draft.sideSelectionRule,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        final existing =
            _localSchemes ??
            ref.read(bpSchemesProvider).valueOrNull ??
            const <BpSchemeSummary>[];
        _localSchemes = [created, ...existing];
        _isCreating = false;
      });
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('BP scheme created')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isCreating = false);
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text(_writeFailureMessage(error))),
      );
    }
  }

  Future<void> _confirmDeleteScheme(BpSchemeSummary scheme) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete BP scheme?'),
          content: Text('Delete "${scheme.name}" from your BP schemes.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await ref.read(bpRepositoryProvider).deleteScheme(scheme.id);
      if (!mounted) {
        return;
      }
      setState(() {
        final existing =
            _localSchemes ??
            ref.read(bpSchemesProvider).valueOrNull ??
            const <BpSchemeSummary>[];
        _localSchemes = existing
            .where((item) => item.id != scheme.id)
            .toList(growable: false);
      });
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('BP scheme deleted')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text(_writeFailureMessage(error))),
      );
    }
  }
}

String _writeFailureMessage(Object error) {
  if (error is ApiError &&
      (error.kind == ApiErrorKind.authExpired ||
          error.kind == ApiErrorKind.forbidden)) {
    return 'Sign in to save BP schemes';
  }
  return 'Failed to save BP scheme';
}

class _BpCreateDraft {
  const _BpCreateDraft({
    required this.name,
    required this.boMode,
    required this.teamAName,
    required this.teamBName,
    required this.sideSelectionRule,
  });

  final String name;
  final int boMode;
  final String teamAName;
  final String teamBName;
  final String sideSelectionRule;
}

class _BpCreateSheet extends StatefulWidget {
  const _BpCreateSheet();

  @override
  State<_BpCreateSheet> createState() => _BpCreateSheetState();
}

class _BpCreateSheetState extends State<_BpCreateSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _teamAController = TextEditingController(text: 'Team A');
  final _teamBController = TextEditingController(text: 'Team B');
  var _boMode = 7;
  var _sideSelectionRule = 'loser_selects';

  @override
  void dispose() {
    _nameController.dispose();
    _teamAController.dispose();
    _teamBController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 18, 20, bottom + 20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Create BP scheme',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Scheme name'),
                  validator: (value) =>
                      (value ?? '').trim().isEmpty ? 'Enter a name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _teamAController,
                  decoration: const InputDecoration(labelText: 'Blue side'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _teamBController,
                  decoration: const InputDecoration(labelText: 'Red side'),
                ),
                const SizedBox(height: 16),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 3, label: Text('BO3')),
                    ButtonSegment(value: 5, label: Text('BO5')),
                    ButtonSegment(value: 7, label: Text('BO7')),
                  ],
                  selected: {_boMode},
                  onSelectionChanged: (values) {
                    setState(() => _boMode = values.single);
                  },
                ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'loser_selects',
                      label: Text('Loser selects'),
                    ),
                    ButtonSegment(
                      value: 'alternating',
                      label: Text('Alternate'),
                    ),
                  ],
                  selected: {_sideSelectionRule},
                  onSelectionChanged: (values) {
                    setState(() => _sideSelectionRule = values.single);
                  },
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _submit,
                        child: const Text('Create'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    Navigator.of(context).pop(
      _BpCreateDraft(
        name: _nameController.text.trim(),
        boMode: _boMode,
        teamAName: _teamAController.text.trim().isEmpty
            ? 'Team A'
            : _teamAController.text.trim(),
        teamBName: _teamBController.text.trim().isEmpty
            ? 'Team B'
            : _teamBController.text.trim(),
        sideSelectionRule: _sideSelectionRule,
      ),
    );
  }
}

class _BpSchemeCard extends StatelessWidget {
  const _BpSchemeCard({required this.scheme, required this.onDelete});

  final BpSchemeSummary scheme;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final gameIndex = (scheme.gameNumber - 1).clamp(0, 99);
    return Material(
      color: AppTheme.panel,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () =>
            context.go('/tools/bp-simulator/${scheme.id}?gameIndex=$gameIndex'),
        child: DecoratedBox(
          decoration: BoxDecoration(
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
                      Icons.account_tree_outlined,
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
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: BorderSide(
                        color: AppTheme.error.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
