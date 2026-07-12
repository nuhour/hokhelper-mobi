import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_error.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_image.dart';
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

class _BpSchemeCard extends StatefulWidget {
  const _BpSchemeCard({required this.scheme, required this.onDelete});

  final BpSchemeSummary scheme;
  final VoidCallback onDelete;

  @override
  State<_BpSchemeCard> createState() => _BpSchemeCardState();
}

class _BpSchemeCardState extends State<_BpSchemeCard> {
  var _selectedGameIndex = 0;

  @override
  Widget build(BuildContext context) {
    final scheme = widget.scheme;
    final history = scheme.history;
    final selectedHistoryIndex = history.isEmpty
        ? null
        : _selectedGameIndex.clamp(0, history.length - 1);
    final selectedGame = selectedHistoryIndex == null
        ? null
        : history[selectedHistoryIndex];
    final openGameIndex =
        selectedHistoryIndex ?? (scheme.gameNumber - 1).clamp(0, 99);
    return Material(
      color: AppTheme.panel,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go(
          '/tools/bp-simulator/${scheme.id}?gameIndex=$openGameIndex',
        ),
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
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: 'Delete BP scheme',
                      onPressed: widget.onDelete,
                      icon: const Icon(Icons.delete_outline, size: 17),
                      color: AppTheme.error,
                      style: IconButton.styleFrom(
                        minimumSize: const Size(32, 32),
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
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
                if (history.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (var index = 0; index < history.length; index++)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text('G${history[index].gameNumber}'),
                              selected: selectedHistoryIndex == index,
                              onSelected: (_) {
                                setState(() => _selectedGameIndex = index);
                              },
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _BpGamePreview(game: selectedGame!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BpGamePreview extends StatelessWidget {
  const _BpGamePreview({required this.game});

  final BpHistoryGame game;

  @override
  Widget build(BuildContext context) {
    final blueWon = game.winner == 'blue';
    final redWon = game.winner == 'red';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            _BpPreviewSide(
              label: blueWon ? 'Blue Win' : 'Blue',
              color: const Color(0xFF246BFF),
              bans: game.blueBans,
              picks: game.bluePicks,
            ),
            const SizedBox(height: 8),
            _BpPreviewSide(
              label: redWon ? 'Red Win' : 'Red',
              color: const Color(0xFFE83B43),
              bans: game.redBans,
              picks: game.redPicks,
            ),
          ],
        ),
      ),
    );
  }
}

class _BpPreviewSide extends StatelessWidget {
  const _BpPreviewSide({
    required this.label,
    required this.color,
    required this.bans,
    required this.picks,
  });

  final String label;
  final Color color;
  final List<int?> bans;
  final List<int?> picks;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 58,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Expanded(
          child: _BpPreviewSlots(heroIds: bans, color: color, ban: true),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _BpPreviewSlots(heroIds: picks, color: color),
        ),
      ],
    );
  }
}

class _BpPreviewSlots extends StatelessWidget {
  const _BpPreviewSlots({
    required this.heroIds,
    required this.color,
    this.ban = false,
  });

  final List<int?> heroIds;
  final Color color;
  final bool ban;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var index = 0; index < 5; index++)
          _BpPreviewSlot(
            heroId: index < heroIds.length ? heroIds[index] : null,
            color: color,
            ban: ban,
          ),
      ],
    );
  }
}

class _BpPreviewSlot extends StatelessWidget {
  const _BpPreviewSlot({
    required this.heroId,
    required this.color,
    this.ban = false,
  });

  final int? heroId;
  final Color color;
  final bool ban;

  @override
  Widget build(BuildContext context) {
    final id = heroId;
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: id == null || id <= 0
          ? Icon(
              Icons.circle_outlined,
              color: color.withValues(alpha: 0.45),
              size: 11,
            )
          : Stack(
              fit: StackFit.expand,
              children: [
                AppImage(
                  url: 'https://hokhelper.com/static/game/hero/$id.png',
                  borderRadius: 999,
                  semanticLabel: 'BP hero $id',
                ),
                if (ban)
                  const Center(
                    child: Icon(
                      Icons.block_rounded,
                      color: AppTheme.error,
                      size: 14,
                    ),
                  ),
              ],
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
