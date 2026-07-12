import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/app_image.dart';
import '../../heroes/domain/hero_summary.dart';
import '../../heroes/presentation/hero_gallery_screen.dart';
import '../../settings/presentation/settings_controller.dart';
import '../../teambuild/domain/team_recommendation.dart';
import '../../teambuild/presentation/team_builder_screen.dart';
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

class _BpStep {
  const _BpStep(this.side, this.type);

  final _BpSide side;
  final _BpSlotType type;
}

enum _BpSide { blue, red }

enum _BpSlotType { ban, pick }

class _BpSnapshot {
  const _BpSnapshot({
    required this.blueBans,
    required this.redBans,
    required this.bluePicks,
    required this.redPicks,
    required this.stepIndex,
    required this.timeLeft,
  });

  final List<int?> blueBans;
  final List<int?> redBans;
  final List<int?> bluePicks;
  final List<int?> redPicks;
  final int stepIndex;
  final int timeLeft;
}

class _BpLandscapeEditor extends ConsumerStatefulWidget {
  const _BpLandscapeEditor({required this.scheme, this.initialGameIndex});

  final BpSchemeSummary scheme;
  final int? initialGameIndex;

  @override
  ConsumerState<_BpLandscapeEditor> createState() => _BpLandscapeEditorState();
}

class _BpLandscapeEditorState extends ConsumerState<_BpLandscapeEditor> {
  static const _timerDuration = 45;
  static const _lanes = <(String, IconData, int?)>[
    ('ALL', Icons.grid_view_rounded, null),
    ('CLASH', Icons.shield_outlined, 1),
    ('MID', Icons.auto_awesome_outlined, 2),
    ('FARM', Icons.bolt_outlined, 3),
    ('JUNGLE', Icons.forest_outlined, 4),
    ('SUPPORT', Icons.handshake_outlined, 5),
  ];
  static const _standardSteps = <_BpStep>[
    _BpStep(_BpSide.blue, _BpSlotType.ban),
    _BpStep(_BpSide.red, _BpSlotType.ban),
    _BpStep(_BpSide.blue, _BpSlotType.ban),
    _BpStep(_BpSide.red, _BpSlotType.ban),
    _BpStep(_BpSide.blue, _BpSlotType.pick),
    _BpStep(_BpSide.red, _BpSlotType.pick),
    _BpStep(_BpSide.red, _BpSlotType.pick),
    _BpStep(_BpSide.blue, _BpSlotType.pick),
    _BpStep(_BpSide.blue, _BpSlotType.pick),
    _BpStep(_BpSide.red, _BpSlotType.pick),
    _BpStep(_BpSide.red, _BpSlotType.ban),
    _BpStep(_BpSide.blue, _BpSlotType.ban),
    _BpStep(_BpSide.blue, _BpSlotType.ban),
    _BpStep(_BpSide.red, _BpSlotType.ban),
    _BpStep(_BpSide.red, _BpSlotType.ban),
    _BpStep(_BpSide.blue, _BpSlotType.ban),
    _BpStep(_BpSide.red, _BpSlotType.pick),
    _BpStep(_BpSide.blue, _BpSlotType.pick),
    _BpStep(_BpSide.blue, _BpSlotType.pick),
    _BpStep(_BpSide.red, _BpSlotType.pick),
  ];

  late List<int?> _blueBans;
  late List<int?> _redBans;
  late List<int?> _bluePicks;
  late List<int?> _redPicks;
  late int _currentStepIndex;
  late int _timeLeft;
  late bool _isStarted;
  late bool _isTimerRunning;
  late bool _isSaved;
  late bool _isHistoryMode;
  late bool _isPeakMode;
  late int _gameNumber;
  late List<BpHistoryGame> _history;
  late bool _blueTeamIsA;
  late List<int> _peakUserPicks;
  late List<int> _peakEnemyPicks;
  _BpSide _nextGameLoserSide = _BpSide.blue;
  bool _peakRevealed = false;
  bool _isPeakGenerating = false;
  int? _selectedHeroId;
  String? _gameWinner;
  final _undoStack = <_BpSnapshot>[];
  final _redoStack = <_BpSnapshot>[];
  int? _selectedLane;
  bool _isSaving = false;
  bool _isAdvancing = false;
  bool _showBanned = true;
  bool _showPicked = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _gameNumber = widget.scheme.gameNumber;
    _history = List<BpHistoryGame>.from(widget.scheme.history);
    _blueTeamIsA = _gameNumber.isOdd;
    final historyIndex = widget.initialGameIndex;
    _isHistoryMode =
        historyIndex != null &&
        historyIndex >= 0 &&
        historyIndex < widget.scheme.history.length;
    _isPeakMode =
        !_isHistoryMode && widget.scheme.boMode == 7 && _gameNumber == 7;
    if (_isHistoryMode) {
      final game = widget.scheme.history[historyIndex!];
      _gameNumber = game.gameNumber;
      _blueTeamIsA = game.blueTeamId.isEmpty
          ? _gameNumber.isOdd
          : game.blueTeamId == widget.scheme.teamAId;
      _blueBans = List<int?>.filled(5, null);
      _redBans = List<int?>.filled(5, null);
      _bluePicks = List<int?>.from(game.bluePicks);
      _redPicks = List<int?>.from(game.redPicks);
      _currentStepIndex = _standardSteps.length;
      _timeLeft = _timerDuration;
      _isStarted = true;
      _isTimerRunning = false;
      _isSaved = true;
      _isPeakMode = game.mode == 'peak';
      _peakUserPicks = game.bluePicks
          .whereType<int>()
          .where((id) => id > 0)
          .toList();
      _peakEnemyPicks = game.redPicks
          .whereType<int>()
          .where((id) => id > 0)
          .toList();
      _peakRevealed = _isPeakMode;
      if (_isPeakMode) _currentStepIndex = -1;
    } else {
      final state = widget.scheme.draftState;
      _blueBans = List<int?>.from(state.blueBans);
      _redBans = List<int?>.from(state.redBans);
      _bluePicks = List<int?>.from(state.bluePicks);
      _redPicks = List<int?>.from(state.redPicks);
      _currentStepIndex = state.currentStepIndex.clamp(
        0,
        _standardSteps.length,
      );
      _timeLeft = state.timeLeft.clamp(1, _timerDuration);
      _isStarted = state.isStarted;
      _isTimerRunning = state.isStarted && !state.isSaved;
      _isSaved = state.isSaved;
      _gameWinner = state.gameWinner;
      _peakUserPicks = state.bluePicks
          .whereType<int>()
          .where((id) => id > 0)
          .toList();
      _peakEnemyPicks = state.redPicks
          .whereType<int>()
          .where((id) => id > 0)
          .toList();
      _peakRevealed = _isPeakMode && _peakEnemyPicks.isNotEmpty;
      if (_isPeakMode) {
        _currentStepIndex = -1;
        _isStarted = false;
        _isTimerRunning = false;
      }
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_canAct || !_isTimerRunning) return;
      if (_timeLeft <= 1) {
        _handleTimeout();
      } else {
        setState(() => _timeLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  _BpStep? get _currentStep =>
      _isPeakMode || _isFinished ? null : _standardSteps[_currentStepIndex];

  bool get _isFinished =>
      _isPeakMode ? _peakRevealed : _currentStepIndex >= _standardSteps.length;

  bool get _canAct =>
      _isStarted && !_isHistoryMode && !_isSaved && !_isFinished;

  List<int?> _slotsFor(_BpStep step) {
    return switch ((step.side, step.type)) {
      (_BpSide.blue, _BpSlotType.ban) => _blueBans,
      (_BpSide.red, _BpSlotType.ban) => _redBans,
      (_BpSide.blue, _BpSlotType.pick) => _bluePicks,
      (_BpSide.red, _BpSlotType.pick) => _redPicks,
    };
  }

  int get _activeSlotIndex => _currentStep == null
      ? -1
      : _slotsFor(_currentStep!).indexWhere((heroId) => heroId == null);

  _BpSnapshot get _snapshot => _BpSnapshot(
    blueBans: List<int?>.from(_blueBans),
    redBans: List<int?>.from(_redBans),
    bluePicks: List<int?>.from(_bluePicks),
    redPicks: List<int?>.from(_redPicks),
    stepIndex: _currentStepIndex,
    timeLeft: _timeLeft,
  );

  void _restore(_BpSnapshot snapshot) {
    setState(() {
      _blueBans = List<int?>.from(snapshot.blueBans);
      _redBans = List<int?>.from(snapshot.redBans);
      _bluePicks = List<int?>.from(snapshot.bluePicks);
      _redPicks = List<int?>.from(snapshot.redPicks);
      _currentStepIndex = snapshot.stepIndex;
      _timeLeft = snapshot.timeLeft;
      _selectedHeroId = null;
    });
  }

  void _startBp() {
    if (_isPeakMode) return;
    setState(() {
      _isStarted = true;
      _isTimerRunning = true;
      _isSaved = false;
      _timeLeft = _timerDuration;
    });
  }

  void _resetBp() {
    if (_isPeakMode) {
      setState(() {
        _peakUserPicks = [];
        _peakEnemyPicks = [];
        _peakRevealed = false;
        _gameWinner = null;
        _isSaved = false;
      });
      return;
    }
    setState(() {
      _blueBans = List<int?>.filled(5, null);
      _redBans = List<int?>.filled(5, null);
      _bluePicks = List<int?>.filled(5, null);
      _redPicks = List<int?>.filled(5, null);
      _currentStepIndex = 0;
      _timeLeft = _timerDuration;
      _selectedHeroId = null;
      _isStarted = false;
      _isTimerRunning = false;
      _isSaved = false;
      _gameWinner = null;
      _undoStack.clear();
      _redoStack.clear();
    });
  }

  void _toggleTimer() {
    if (_isHistoryMode || _isSaved || _isFinished) return;
    if (!_isStarted) {
      _startBp();
      return;
    }
    setState(() => _isTimerRunning = !_isTimerRunning);
  }

  void _resumeTimer() => _startBp();

  void _setSelectedHero(int heroId) {
    if (_isPeakMode) {
      if (_isSaved || _peakRevealed || heroId <= 0) return;
      setState(() {
        if (_peakUserPicks.contains(heroId)) {
          _peakUserPicks.remove(heroId);
        } else if (_peakUserPicks.length < 5) {
          _peakUserPicks.add(heroId);
        }
      });
      return;
    }
    if (!_canSelectHero(heroId)) return;
    setState(() => _selectedHeroId = heroId);
  }

  void _commitSelection([int? heroOverride]) {
    final step = _currentStep;
    if (step == null || !_canAct) return;
    var heroId = heroOverride ?? _selectedHeroId;
    if (heroId == null && step.type == _BpSlotType.pick) return;
    final activeIndex = _activeSlotIndex;
    if (activeIndex < 0) return;
    _undoStack.add(_snapshot);
    _redoStack.clear();
    setState(() {
      heroId ??= -1;
      _slotsFor(step)[activeIndex] = heroId;
      _currentStepIndex++;
      _timeLeft = _timerDuration;
      _selectedHeroId = null;
    });
  }

  void _handleTimeout() {
    final step = _currentStep;
    if (step == null) return;
    var heroId = _selectedHeroId;
    if (heroId == null && step.type == _BpSlotType.pick) {
      final heroes =
          ref.read(heroGalleryProvider).valueOrNull ?? const <HeroSummary>[];
      final fallback = heroes.firstWhere(
        (hero) => _canSelectHero(int.tryParse(hero.id) ?? 0),
        orElse: () =>
            const HeroSummary(id: '', name: '', avatar: '', title: ''),
      );
      heroId = int.tryParse(fallback.id);
    }
    _commitSelection(heroId);
  }

  void _undo() {
    if (_undoStack.isEmpty || _isHistoryMode || _isSaved) return;
    final previous = _undoStack.removeLast();
    _redoStack.add(_snapshot);
    _restore(previous);
  }

  void _redo() {
    if (_redoStack.isEmpty || _isHistoryMode || _isSaved) return;
    final next = _redoStack.removeLast();
    _undoStack.add(_snapshot);
    _restore(next);
  }

  bool _isBlueTeamA() => _blueTeamIsA;

  String get _blueTeamName =>
      _isBlueTeamA() ? widget.scheme.teamAName : widget.scheme.teamBName;

  String get _redTeamName =>
      _isBlueTeamA() ? widget.scheme.teamBName : widget.scheme.teamAName;

  int get _winThreshold => (widget.scheme.boMode + 1) ~/ 2;

  bool get _isSeriesCompletedAfterThis =>
      _teamScore(true) >= _winThreshold ||
      _teamScore(false) >= _winThreshold ||
      _gameNumber >= widget.scheme.boMode;

  int _teamScore(bool teamA) {
    var score = 0;
    for (final game in _history) {
      if (game.winner == null) continue;
      final blueIsA = game.blueTeamId.isEmpty
          ? game.gameNumber.isOdd
          : game.blueTeamId == widget.scheme.teamAId;
      final winnerIsA = game.winner == 'blue' ? blueIsA : !blueIsA;
      if (winnerIsA == teamA) score++;
    }
    if (_gameWinner != null) {
      final winnerIsA = _gameWinner == 'blue'
          ? _isBlueTeamA()
          : !_isBlueTeamA();
      if (winnerIsA == teamA) score++;
    }
    return score;
  }

  int _scoreForSide(_BpSide side) =>
      _teamScore(side == _BpSide.blue ? _isBlueTeamA() : !_isBlueTeamA());

  Set<int> _teamUsedHeroes(bool teamA) {
    final used = <int>{};
    for (final game in _history) {
      final blueIsA = game.blueTeamId.isEmpty
          ? game.gameNumber.isOdd
          : game.blueTeamId == widget.scheme.teamAId;
      final picks = blueIsA == teamA ? game.bluePicks : game.redPicks;
      used.addAll(picks.whereType<int>().where((id) => id > 0));
    }
    return used;
  }

  bool _activeSideIsTeamA() {
    final step = _currentStep;
    if (step == null) return _isBlueTeamA();
    return step.side == _BpSide.blue ? _isBlueTeamA() : !_isBlueTeamA();
  }

  bool _canSelectHero(int heroId) {
    if (_isPeakMode) {
      return !_isSaved &&
          !_peakRevealed &&
          heroId > 0 &&
          !_peakEnemyPicks.contains(heroId);
    }
    final step = _currentStep;
    if (!_canAct || heroId <= 0 || step == null) return false;
    final inCurrentDraft = <int>{
      ..._blueBans.whereType<int>(),
      ..._redBans.whereType<int>(),
      ..._bluePicks.whereType<int>(),
      ..._redPicks.whereType<int>(),
    };
    if (inCurrentDraft.contains(heroId)) return false;
    final activeTeamIsA = _activeSideIsTeamA();
    if (step.type == _BpSlotType.pick) {
      return !_teamUsedHeroes(activeTeamIsA).contains(heroId);
    }
    return !_teamUsedHeroes(!activeTeamIsA).contains(heroId);
  }

  _BpHeroStatus _heroStatus(int heroId) {
    if (_isPeakMode) {
      if (_peakUserPicks.contains(heroId)) return _BpHeroStatus.picked;
      if (_peakEnemyPicks.contains(heroId)) return _BpHeroStatus.usedByOpponent;
      return _BpHeroStatus.available;
    }
    if (_blueBans.contains(heroId) || _redBans.contains(heroId)) {
      return _BpHeroStatus.banned;
    }
    if (_bluePicks.contains(heroId) || _redPicks.contains(heroId)) {
      return _BpHeroStatus.picked;
    }
    final activeTeamIsA = _activeSideIsTeamA();
    if (_teamUsedHeroes(activeTeamIsA).contains(heroId)) {
      return _BpHeroStatus.usedByActiveTeam;
    }
    if (_teamUsedHeroes(!activeTeamIsA).contains(heroId)) {
      return _BpHeroStatus.usedByOpponent;
    }
    return _BpHeroStatus.available;
  }

  Future<void> _revealPeakEnemy() async {
    if (!_isPeakMode || _peakUserPicks.length != 5 || _isPeakGenerating) {
      return;
    }
    final heroes =
        ref.read(heroGalleryProvider).valueOrNull ?? const <HeroSummary>[];
    setState(() => _isPeakGenerating = true);
    try {
      final settings = await ref.read(appSettingsControllerProvider.future);
      final result = await ref
          .read(teamBuilderRepositoryProvider)
          .loadRecommendations(
            regionId: settings.region.regionId,
            enemyPicks: _peakUserPicks,
            mySide: 'red',
            slotType: 'pick',
            recommendType: TeamRecommendType.counter,
            limit: 120,
          );
      final byId = {for (final hero in heroes) int.tryParse(hero.id): hero};
      final picked = <int>[];
      final usedPositions = <int>{};
      final excluded = {..._peakUserPicks};
      for (final recommendation in result.recommendations) {
        final id = recommendation.heroId;
        final hero = byId[id];
        final position = recommendation.mainJob > 0
            ? recommendation.mainJob
            : hero?.position;
        if (id <= 0 || excluded.contains(id) || picked.contains(id)) continue;
        if (position != null &&
            position > 0 &&
            usedPositions.contains(position)) {
          continue;
        }
        picked.add(id);
        if (position != null && position > 0) usedPositions.add(position);
        if (picked.length == 5) break;
      }
      for (final hero in heroes) {
        final id = int.tryParse(hero.id) ?? 0;
        if (picked.length == 5) break;
        if (id <= 0 || excluded.contains(id) || picked.contains(id)) continue;
        if (hero.position != null && usedPositions.contains(hero.position)) {
          continue;
        }
        picked.add(id);
        if (hero.position != null) usedPositions.add(hero.position!);
      }
      for (final hero in heroes) {
        final id = int.tryParse(hero.id) ?? 0;
        if (picked.length == 5) break;
        if (id > 0 && !excluded.contains(id) && !picked.contains(id)) {
          picked.add(id);
        }
      }
      if (!mounted) return;
      setState(() {
        _peakEnemyPicks = picked;
        _peakRevealed = true;
      });
    } catch (_) {
      final fallback = heroes
          .map((hero) => int.tryParse(hero.id) ?? 0)
          .where((id) => id > 0 && !_peakUserPicks.contains(id))
          .take(5)
          .toList(growable: false);
      if (mounted) {
        setState(() {
          _peakEnemyPicks = fallback;
          _peakRevealed = true;
        });
      }
    } finally {
      if (mounted) setState(() => _isPeakGenerating = false);
    }
  }

  Future<void> _saveDraft() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await ref
          .read(bpRepositoryProvider)
          .saveDraftState(
            widget.scheme.id,
            gameNumber: _gameNumber,
            draftState: BpDraftState(
              blueBans: _blueBans,
              redBans: _redBans,
              bluePicks: _isPeakMode
                  ? _slotsFromIds(_peakUserPicks)
                  : _bluePicks,
              redPicks: _isPeakMode
                  ? _slotsFromIds(_peakEnemyPicks)
                  : _redPicks,
              currentStepIndex: _isPeakMode ? -1 : _currentStepIndex,
              isStarted: _isPeakMode ? false : _isStarted,
              isSaved: _isFinished || _isSaved,
              timeLeft: _timeLeft,
              gameWinner: _gameWinner,
            ),
          );
      if (!mounted) return;
      if (_isFinished) setState(() => _isSaved = true);
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

  BpHistoryGame get _completedHistoryGame => BpHistoryGame(
    gameNumber: _gameNumber,
    blueTeamId: _isBlueTeamA() ? widget.scheme.teamAId : widget.scheme.teamBId,
    redTeamId: _isBlueTeamA() ? widget.scheme.teamBId : widget.scheme.teamAId,
    blueBans: _blueBans,
    redBans: _redBans,
    bluePicks: _isPeakMode ? _slotsFromIds(_peakUserPicks) : _bluePicks,
    redPicks: _isPeakMode ? _slotsFromIds(_peakEnemyPicks) : _redPicks,
    mode: _isPeakMode ? 'peak' : 'standard',
    winner: _gameWinner,
  );

  Future<void> _advanceSeries() async {
    if (_isAdvancing || _isHistoryMode || !_isSaved || _gameWinner == null) {
      return;
    }
    final nextHistory = [..._history, _completedHistoryGame];
    final isComplete = _isSeriesCompletedAfterThis;
    final loserIsTeamA = _gameWinner == 'blue'
        ? !_isBlueTeamA()
        : _isBlueTeamA();
    setState(() => _isAdvancing = true);
    try {
      await ref
          .read(bpRepositoryProvider)
          .advanceSeries(
            widget.scheme.id,
            nextGameNumber: isComplete ? _gameNumber : _gameNumber + 1,
            history: nextHistory,
          );
      if (!mounted) return;
      ref.invalidate(bpSchemeDetailProvider(widget.scheme.id));
      ref.invalidate(bpSchemesProvider);
      if (isComplete) {
        Navigator.of(context).maybePop();
        return;
      }
      setState(() {
        _history = nextHistory;
        _gameNumber++;
        _blueTeamIsA = widget.scheme.sideSelectionRule == 'alternating'
            ? !_blueTeamIsA
            : _nextGameLoserSide == _BpSide.blue
            ? loserIsTeamA
            : !loserIsTeamA;
        _isPeakMode = widget.scheme.boMode == 7 && _gameNumber == 7;
        _blueBans = List<int?>.filled(5, null);
        _redBans = List<int?>.filled(5, null);
        _bluePicks = List<int?>.filled(5, null);
        _redPicks = List<int?>.filled(5, null);
        _peakUserPicks = [];
        _peakEnemyPicks = [];
        _peakRevealed = false;
        _currentStepIndex = _isPeakMode ? -1 : 0;
        _timeLeft = _timerDuration;
        _isStarted = false;
        _isTimerRunning = false;
        _isSaved = false;
        _selectedHeroId = null;
        _gameWinner = null;
        _undoStack.clear();
        _redoStack.clear();
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to start the next BP game')),
      );
    } finally {
      if (mounted) setState(() => _isAdvancing = false);
    }
  }

  List<int?> _slotsFromIds(List<int> ids) => [
    ...ids.take(5),
    ...List<int?>.filled((5 - ids.length).clamp(0, 5).toInt(), null),
  ];

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
              blueTeamName: _blueTeamName,
              redTeamName: _redTeamName,
              isSaving: _isSaving,
              blueBans: _blueBans,
              redBans: _redBans,
              bluePicks: _isPeakMode
                  ? _slotsFromIds(_peakUserPicks)
                  : _bluePicks,
              redPicks: _isPeakMode
                  ? _slotsFromIds(_peakEnemyPicks)
                  : _redPicks,
              blueScore: _scoreForSide(_BpSide.blue),
              redScore: _scoreForSide(_BpSide.red),
              currentStep: _currentStep,
              activeSlotIndex: _activeSlotIndex,
              selectedHeroId: _selectedHeroId,
              timeLeft: _timeLeft,
              isStarted: _isStarted,
              isFinished: _isFinished,
              onBack: () => Navigator.of(context).maybePop(),
              onSave: _saveDraft,
              onTimerTap: _isStarted ? _toggleTimer : _resumeTimer,
            ),
            _BpLaneBar(
              lanes: _lanes,
              selectedLane: _selectedLane,
              onSelected: (lane) => setState(() => _selectedLane = lane),
              showBanned: _showBanned,
              showPicked: _showPicked,
              onToggleBanned: () => setState(() => _showBanned = !_showBanned),
              onTogglePicked: () => setState(() => _showPicked = !_showPicked),
            ),
            Expanded(
              child: Row(
                children: [
                  _BpTeamRail(
                    color: const Color(0xFF246BFF),
                    heroIds: _isPeakMode
                        ? _slotsFromIds(_peakUserPicks)
                        : _bluePicks,
                    active:
                        _currentStep?.side == _BpSide.blue &&
                        _currentStep?.type == _BpSlotType.pick,
                    activeSlotIndex: _activeSlotIndex,
                    selectedHeroId: _selectedHeroId,
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final crossAxisCount = (constraints.maxWidth / 70)
                                .floor()
                                .clamp(7, 14);
                            return GridView.builder(
                              padding: const EdgeInsets.fromLTRB(8, 8, 8, 60),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: 5,
                                    mainAxisSpacing: 5,
                                    childAspectRatio: 1.02,
                                  ),
                              itemCount: visibleHeroes.length,
                              itemBuilder: (context, index) {
                                final hero = visibleHeroes[index];
                                final heroId = int.tryParse(hero.id) ?? 0;
                                final status = _heroStatus(heroId);
                                if ((status == _BpHeroStatus.banned &&
                                        !_showBanned) ||
                                    (status == _BpHeroStatus.picked &&
                                        !_showPicked)) {
                                  return const SizedBox.shrink();
                                }
                                return _BpHeroPoolTile(
                                  hero: hero,
                                  status: status,
                                  selected: _selectedHeroId == heroId,
                                  allowPickedTap:
                                      _isPeakMode &&
                                      !_peakRevealed &&
                                      !_isSaved,
                                  onTap: () => _setSelectedHero(heroId),
                                );
                              },
                            );
                          },
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 6,
                          child: _BpFlowControls(
                            currentStep: _currentStep,
                            isHistoryMode: _isHistoryMode,
                            isStarted: _isStarted,
                            isFinished: _isFinished,
                            isSaved: _isSaved,
                            isPeakMode: _isPeakMode,
                            peakPickCount: _peakUserPicks.length,
                            isPeakGenerating: _isPeakGenerating,
                            isAdvancing: _isAdvancing,
                            isSeriesCompleted: _isSeriesCompletedAfterThis,
                            sideSelectionRule: widget.scheme.sideSelectionRule,
                            loserTeamName: _gameWinner == 'blue'
                                ? _redTeamName
                                : _blueTeamName,
                            nextGameLoserSide: _nextGameLoserSide,
                            selectedHeroId: _selectedHeroId,
                            canUndo: _undoStack.isNotEmpty,
                            canRedo: _redoStack.isNotEmpty,
                            onStart: _startBp,
                            onLockIn: _commitSelection,
                            onUndo: _undo,
                            onRedo: _redo,
                            onReset: _resetBp,
                            onSave: _saveDraft,
                            gameWinner: _gameWinner,
                            onWinnerChanged: (winner) =>
                                setState(() => _gameWinner = winner),
                            onPeakShow: _revealPeakEnemy,
                            onNextGame: _advanceSeries,
                            onNextGameLoserSide: (side) =>
                                setState(() => _nextGameLoserSide = side),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _BpTeamRail(
                    color: const Color(0xFFE83B43),
                    heroIds: _isPeakMode
                        ? _slotsFromIds(_peakEnemyPicks)
                        : _redPicks,
                    active:
                        _currentStep?.side == _BpSide.red &&
                        _currentStep?.type == _BpSlotType.pick,
                    activeSlotIndex: _activeSlotIndex,
                    selectedHeroId: _selectedHeroId,
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

enum _BpHeroStatus {
  available,
  banned,
  picked,
  usedByActiveTeam,
  usedByOpponent,
}

class _BpEditorTopBar extends StatelessWidget {
  const _BpEditorTopBar({
    required this.scheme,
    required this.blueTeamName,
    required this.redTeamName,
    required this.isSaving,
    required this.blueBans,
    required this.redBans,
    required this.bluePicks,
    required this.redPicks,
    required this.blueScore,
    required this.redScore,
    required this.currentStep,
    required this.activeSlotIndex,
    required this.selectedHeroId,
    required this.timeLeft,
    required this.isStarted,
    required this.isFinished,
    required this.onBack,
    required this.onSave,
    required this.onTimerTap,
  });

  final BpSchemeSummary scheme;
  final String blueTeamName;
  final String redTeamName;
  final bool isSaving;
  final List<int?> blueBans;
  final List<int?> redBans;
  final List<int?> bluePicks;
  final List<int?> redPicks;
  final int blueScore;
  final int redScore;
  final _BpStep? currentStep;
  final int activeSlotIndex;
  final int? selectedHeroId;
  final int timeLeft;
  final bool isStarted;
  final bool isFinished;
  final VoidCallback onBack;
  final VoidCallback onSave;
  final VoidCallback onTimerTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 82,
      child: Row(
        children: [
          IconButton.filledTonal(
            tooltip: 'Exit BP editor',
            onPressed: onBack,
            icon: const Icon(Icons.logout_rounded),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _BpBanSlots(
                  color: const Color(0xFF246BFF),
                  heroIds: blueBans,
                  active:
                      currentStep?.side == _BpSide.blue &&
                      currentStep?.type == _BpSlotType.ban,
                  activeSlotIndex: activeSlotIndex,
                  selectedHeroId: selectedHeroId,
                ),
                const SizedBox(width: 6),
                _BpScorePill(
                  label: blueTeamName,
                  score: blueScore,
                  color: const Color(0xFF246BFF),
                ),
                InkWell(
                  onTap: onTimerTap,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 52,
                    height: 52,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF171923),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: timeLeft <= 10 ? AppTheme.error : Colors.white24,
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isFinished ? 'DONE' : '$timeLeft',
                          style: TextStyle(
                            color: timeLeft <= 10
                                ? AppTheme.error
                                : Colors.white,
                            fontSize: isFinished ? 12 : 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          currentStep == null
                              ? 'READY'
                              : currentStep!.type == _BpSlotType.ban
                              ? 'BAN'
                              : 'PICK',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _BpScorePill(
                  label: redTeamName,
                  score: redScore,
                  color: const Color(0xFFE83B43),
                ),
                const SizedBox(width: 6),
                _BpBanSlots(
                  color: const Color(0xFFE83B43),
                  heroIds: redBans,
                  active:
                      currentStep?.side == _BpSide.red &&
                      currentStep?.type == _BpSlotType.ban,
                  activeSlotIndex: activeSlotIndex,
                  selectedHeroId: selectedHeroId,
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

class _BpBanSlots extends StatelessWidget {
  const _BpBanSlots({
    required this.color,
    required this.heroIds,
    required this.active,
    required this.activeSlotIndex,
    required this.selectedHeroId,
  });

  final Color color;
  final List<int?> heroIds;
  final bool active;
  final int activeSlotIndex;
  final int? selectedHeroId;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < 5; index++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: _BpSlot(
              heroId: index < heroIds.length ? heroIds[index] : null,
              color: color,
              size: 28,
              active: active && index == activeSlotIndex,
              previewHeroId: active && index == activeSlotIndex
                  ? selectedHeroId
                  : null,
              banned: true,
            ),
          ),
      ],
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
      width: 110,
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
          const SizedBox(width: 6),
          Text(
            label.isEmpty ? 'TEAM' : label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
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
    required this.showBanned,
    required this.showPicked,
    required this.onToggleBanned,
    required this.onTogglePicked,
  });

  final List<(String, IconData, int?)> lanes;
  final int? selectedLane;
  final ValueChanged<int?> onSelected;
  final bool showBanned;
  final bool showPicked;
  final VoidCallback onToggleBanned;
  final VoidCallback onTogglePicked;

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
              child: IconButton(
                tooltip: lane.$1,
                onPressed: () => onSelected(lane.$3),
                icon: Icon(
                  lane.$2,
                  size: selectedLane == lane.$3 ? 21 : 18,
                  color: selectedLane == lane.$3
                      ? Colors.white
                      : AppTheme.muted,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: selectedLane == lane.$3
                      ? AppTheme.gold.withValues(alpha: 0.75)
                      : Colors.transparent,
                  minimumSize: const Size(34, 34),
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          const SizedBox(width: 18),
          IconButton(
            tooltip: 'Show banned heroes',
            onPressed: onToggleBanned,
            icon: Icon(
              showBanned ? Icons.block_rounded : Icons.block_outlined,
              color: showBanned ? AppTheme.error : AppTheme.muted,
              size: 20,
            ),
          ),
          IconButton(
            tooltip: 'Show picked heroes',
            onPressed: onTogglePicked,
            icon: Icon(
              showPicked
                  ? Icons.check_circle_rounded
                  : Icons.check_circle_outline,
              color: showPicked ? AppTheme.success : AppTheme.muted,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _BpTeamRail extends StatelessWidget {
  const _BpTeamRail({
    required this.color,
    required this.heroIds,
    required this.active,
    required this.activeSlotIndex,
    required this.selectedHeroId,
  });

  final Color color;
  final List<int?> heroIds;
  final bool active;
  final int activeSlotIndex;
  final int? selectedHeroId;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 68,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final slotSize = ((constraints.maxHeight - 40) / 5)
              .clamp(28.0, 44.0)
              .toDouble();
          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var index = 0; index < 5; index++)
                _BpSlot(
                  heroId: index < heroIds.length ? heroIds[index] : null,
                  color: color,
                  size: slotSize,
                  active: active && index == activeSlotIndex,
                  previewHeroId: active && index == activeSlotIndex
                      ? selectedHeroId
                      : null,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _BpFlowControls extends StatelessWidget {
  const _BpFlowControls({
    required this.currentStep,
    required this.isHistoryMode,
    required this.isStarted,
    required this.isFinished,
    required this.isSaved,
    required this.isPeakMode,
    required this.peakPickCount,
    required this.isPeakGenerating,
    required this.isAdvancing,
    required this.isSeriesCompleted,
    required this.sideSelectionRule,
    required this.loserTeamName,
    required this.nextGameLoserSide,
    required this.selectedHeroId,
    required this.canUndo,
    required this.canRedo,
    required this.onStart,
    required this.onLockIn,
    required this.onUndo,
    required this.onRedo,
    required this.onReset,
    required this.onSave,
    required this.gameWinner,
    required this.onWinnerChanged,
    required this.onPeakShow,
    required this.onNextGame,
    required this.onNextGameLoserSide,
  });

  final _BpStep? currentStep;
  final bool isHistoryMode;
  final bool isStarted;
  final bool isFinished;
  final bool isSaved;
  final bool isPeakMode;
  final int peakPickCount;
  final bool isPeakGenerating;
  final bool isAdvancing;
  final bool isSeriesCompleted;
  final String sideSelectionRule;
  final String loserTeamName;
  final _BpSide nextGameLoserSide;
  final int? selectedHeroId;
  final bool canUndo;
  final bool canRedo;
  final VoidCallback onStart;
  final VoidCallback onLockIn;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onReset;
  final VoidCallback onSave;
  final String? gameWinner;
  final ValueChanged<String> onWinnerChanged;
  final VoidCallback onPeakShow;
  final VoidCallback onNextGame;
  final ValueChanged<_BpSide> onNextGameLoserSide;

  @override
  Widget build(BuildContext context) {
    if (isHistoryMode) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton.filledTonal(
          tooltip: 'Undo',
          onPressed: canUndo && !isSaved ? onUndo : null,
          icon: const Icon(Icons.undo_rounded, size: 18),
        ),
        const SizedBox(width: 8),
        if (isPeakMode && !isFinished)
          FilledButton.icon(
            onPressed: peakPickCount == 5 && !isPeakGenerating
                ? onPeakShow
                : null,
            icon: const Icon(Icons.visibility_rounded, size: 17),
            label: Text(
              isPeakGenerating
                  ? '生成对手阵容'
                  : peakPickCount == 5
                  ? '展示对手'
                  : '还需选择 ${5 - peakPickCount} 人',
            ),
          )
        else if (!isStarted && !isFinished)
          FilledButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.play_arrow_rounded, size: 17),
            label: const Text('开始 BP'),
          )
        else if (!isFinished)
          FilledButton.icon(
            onPressed:
                currentStep?.type == _BpSlotType.ban || selectedHeroId != null
                ? onLockIn
                : null,
            icon: const Icon(Icons.lock_rounded, size: 17),
            label: Text(
              currentStep?.type == _BpSlotType.ban && selectedHeroId == null
                  ? '跳过禁用'
                  : '锁定',
            ),
          )
        else if (!isSaved)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton(
                onPressed: () => onWinnerChanged('blue'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF246BFF),
                  side: BorderSide(
                    color: gameWinner == 'blue'
                        ? const Color(0xFF246BFF)
                        : Colors.white24,
                  ),
                ),
                child: const Text('蓝方胜'),
              ),
              const SizedBox(width: 6),
              OutlinedButton(
                onPressed: () => onWinnerChanged('red'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.error,
                  side: BorderSide(
                    color: gameWinner == 'red'
                        ? AppTheme.error
                        : Colors.white24,
                  ),
                ),
                child: const Text('红方胜'),
              ),
              const SizedBox(width: 6),
              FilledButton.icon(
                onPressed: gameWinner == null ? null : onSave,
                icon: const Icon(Icons.save_rounded, size: 17),
                label: const Text('完成 BP'),
              ),
            ],
          )
        else if (isSeriesCompleted)
          FilledButton.icon(
            onPressed: isAdvancing ? null : onNextGame,
            icon: const Icon(Icons.emoji_events_outlined, size: 17),
            label: const Text('结束系列赛'),
          )
        else
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (sideSelectionRule == 'loser_selects') ...[
                Text(
                  '${loserTeamName.isEmpty ? '败方' : loserTeamName} 选边',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 5),
                IconButton.filledTonal(
                  tooltip: 'Loser chooses blue side',
                  onPressed: () => onNextGameLoserSide(_BpSide.blue),
                  icon: Icon(
                    Icons.circle,
                    size: 15,
                    color: nextGameLoserSide == _BpSide.blue
                        ? const Color(0xFF246BFF)
                        : Colors.white54,
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Loser chooses red side',
                  onPressed: () => onNextGameLoserSide(_BpSide.red),
                  icon: Icon(
                    Icons.circle,
                    size: 15,
                    color: nextGameLoserSide == _BpSide.red
                        ? const Color(0xFFE83B43)
                        : Colors.white54,
                  ),
                ),
                const SizedBox(width: 5),
              ],
              FilledButton.icon(
                onPressed: isAdvancing ? null : onNextGame,
                icon: const Icon(Icons.skip_next_rounded, size: 17),
                label: Text(isAdvancing ? '保存中' : '下一局'),
              ),
            ],
          ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          tooltip: 'Redo',
          onPressed: canRedo && !isSaved ? onRedo : null,
          icon: const Icon(Icons.redo_rounded, size: 18),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          tooltip: 'Reset BP flow',
          onPressed: onReset,
          icon: const Icon(Icons.restart_alt_rounded, size: 18),
        ),
      ],
    );
  }
}

class _BpSlot extends StatelessWidget {
  const _BpSlot({
    required this.heroId,
    required this.color,
    this.size = 48,
    this.active = false,
    this.previewHeroId,
    this.banned = false,
  });

  final int? heroId;
  final Color color;
  final double size;
  final bool active;
  final int? previewHeroId;
  final bool banned;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: active ? color : color.withValues(alpha: 0.7),
          width: active ? 3 : 2,
        ),
        color: color.withValues(alpha: 0.08),
      ),
      child: (heroId ?? previewHeroId) == null
          ? Center(
              child: Text('•', style: TextStyle(color: color, fontSize: 22)),
            )
          : Stack(
              fit: StackFit.expand,
              children: [
                Opacity(
                  opacity: heroId == null ? 0.6 : 1,
                  child: AppImage(
                    url:
                        'https://hokhelper.com/static/game/hero/${heroId ?? previewHeroId}.png',
                    borderRadius: 999,
                    semanticLabel: 'Selected hero',
                  ),
                ),
                if (banned && heroId != null && heroId! > 0)
                  const Center(
                    child: Icon(Icons.block_rounded, color: AppTheme.error),
                  ),
                if (heroId == -1)
                  const Center(
                    child: Icon(
                      Icons.remove_circle_outline,
                      color: Colors.white38,
                    ),
                  ),
              ],
            ),
    );
  }
}

class _BpHeroPoolTile extends StatelessWidget {
  const _BpHeroPoolTile({
    required this.hero,
    required this.status,
    required this.selected,
    this.allowPickedTap = false,
    this.onTap,
  });

  final HeroSummary hero;
  final _BpHeroStatus status;
  final bool selected;
  final bool allowPickedTap;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isInteractive =
        onTap != null &&
        (status == _BpHeroStatus.available ||
            (allowPickedTap && status == _BpHeroStatus.picked));
    final heroId = hero.id.isEmpty ? hero.heroId : hero.id;
    final url = hero.avatar.isNotEmpty
        ? hero.avatar
        : 'https://hokhelper.com/static/game/hero/$heroId.png';
    return Material(
      color: status == _BpHeroStatus.available && !selected
          ? const Color(0xFF0A1020)
          : const Color(0xFF070A12),
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        onTap: isInteractive ? onTap : null,
        borderRadius: BorderRadius.circular(7),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: status == _BpHeroStatus.available ? 1 : 0.28,
              child: AppImage(
                url: url,
                width: 48,
                height: 48,
                borderRadius: 999,
                semanticLabel: hero.name,
              ),
            ),
            if (selected)
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.gold, width: 2),
                  shape: BoxShape.circle,
                ),
              )
            else if (status != _BpHeroStatus.available)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                  border: Border.all(color: _statusColor(status), width: 2),
                ),
                child: Icon(
                  _statusIcon(status),
                  color: _statusColor(status),
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Color _statusColor(_BpHeroStatus status) => switch (status) {
  _BpHeroStatus.banned || _BpHeroStatus.usedByOpponent => AppTheme.error,
  _BpHeroStatus.picked || _BpHeroStatus.usedByActiveTeam => AppTheme.gold,
  _BpHeroStatus.available => AppTheme.muted,
};

IconData _statusIcon(_BpHeroStatus status) => switch (status) {
  _BpHeroStatus.banned => Icons.block_rounded,
  _BpHeroStatus.picked => Icons.check_rounded,
  _BpHeroStatus.usedByActiveTeam => Icons.person_off_rounded,
  _BpHeroStatus.usedByOpponent => Icons.shield_outlined,
  _BpHeroStatus.available => Icons.circle_outlined,
};

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
