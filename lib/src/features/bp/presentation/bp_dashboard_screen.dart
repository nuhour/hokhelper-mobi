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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.hokTheme.onSurfaceMuted,
                ),
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
      backgroundColor: context.hokTheme.surfaceSlate,
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
                    color: context.hokTheme.onSurfaceStrong,
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
    final selectedCurrentGame = _selectedGameIndex >= history.length;
    final selectedHistoryIndex = selectedCurrentGame
        ? null
        : _selectedGameIndex.clamp(0, history.length - 1);
    final selectedGame = selectedHistoryIndex == null
        ? null
        : history[selectedHistoryIndex];
    final openGameIndex = selectedHistoryIndex ?? history.length;
    return Material(
      color: context.hokTheme.surfaceSlate,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go(
          '/tools/bp-simulator/${scheme.id}?gameIndex=$openGameIndex',
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF2E6AE8), width: 1.35),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        scheme.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: context.hokTheme.onSurfaceStrong,
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Delete BP scheme',
                      onPressed: widget.onDelete,
                      icon: const Icon(Icons.delete_outline, size: 17),
                      color: context.hokTheme.onSurfaceMuted,
                      style: IconButton.styleFrom(
                        minimumSize: const Size(32, 32),
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetricBadge(label: scheme.boModeText),
                    _MetricBadge(
                      label: _sideSelectionLabel(scheme),
                      isPrimary: true,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (var index = 0; index < history.length; index++)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _BpGameSelector(
                            label: 'Game ${history[index].gameNumber}',
                            selected: selectedHistoryIndex == index,
                            onPressed: () =>
                                setState(() => _selectedGameIndex = index),
                          ),
                        ),
                      _BpGameSelector(
                        label: 'Current (Game ${scheme.gameNumber})',
                        selected: selectedCurrentGame,
                        current: true,
                        onPressed: () =>
                            setState(() => _selectedGameIndex = history.length),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _BpGamePreview(
                  scheme: scheme,
                  game: selectedGame,
                  current: selectedCurrentGame,
                ),
                const SizedBox(height: 14),
                _BpScoreFooter(scheme: scheme),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BpGamePreview extends StatelessWidget {
  const _BpGamePreview({
    required this.scheme,
    required this.game,
    required this.current,
  });

  final BpSchemeSummary scheme;
  final BpHistoryGame? game;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final activeGame = game;
    final blueIsTeamA = activeGame == null
        ? scheme.gameNumber.isOdd
        : activeGame.blueTeamId.isEmpty
        ? activeGame.gameNumber.isOdd
        : activeGame.blueTeamId == scheme.teamAId;
    final blueName = blueIsTeamA ? scheme.teamAName : scheme.teamBName;
    final redName = blueIsTeamA ? scheme.teamBName : scheme.teamAName;
    final blueWon = activeGame?.winner == 'blue';
    final redWon = activeGame?.winner == 'red';
    final blueBans = activeGame?.blueBans ?? scheme.draftState.blueBans;
    final redBans = activeGame?.redBans ?? scheme.draftState.redBans;
    final bluePicks = activeGame?.bluePicks ?? scheme.draftState.bluePicks;
    final redPicks = activeGame?.redPicks ?? scheme.draftState.redPicks;
    final board = Padding(
      padding: const EdgeInsets.fromLTRB(12, 13, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _BpPreviewSide(
              label: blueName,
              color: const Color(0xFF246BFF),
              bans: blueBans,
              picks: bluePicks,
              winner: blueWon,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _BpPreviewSide(
              label: redName,
              color: const Color(0xFFE83B43),
              bans: redBans,
              picks: redPicks,
              winner: redWon,
              alignEnd: true,
            ),
          ),
        ],
      ),
    );
    return SizedBox(
      height: 100,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.24),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.11)),
        ),
        child: board,
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
    required this.winner,
    this.alignEnd = false,
  });

  final String label;
  final Color color;
  final List<int?> bans;
  final List<int?> picks;
  final bool winner;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: alignEnd ? TextAlign.right : TextAlign.left,
                style: TextStyle(
                  color: winner ? color : context.hokTheme.onSurfaceMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (winner) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.emoji_events_rounded,
                color: AppTheme.gold,
                size: 14,
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        _BpPreviewSlots(
          heroIds: bans,
          color: color,
          ban: true,
          alignEnd: alignEnd,
        ),
        const SizedBox(height: 7),
        _BpPreviewSlots(heroIds: picks, color: color, alignEnd: alignEnd),
      ],
    );
  }
}

class _BpPreviewSlots extends StatelessWidget {
  const _BpPreviewSlots({
    required this.heroIds,
    required this.color,
    this.ban = false,
    this.alignEnd = false,
  });

  final List<int?> heroIds;
  final Color color;
  final bool ban;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final visibleIds = heroIds.whereType<int>().where((id) => id > 0).toList();
    if (visibleIds.isEmpty) {
      return SizedBox(height: ban ? 18 : 24);
    }
    return Wrap(
      spacing: 2,
      runSpacing: 2,
      alignment: alignEnd ? WrapAlignment.end : WrapAlignment.start,
      children: [
        for (final heroId in visibleIds)
          _BpPreviewSlot(heroId: heroId, color: color, ban: ban),
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
    return Semantics(
      image: true,
      label: 'BP hero $id',
      child: Container(
        width: ban ? 18 : 24,
        height: ban ? 18 : 24,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: ban ? 0.04 : 0.1),
          border: Border.all(color: color.withValues(alpha: ban ? 0.28 : 0.75)),
        ),
        child: ban
            ? ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  Colors.grey,
                  BlendMode.saturation,
                ),
                child: _heroImage(context, id),
              )
            : _heroImage(context, id),
      ),
    );
  }

  Widget _heroImage(BuildContext context, int? id) {
    if (id == null) {
      return const SizedBox.expand();
    }
    return Image.network(
      'https://hokhelper.com/static/game/hero/$id.png',
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) =>
          ColoredBox(color: context.hokTheme.surfaceRaised),
    );
  }
}

class _BpGameSelector extends StatelessWidget {
  const _BpGameSelector({
    required this.label,
    required this.selected,
    required this.onPressed,
    this.current = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final accent = current ? const Color(0xFF16813F) : const Color(0xFF2E6AE8);
    final borderColor = selected
        ? accent
        : current
        ? AppTheme.success.withValues(alpha: 0.72)
        : Colors.white.withValues(alpha: 0.18);
    final textColor = selected
        ? context.hokTheme.onSurfaceStrong
        : current
        ? AppTheme.success
        : context.hokTheme.onSurfaceMuted;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: textColor,
        backgroundColor: selected ? accent : Colors.transparent,
        side: BorderSide(color: borderColor, width: selected ? 1.5 : 1),
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: const StadiumBorder(),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }
}

class _BpScoreFooter extends StatelessWidget {
  const _BpScoreFooter({required this.scheme});

  final BpSchemeSummary scheme;

  @override
  Widget build(BuildContext context) {
    var teamAScore = 0;
    var teamBScore = 0;
    for (final game in scheme.history) {
      if (game.winner == null) continue;
      final blueIsA = game.blueTeamId.isEmpty
          ? game.gameNumber.isOdd
          : game.blueTeamId == scheme.teamAId;
      final winnerIsA = game.winner == 'blue' ? blueIsA : !blueIsA;
      if (winnerIsA) {
        teamAScore++;
      } else {
        teamBScore++;
      }
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: context.hokTheme.outlineSoft)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${scheme.teamAName}: $teamAScore',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF2E6AE8),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              'VS',
              style: TextStyle(
                color: context.hokTheme.onSurfaceMuted,
                fontWeight: FontWeight.w900,
              ),
            ),
            Expanded(
              child: Text(
                '${scheme.teamBName}: $teamBScore',
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFE0E7F5),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _sideSelectionLabel(BpSchemeSummary scheme) {
  return switch (scheme.sideSelectionRule) {
    'alternating' => 'Alternating sides',
    'loser_selects' => 'Loser selects side',
    _ => 'Side selection',
  };
}

class _MetricBadge extends StatelessWidget {
  const _MetricBadge({required this.label, this.isPrimary = false});

  final String label;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final color = isPrimary
        ? const Color(0xFF4B8BFF)
        : context.hokTheme.onSurfaceMuted;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: (isPrimary ? const Color(0xFF246BFF) : Colors.white).withValues(
          alpha: isPrimary ? 0.17 : 0.035,
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: (isPrimary ? const Color(0xFF246BFF) : Colors.white)
              .withValues(alpha: isPrimary ? 0.52 : 0.13),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
