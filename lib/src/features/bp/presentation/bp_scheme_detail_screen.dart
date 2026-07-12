import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/app_image.dart';
import '../../heroes/domain/hero_summary.dart';
import '../../heroes/presentation/hero_gallery_screen.dart';
import '../domain/bp_scheme_summary.dart';
import 'bp_dashboard_screen.dart';

final bpSchemeDetailProvider = FutureProvider.family<BpSchemeSummary, String>((
  ref,
  schemeId,
) {
  return ref.watch(bpRepositoryProvider).loadScheme(schemeId);
});

class BpSchemeDetailScreen extends ConsumerStatefulWidget {
  const BpSchemeDetailScreen({
    required this.schemeId,
    this.initialGameIndex,
    this.enableLandscapeEditor = false,
    super.key,
  });

  final String schemeId;
  final int? initialGameIndex;
  final bool enableLandscapeEditor;

  @override
  ConsumerState<BpSchemeDetailScreen> createState() =>
      _BpSchemeDetailScreenState();
}

class _BpSchemeDetailScreenState extends ConsumerState<BpSchemeDetailScreen> {
  BpSchemeSummary? _localScheme;
  var _isUpdating = false;

  @override
  void initState() {
    super.initState();
    if (!widget.enableLandscapeEditor) return;
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    if (widget.enableLandscapeEditor) {
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(bpSchemeDetailProvider(widget.schemeId));

    return Material(
      color: AppTheme.bg,
      child: AppAsyncView<BpSchemeSummary>(
        value: value,
        retry: () => ref.invalidate(bpSchemeDetailProvider(widget.schemeId)),
        data: (scheme) {
          final activeScheme = _localScheme ?? scheme;
          if (widget.enableLandscapeEditor &&
              MediaQuery.orientationOf(context) == Orientation.landscape) {
            return _BpLandscapeEditor(
              scheme: activeScheme,
              initialGameIndex: widget.initialGameIndex,
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              _localScheme = null;
              ref.invalidate(bpSchemeDetailProvider(widget.schemeId));
              await ref.read(bpSchemeDetailProvider(widget.schemeId).future);
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
                _BpSchemeDetailCard(
                  scheme: activeScheme,
                  initialGameIndex: widget.initialGameIndex,
                  isUpdating: _isUpdating,
                  onEdit: () => _openEditSheet(activeScheme),
                  onDraftProgress: () => _openDraftProgressSheet(activeScheme),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openEditSheet(BpSchemeSummary scheme) async {
    final draft = await showModalBottomSheet<_BpEditDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _BpEditSheet(scheme: scheme),
    );
    if (draft == null || !mounted) {
      return;
    }

    setState(() => _isUpdating = true);
    try {
      final updated = await ref
          .read(bpRepositoryProvider)
          .updateScheme(
            scheme.id,
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
        _localScheme = updated;
        _isUpdating = false;
      });
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('BP scheme updated')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isUpdating = false);
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to update BP scheme')),
      );
    }
  }

  Future<void> _openDraftProgressSheet(BpSchemeSummary scheme) async {
    final draft = await showModalBottomSheet<_BpDraftProgressDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _BpDraftProgressSheet(scheme: scheme),
    );
    if (draft == null || !mounted) {
      return;
    }

    setState(() => _isUpdating = true);
    try {
      final updated = await ref
          .read(bpRepositoryProvider)
          .updateDraftState(
            scheme.id,
            gameNumber: draft.gameNumber,
            currentStepIndex: draft.currentStepIndex,
            blueBanCount: draft.blueBanCount,
            redBanCount: draft.redBanCount,
            bluePickCount: draft.bluePickCount,
            redPickCount: draft.redPickCount,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _localScheme = updated;
        _isUpdating = false;
      });
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('BP draft progress saved')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isUpdating = false);
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to save BP draft progress')),
      );
    }
  }
}

class _BpSchemeDetailCard extends StatelessWidget {
  const _BpSchemeDetailCard({
    required this.scheme,
    required this.isUpdating,
    required this.onEdit,
    required this.onDraftProgress,
    this.initialGameIndex,
  });

  final BpSchemeSummary scheme;
  final bool isUpdating;
  final VoidCallback onEdit;
  final VoidCallback onDraftProgress;
  final int? initialGameIndex;

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
                if (initialGameIndex != null && initialGameIndex! >= 0)
                  _MetricBadge(
                    label: 'Focused game: Game ${initialGameIndex! + 1}',
                    isPrimary: true,
                  ),
              ],
            ),
            const SizedBox(height: 18),
            _DraftCountGrid(scheme: scheme),
            if (scheme.hasCurrentBoardHeroes) ...[
              const SizedBox(height: 16),
              _CurrentBpBoard(scheme: scheme),
            ],
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: isUpdating ? null : onDraftProgress,
                  icon: const Icon(Icons.timeline_outlined, size: 18),
                  label: const Text('Draft Progress'),
                ),
                OutlinedButton.icon(
                  onPressed: isUpdating ? null : onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BpEditDraft {
  const _BpEditDraft({
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

class _BpEditSheet extends StatefulWidget {
  const _BpEditSheet({required this.scheme});

  final BpSchemeSummary scheme;

  @override
  State<_BpEditSheet> createState() => _BpEditSheetState();
}

class _BpEditSheetState extends State<_BpEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _teamAController;
  late final TextEditingController _teamBController;
  late int _boMode;
  late String _sideSelectionRule;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.scheme.name);
    _teamAController = TextEditingController(text: widget.scheme.teamAName);
    _teamBController = TextEditingController(text: widget.scheme.teamBName);
    _boMode = widget.scheme.boMode;
    _sideSelectionRule = widget.scheme.sideSelectionRule;
  }

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
                  'Edit BP scheme',
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
                        child: const Text('Save'),
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
      _BpEditDraft(
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

class _BpDraftProgressDraft {
  const _BpDraftProgressDraft({
    required this.gameNumber,
    required this.currentStepIndex,
    required this.blueBanCount,
    required this.redBanCount,
    required this.bluePickCount,
    required this.redPickCount,
  });

  final int gameNumber;
  final int currentStepIndex;
  final int blueBanCount;
  final int redBanCount;
  final int bluePickCount;
  final int redPickCount;
}

class _BpDraftProgressSheet extends StatefulWidget {
  const _BpDraftProgressSheet({required this.scheme});

  final BpSchemeSummary scheme;

  @override
  State<_BpDraftProgressSheet> createState() => _BpDraftProgressSheetState();
}

class _BpDraftProgressSheetState extends State<_BpDraftProgressSheet> {
  late int _gameNumber;
  late int _currentStepIndex;
  late int _blueBanCount;
  late int _redBanCount;
  late int _bluePickCount;
  late int _redPickCount;

  @override
  void initState() {
    super.initState();
    _gameNumber = widget.scheme.gameNumber;
    _currentStepIndex = widget.scheme.currentStepIndex;
    _blueBanCount = widget.scheme.blueBanCount;
    _redBanCount = widget.scheme.redBanCount;
    _bluePickCount = widget.scheme.bluePickCount;
    _redPickCount = widget.scheme.redPickCount;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 18, 20, bottom + 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Draft progress',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.text,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              _ProgressStepper(
                label: 'Game',
                value: _gameNumber,
                min: 1,
                max: widget.scheme.boMode,
                decrementKey: const Key('bp-progress-game-minus'),
                incrementKey: const Key('bp-progress-game-plus'),
                onChanged: (value) => setState(() => _gameNumber = value),
              ),
              _ProgressStepper(
                label: 'Step',
                value: _currentStepIndex,
                min: 0,
                max: 20,
                decrementKey: const Key('bp-progress-step-minus'),
                incrementKey: const Key('bp-progress-step-plus'),
                onChanged: (value) => setState(() => _currentStepIndex = value),
              ),
              _ProgressStepper(
                label: 'Blue bans',
                value: _blueBanCount,
                min: 0,
                max: 5,
                decrementKey: const Key('bp-progress-blue-bans-minus'),
                incrementKey: const Key('bp-progress-blue-bans-plus'),
                onChanged: (value) => setState(() => _blueBanCount = value),
              ),
              _ProgressStepper(
                label: 'Red bans',
                value: _redBanCount,
                min: 0,
                max: 5,
                decrementKey: const Key('bp-progress-red-bans-minus'),
                incrementKey: const Key('bp-progress-red-bans-plus'),
                onChanged: (value) => setState(() => _redBanCount = value),
              ),
              _ProgressStepper(
                label: 'Blue picks',
                value: _bluePickCount,
                min: 0,
                max: 5,
                decrementKey: const Key('bp-progress-blue-picks-minus'),
                incrementKey: const Key('bp-progress-blue-picks-plus'),
                onChanged: (value) => setState(() => _bluePickCount = value),
              ),
              _ProgressStepper(
                label: 'Red picks',
                value: _redPickCount,
                min: 0,
                max: 5,
                decrementKey: const Key('bp-progress-red-picks-minus'),
                incrementKey: const Key('bp-progress-red-picks-plus'),
                onChanged: (value) => setState(() => _redPickCount = value),
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
                      child: const Text('Save Progress'),
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
    Navigator.of(context).pop(
      _BpDraftProgressDraft(
        gameNumber: _gameNumber,
        currentStepIndex: _currentStepIndex,
        blueBanCount: _blueBanCount,
        redBanCount: _redBanCount,
        bluePickCount: _bluePickCount,
        redPickCount: _redPickCount,
      ),
    );
  }
}

class _BpLandscapeEditor extends ConsumerStatefulWidget {
  const _BpLandscapeEditor({required this.scheme, this.initialGameIndex});

  final BpSchemeSummary scheme;
  final int? initialGameIndex;

  @override
  ConsumerState<_BpLandscapeEditor> createState() => _BpLandscapeEditorState();
}

class _BpLandscapeEditorState extends ConsumerState<_BpLandscapeEditor> {
  static const _lanes = <(String, IconData, int?)>[
    ('ALL', Icons.grid_view_rounded, null),
    ('CLASH', Icons.shield_outlined, 1),
    ('MID', Icons.auto_awesome_outlined, 2),
    ('FARM', Icons.bolt_outlined, 3),
    ('JUNGLE', Icons.forest_outlined, 4),
    ('SUPPORT', Icons.handshake_outlined, 5),
  ];

  final _selectedHeroIds = <int>[];
  int? _selectedLane;
  bool _isSaving = false;

  Future<void> _saveDraft() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await ref
          .read(bpRepositoryProvider)
          .updateDraftState(
            widget.scheme.id,
            gameNumber: widget.initialGameIndex == null
                ? widget.scheme.gameNumber
                : widget.initialGameIndex! + 1,
            currentStepIndex: _selectedHeroIds.length,
            blueBanCount: widget.scheme.blueBanCount,
            redBanCount: widget.scheme.redBanCount,
            bluePickCount: _selectedHeroIds.length,
            redPickCount: widget.scheme.redPickCount,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('BP draft saved')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to save BP draft')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final heroes =
        ref.watch(heroGalleryProvider).valueOrNull ?? const <HeroSummary>[];
    final visibleHeroes = heroes
        .where((hero) {
          return _selectedLane == null || hero.position == _selectedLane;
        })
        .toList(growable: false);

    return ColoredBox(
      color: const Color(0xFF03050D),
      child: SafeArea(
        child: Column(
          children: [
            _BpEditorTopBar(
              scheme: widget.scheme,
              isSaving: _isSaving,
              selectedCount: _selectedHeroIds.length,
              onBack: () => Navigator.of(context).maybePop(),
              onSave: _saveDraft,
            ),
            _BpLaneBar(
              lanes: _lanes,
              selectedLane: _selectedLane,
              onSelected: (lane) => setState(() => _selectedLane = lane),
            ),
            Expanded(
              child: Row(
                children: [
                  _BpTeamRail(
                    label: widget.scheme.teamAName,
                    color: const Color(0xFF246BFF),
                    heroIds: _selectedHeroIds.take(5).toList(),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = (constraints.maxWidth / 86)
                            .floor()
                            .clamp(6, 12);
                        return GridView.builder(
                          padding: const EdgeInsets.fromLTRB(8, 8, 8, 18),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 7,
                                mainAxisSpacing: 7,
                                childAspectRatio: 1.02,
                              ),
                          itemCount: visibleHeroes.length,
                          itemBuilder: (context, index) {
                            final hero = visibleHeroes[index];
                            final heroId = int.tryParse(hero.id) ?? 0;
                            final isSelected = _selectedHeroIds.contains(
                              heroId,
                            );
                            return _BpHeroPoolTile(
                              hero: hero,
                              selected: isSelected,
                              onTap: heroId <= 0
                                  ? null
                                  : () => setState(() {
                                      if (isSelected) {
                                        _selectedHeroIds.remove(heroId);
                                      } else if (_selectedHeroIds.length < 5) {
                                        _selectedHeroIds.add(heroId);
                                      }
                                    }),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  _BpTeamRail(
                    label: widget.scheme.teamBName,
                    color: const Color(0xFFE83B43),
                    heroIds: widget.scheme.redPickHeroIds,
                    rightAligned: true,
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

class _BpEditorTopBar extends StatelessWidget {
  const _BpEditorTopBar({
    required this.scheme,
    required this.isSaving,
    required this.selectedCount,
    required this.onBack,
    required this.onSave,
  });

  final BpSchemeSummary scheme;
  final bool isSaving;
  final int selectedCount;
  final VoidCallback onBack;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 62,
      child: Row(
        children: [
          IconButton.filledTonal(
            tooltip: 'Exit BP editor',
            onPressed: onBack,
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _BpScorePill(
                  label: scheme.teamAName,
                  score: selectedCount,
                  color: const Color(0xFF246BFF),
                ),
                Container(
                  width: 64,
                  height: 58,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF171923),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '41',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _BpScorePill(
                  label: scheme.teamBName,
                  score: scheme.redPickHeroIds.length,
                  color: const Color(0xFFE83B43),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            tooltip: 'Save BP draft',
            onPressed: isSaving ? null : onSave,
            icon: const Icon(Icons.save_outlined),
          ),
        ],
      ),
    );
  }
}

class _BpScorePill extends StatelessWidget {
  const _BpScorePill({
    required this.label,
    required this.score,
    required this.color,
  });

  final String label;
  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$score',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label.isEmpty ? 'TEAM' : label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _BpLaneBar extends StatelessWidget {
  const _BpLaneBar({
    required this.lanes,
    required this.selectedLane,
    required this.onSelected,
  });

  final List<(String, IconData, int?)> lanes;
  final int? selectedLane;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final lane in lanes)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: ChoiceChip(
                label: Text(lane.$1),
                avatar: Icon(lane.$2, size: 14),
                selected: selectedLane == lane.$3,
                onSelected: (_) => onSelected(lane.$3),
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
    );
  }
}

class _BpTeamRail extends StatelessWidget {
  const _BpTeamRail({
    required this.label,
    required this.color,
    required this.heroIds,
    this.rightAligned = false,
  });

  final String label;
  final Color color;
  final List<int> heroIds;
  final bool rightAligned;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 86,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: rightAligned
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(
            label.isEmpty ? 'TEAM' : label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          for (var index = 0; index < 5; index++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: _BpSlot(
                heroId: index < heroIds.length ? heroIds[index] : null,
                color: color,
              ),
            ),
        ],
      ),
    );
  }
}

class _BpSlot extends StatelessWidget {
  const _BpSlot({required this.heroId, required this.color});

  final int? heroId;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.7), width: 2),
        color: color.withValues(alpha: 0.08),
      ),
      child: heroId == null
          ? Center(
              child: Text('•', style: TextStyle(color: color, fontSize: 22)),
            )
          : AppImage(
              url: 'https://hokhelper.com/static/game/hero/$heroId.png',
              borderRadius: 999,
              semanticLabel: 'Selected hero',
            ),
    );
  }
}

class _BpHeroPoolTile extends StatelessWidget {
  const _BpHeroPoolTile({
    required this.hero,
    required this.selected,
    this.onTap,
  });

  final HeroSummary hero;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final heroId = hero.id.isEmpty ? hero.heroId : hero.id;
    final url = hero.avatar.isNotEmpty
        ? hero.avatar
        : 'https://hokhelper.com/static/game/hero/$heroId.png';
    return Material(
      color: selected ? const Color(0xFF1A4CBE) : const Color(0xFF0A1020),
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Center(
          child: AppImage(
            url: url,
            width: 64,
            height: 64,
            borderRadius: 999,
            semanticLabel: hero.name,
          ),
        ),
      ),
    );
  }
}

class _CurrentBpBoard extends StatelessWidget {
  const _CurrentBpBoard({required this.scheme});

  final BpSchemeSummary scheme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panelAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current BP Board',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppTheme.text,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            _BpHeroSlotGroup(
              title: 'Blue ban slots',
              heroIds: scheme.blueBanHeroIds,
              color: Colors.blueAccent,
            ),
            _BpHeroSlotGroup(
              title: 'Red ban slots',
              heroIds: scheme.redBanHeroIds,
              color: Colors.redAccent,
            ),
            _BpHeroSlotGroup(
              title: 'Blue pick slots',
              heroIds: scheme.bluePickHeroIds,
              color: Colors.lightBlueAccent,
            ),
            _BpHeroSlotGroup(
              title: 'Red pick slots',
              heroIds: scheme.redPickHeroIds,
              color: Colors.deepOrangeAccent,
            ),
          ],
        ),
      ),
    );
  }
}

class _BpHeroSlotGroup extends StatelessWidget {
  const _BpHeroSlotGroup({
    required this.title,
    required this.heroIds,
    required this.color,
  });

  final String title;
  final List<int> heroIds;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (heroIds.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppTheme.muted,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final heroId in heroIds)
                Chip(
                  avatar: Icon(
                    Icons.sports_esports_outlined,
                    size: 18,
                    color: color,
                  ),
                  label: Text('Hero #$heroId'),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressStepper extends StatelessWidget {
  const _ProgressStepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.decrementKey,
    required this.incrementKey,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final Key decrementKey;
  final Key incrementKey;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.panelAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                key: decrementKey,
                onPressed: value <= min ? null : () => onChanged(value - 1),
                icon: const Icon(Icons.remove),
              ),
              SizedBox(
                width: 36,
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                key: incrementKey,
                onPressed: value >= max ? null : () => onChanged(value + 1),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
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
