import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../heroes/domain/hero_summary.dart';
import '../../heroes/presentation/hero_gallery_screen.dart';
import '../domain/tierlist_scheme_summary.dart';
import 'tierlist_tool_screen.dart';

final tierListSchemeDetailProvider =
    FutureProvider.family<TierListSchemeSummary, String>((ref, schemeId) {
      return ref.watch(tierListToolRepositoryProvider).loadScheme(schemeId);
    });

const _tierListEditorColors = [
  'bg-red-600',
  'bg-orange-500',
  'bg-yellow-500',
  'bg-green-500',
  'bg-teal-500',
  'bg-blue-500',
  'bg-indigo-500',
  'bg-purple-500',
  'bg-pink-500',
  'bg-slate-500',
];

class TierListSchemeDetailScreen extends ConsumerStatefulWidget {
  const TierListSchemeDetailScreen({
    super.key,
    required this.schemeId,
    this.initialEditMode = false,
  });

  final String schemeId;
  final bool initialEditMode;

  @override
  ConsumerState<TierListSchemeDetailScreen> createState() =>
      _TierListSchemeDetailScreenState();
}

class _TierListSchemeDetailScreenState
    extends ConsumerState<TierListSchemeDetailScreen> {
  final TextEditingController _nameController = TextEditingController();
  final GlobalKey _boardBoundaryKey = GlobalKey();
  final Map<String, TextEditingController> _labelControllers = {};
  final Map<String, TextEditingController> _heroIdControllers = {};
  final Map<String, String> _editedLabels = {};
  List<TierListSchemeRowSummary> _editedRows = const [];
  String? _hydratedSchemeId;
  TierListSchemeSummary? _savedScheme;
  bool _isSaving = false;
  bool _showLaneBoard = false;
  int? _boardLanePosition;

  @override
  void dispose() {
    _nameController.dispose();
    for (final controller in _labelControllers.values) {
      controller.dispose();
    }
    for (final controller in _heroIdControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(tierListSchemeDetailProvider(widget.schemeId));

    return AppAsyncView<TierListSchemeSummary>(
      value: value,
      retry: () =>
          ref.invalidate(tierListSchemeDetailProvider(widget.schemeId)),
      data: (scheme) {
        final displayScheme = _displaySchemeFor(scheme);
        void save() => _saveScheme(_schemeWithEditedRows(displayScheme));
        final heroesValue = widget.initialEditMode
            ? ref.watch(heroGalleryProvider)
            : const AsyncValue<List<HeroSummary>>.data(<HeroSummary>[]);
        final heroes = heroesValue.valueOrNull ?? const <HeroSummary>[];
        final heroesById = _heroesById(heroes);

        if (widget.initialEditMode) {
          final size = MediaQuery.sizeOf(context);
          if (size.height > size.width) {
            return Scaffold(
              backgroundColor: AppTheme.bg,
              body: _TierListLandscapePrompt(
                schemeName: displayScheme.name,
                onBack: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/tools/tier-list');
                  }
                },
              ),
            );
          }

          return Scaffold(
            backgroundColor: AppTheme.bg,
            body: SafeArea(
              key: const ValueKey('tier-editor-fullscreen'),
              child: Column(
                children: [
                  _TierListEditorToolbar(
                    schemeName: displayScheme.name,
                    nameController: _nameController,
                    isSaving: _isSaving,
                    isLaneBoardMode: _showLaneBoard,
                    onBack: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/tools/tier-list');
                      }
                    },
                    onSave: save,
                    onExport: () => _exportBoardImage(displayScheme),
                    onToggleLaneBoard: () {
                      setState(() {
                        _showLaneBoard = !_showLaneBoard;
                        if (!_showLaneBoard) {
                          _boardLanePosition = null;
                        }
                      });
                    },
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                      child: _TierListEditorWorkspace(
                        scheme: displayScheme,
                        heroes: heroes,
                        heroesById: heroesById,
                        heroesValue: heroesValue,
                        boardBoundaryKey: _boardBoundaryKey,
                        labelControllers: _labelControllers,
                        showLaneBoard: _showLaneBoard,
                        boardLanePosition: _boardLanePosition,
                        onBoardLaneChanged: (value) {
                          setState(() {
                            _boardLanePosition = value;
                          });
                        },
                        onLabelChanged: _updateRowLabel,
                        onColorChanged: _updateRowColor,
                        onHeroAdded: _addHeroToRow,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Stack(
          children: [
            RefreshIndicator(
              onRefresh: () => ref.refresh(
                tierListSchemeDetailProvider(widget.schemeId).future,
              ),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  widget.initialEditMode ? 104 : 28,
                ),
                children: [
                  const AppSectionHeader(title: 'Tier List Detail'),
                  const SizedBox(height: 8),
                  Text(
                    'Inspect a shared portal tier list in a mobile-friendly layout.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
                  ),
                  const SizedBox(height: 18),
                  if (widget.initialEditMode) ...[
                    _EditorModeBanner(isSaving: _isSaving, onSave: save),
                    const SizedBox(height: 12),
                  ],
                  _TierListDetailCard(
                    scheme: displayScheme,
                    heroesById: heroesById,
                    isEditMode: widget.initialEditMode,
                    isSaving: _isSaving,
                    nameController: _nameController,
                    labelControllers: _labelControllers,
                    heroIdControllers: _heroIdControllers,
                    onLabelChanged: _updateRowLabel,
                    onColorChanged: _updateRowColor,
                    onHeroAdded: _addHeroToRow,
                    onHeroRemoved: _removeHeroFromRow,
                    onMoveRow: _moveRow,
                    onSave: save,
                  ),
                ],
              ),
            ),
            if (widget.initialEditMode)
              Positioned(
                right: 20,
                bottom: 20,
                child: FloatingActionButton.extended(
                  key: const ValueKey('tier-list-save-changes-floating'),
                  heroTag: 'tier-list-save-changes',
                  onPressed: _isSaving ? null : save,
                  icon: _isSaving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Save changes'),
                ),
              ),
          ],
        );
      },
    );
  }

  TierListSchemeSummary _displaySchemeFor(TierListSchemeSummary loadedScheme) {
    final loadedWithRows = _schemeWithDefaultRows(loadedScheme);
    final baseScheme =
        _savedScheme != null && _savedScheme!.id == loadedWithRows.id
        ? _schemeWithDefaultRows(_savedScheme!)
        : loadedWithRows;
    if (_hydratedSchemeId != baseScheme.id) {
      _hydratedSchemeId = baseScheme.id;
      _editedLabels
        ..clear()
        ..addEntries(baseScheme.rows.map((row) => MapEntry(row.id, row.label)));
      _editedRows = baseScheme.rows;
      _nameController.text = baseScheme.name;
      final rowIds = baseScheme.rows.map((row) => row.id).toSet();
      final removedIds = _labelControllers.keys
          .where((rowId) => !rowIds.contains(rowId))
          .toList(growable: false);
      for (final rowId in removedIds) {
        _labelControllers.remove(rowId)?.dispose();
        _heroIdControllers.remove(rowId)?.dispose();
      }
      for (final row in baseScheme.rows) {
        final controller = _labelControllers.putIfAbsent(
          row.id,
          () => TextEditingController(),
        );
        controller.text = row.label;
        _heroIdControllers.putIfAbsent(row.id, () => TextEditingController());
      }
    }
    return baseScheme.copyWith(
      rows: [
        for (final row in _editedRows) row.copyWith(label: _rowLabel(row)),
      ],
    );
  }

  void _updateRowLabel(String rowId, String label) {
    _editedLabels[rowId] = label;
  }

  String _rowLabel(TierListSchemeRowSummary row) {
    final controllerText = _labelControllers[row.id]?.text.trim();
    if (controllerText != null && controllerText.isNotEmpty) {
      return controllerText;
    }
    final editedLabel = _editedLabels[row.id]?.trim();
    if (editedLabel != null && editedLabel.isNotEmpty) {
      return editedLabel;
    }
    return row.label;
  }

  TierListSchemeSummary _schemeWithEditedRows(TierListSchemeSummary scheme) {
    final editedName = _nameController.text.trim();
    return scheme.copyWith(
      name: editedName.isEmpty ? scheme.name : editedName,
      rows: [
        for (final row in _editedRows) row.copyWith(label: _rowLabel(row)),
      ],
    );
  }

  void _updateRowColor(String rowId, String color) {
    setState(() {
      _editedRows = [
        for (final row in _editedRows)
          row.id == rowId ? row.copyWith(color: color) : row,
      ];
    });
  }

  void _removeHeroFromRow(String rowId, int heroId) {
    setState(() {
      _editedRows = [
        for (final row in _editedRows)
          if (row.id == rowId)
            row.copyWith(
              heroIds: row.heroIds.where((id) => id != heroId).toList(),
              heroCount: row.heroIds.where((id) => id != heroId).length,
            )
          else
            row,
      ];
    });
  }

  void _addHeroToRow(String rowId, int heroId) {
    if (heroId <= 0) {
      return;
    }
    setState(() {
      _editedRows = [
        for (final row in _editedRows)
          if (row.id == rowId && !row.heroIds.contains(heroId))
            row.copyWith(
              heroIds: [...row.heroIds, heroId],
              heroCount: row.heroIds.length + 1,
            )
          else
            row,
      ];
      _heroIdControllers[rowId]?.clear();
    });
  }

  void _moveRow(String rowId, int offset) {
    final index = _editedRows.indexWhere((row) => row.id == rowId);
    if (index < 0) {
      return;
    }
    final targetIndex = index + offset;
    if (targetIndex < 0 || targetIndex >= _editedRows.length) {
      return;
    }
    final rows = [..._editedRows];
    final row = rows.removeAt(index);
    rows.insert(targetIndex, row);
    setState(() {
      _editedRows = rows;
    });
  }

  Future<void> _saveScheme(TierListSchemeSummary scheme) async {
    if (_isSaving) {
      return;
    }
    setState(() {
      _isSaving = true;
    });
    try {
      final saved = await ref
          .read(tierListToolRepositoryProvider)
          .updateScheme(scheme);
      if (!mounted) {
        return;
      }
      setState(() {
        _savedScheme = saved;
        _hydratedSchemeId = null;
        _isSaving = false;
      });
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(const SnackBar(content: Text('Tier list saved')));
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSaving = false;
      });
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to save tier list')),
      );
    }
  }

  Future<void> _exportBoardImage(TierListSchemeSummary scheme) async {
    try {
      final bytes = utf8.encode(_tierListSvg(scheme));
      if (bytes.isEmpty) {
        throw StateError('Tier board export is empty');
      }

      final directory = _exportDirectory();
      final safeName = scheme.name
          .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '-')
          .replaceAll(RegExp(r'-+'), '-')
          .replaceAll(RegExp(r'^-|-$'), '');
      final file = File(
        '${directory.path}/${safeName.isEmpty ? 'tier-list' : safeName}-${scheme.id}.svg',
      );
      file.writeAsBytesSync(bytes, flush: true);
      if (!mounted) {
        return;
      }
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text('Tier list image saved: ${file.path}')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to download tier list image')),
      );
    }
  }
}

Directory _exportDirectory() {
  if (Platform.isAndroid) {
    final downloads = Directory('/storage/emulated/0/Download');
    if (downloads.existsSync()) {
      return downloads;
    }
  }
  final directory = Directory(
    '${Directory.systemTemp.path}/hokhelper-tier-list',
  );
  if (!directory.existsSync()) {
    directory.createSync(recursive: true);
  }
  return directory;
}

String _tierListSvg(TierListSchemeSummary scheme) {
  const width = 900;
  const rowHeight = 92;
  final height = 110 + rowHeight * scheme.rows.length;
  final buffer = StringBuffer()
    ..writeln(
      '<svg xmlns="http://www.w3.org/2000/svg" width="$width" height="$height" viewBox="0 0 $width $height">',
    )
    ..writeln('<rect width="100%" height="100%" fill="#020617"/>')
    ..writeln(
      '<text x="24" y="56" fill="#F8FAFC" font-size="34" font-weight="900" font-family="Arial, sans-serif">${_xmlEscape(scheme.name)}</text>',
    );

  var y = 86;
  for (final row in scheme.rows) {
    final color = _colorToHex(
      _tierColorToken(row.color, fallbackLabel: row.label),
    );
    final count = row.heroCount == 1 ? '1 hero' : '${row.heroCount} heroes';
    buffer
      ..writeln(
        '<rect x="24" y="$y" width="852" height="78" rx="14" fill="#071027" stroke="#1E293B"/>',
      )
      ..writeln(
        '<rect x="24" y="$y" width="120" height="78" rx="14" fill="$color"/>',
      )
      ..writeln(
        '<text x="62" y="${y + 50}" fill="#FFFFFF" font-size="30" font-style="italic" font-weight="900" font-family="Arial, sans-serif">${_xmlEscape(row.label)}</text>',
      )
      ..writeln(
        '<text x="170" y="${y + 48}" fill="#94A3B8" font-size="22" font-weight="800" font-family="Arial, sans-serif">${_xmlEscape(count)}</text>',
      );
    y += rowHeight;
  }

  buffer.writeln('</svg>');
  return buffer.toString();
}

String _xmlEscape(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}

String _colorToHex(Color color) {
  final value = color.toARGB32() & 0xFFFFFF;
  return '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

TierListSchemeSummary _schemeWithDefaultRows(TierListSchemeSummary scheme) {
  if (scheme.rows.isNotEmpty) {
    return scheme;
  }
  return scheme.copyWith(
    rows: const [
      TierListSchemeRowSummary(
        id: 'default-t0',
        label: 'T0',
        color: 'bg-red-600',
        heroCount: 0,
      ),
      TierListSchemeRowSummary(
        id: 'default-t1',
        label: 'T1',
        color: 'bg-orange-500',
        heroCount: 0,
      ),
      TierListSchemeRowSummary(
        id: 'default-t2',
        label: 'T2',
        color: 'bg-yellow-500',
        heroCount: 0,
      ),
      TierListSchemeRowSummary(
        id: 'default-t3',
        label: 'T3',
        color: 'bg-green-500',
        heroCount: 0,
      ),
      TierListSchemeRowSummary(
        id: 'default-t4',
        label: 'T4',
        color: 'bg-slate-500',
        heroCount: 0,
      ),
    ],
  );
}

Map<int, HeroSummary> _heroesById(List<HeroSummary> heroes) {
  final result = <int, HeroSummary>{};
  for (final hero in heroes) {
    final ids = [
      int.tryParse(hero.id),
      int.tryParse(hero.heroId),
    ].whereType<int>();
    for (final id in ids) {
      result[id] = hero;
    }
  }
  return result;
}

class _TierListEditorToolbar extends StatelessWidget {
  const _TierListEditorToolbar({
    required this.schemeName,
    required this.nameController,
    required this.isSaving,
    required this.isLaneBoardMode,
    required this.onBack,
    required this.onSave,
    required this.onExport,
    required this.onToggleLaneBoard,
  });

  final String schemeName;
  final TextEditingController nameController;
  final bool isSaving;
  final bool isLaneBoardMode;
  final VoidCallback onBack;
  final VoidCallback onSave;
  final VoidCallback onExport;
  final VoidCallback onToggleLaneBoard;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey('tier-editor-toolbar'),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 4, 8, 5),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Back',
                onPressed: onBack,
                style: IconButton.styleFrom(
                  minimumSize: const Size(32, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.zero,
                ),
                icon: const Icon(Icons.close_rounded),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  key: const ValueKey('tier-list-name-field'),
                  controller: nameController,
                  minLines: 1,
                  maxLines: 1,
                  textInputAction: TextInputAction.done,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.text,
                    fontWeight: FontWeight.w900,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _ToolbarButton(
                buttonKey: const ValueKey('tier-lane-board-toggle'),
                tooltip: 'Lane tier view',
                icon: Icons.account_tree_outlined,
                isSelected: isLaneBoardMode,
                onPressed: onToggleLaneBoard,
              ),
              const SizedBox(width: 6),
              _ToolbarButton(
                buttonKey: const ValueKey('tier-list-download-image'),
                tooltip: 'Export',
                icon: Icons.file_download_outlined,
                onPressed: onExport,
              ),
              const SizedBox(width: 6),
              FilledButton(
                key: const ValueKey('tier-list-save-changes-top'),
                onPressed: isSaving ? null : onSave,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: const Size(34, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: isSaving
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    this.buttonKey,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.isSelected = false,
  });

  final Key? buttonKey;
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      key: buttonKey,
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: isSelected
            ? AppTheme.gold
            : Colors.white.withValues(alpha: 0.05),
        foregroundColor: AppTheme.text,
        minimumSize: const Size(32, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: EdgeInsets.zero,
      ),
      icon: Icon(icon, size: 18),
    );
  }
}

class _TierListLandscapePrompt extends StatelessWidget {
  const _TierListLandscapePrompt({
    required this.schemeName,
    required this.onBack,
  });

  final String schemeName;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      key: const ValueKey('tier-editor-landscape-prompt'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                tooltip: 'Back',
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
              ),
            ),
            const Spacer(),
            Icon(
              Icons.screen_rotation_alt_rounded,
              color: AppTheme.gold,
              size: 64,
            ),
            const SizedBox(height: 20),
            Text(
              'Rotate to landscape',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.text,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              schemeName,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.text,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'The tier editor uses a wide board and hero pool. Turn your phone sideways to start editing.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _TierListEditorWorkspace extends StatelessWidget {
  const _TierListEditorWorkspace({
    required this.scheme,
    required this.heroes,
    required this.heroesById,
    required this.heroesValue,
    required this.boardBoundaryKey,
    required this.labelControllers,
    required this.showLaneBoard,
    required this.boardLanePosition,
    required this.onBoardLaneChanged,
    required this.onLabelChanged,
    required this.onColorChanged,
    required this.onHeroAdded,
  });

  final TierListSchemeSummary scheme;
  final List<HeroSummary> heroes;
  final Map<int, HeroSummary> heroesById;
  final AsyncValue<List<HeroSummary>> heroesValue;
  final GlobalKey boardBoundaryKey;
  final Map<String, TextEditingController> labelControllers;
  final bool showLaneBoard;
  final int? boardLanePosition;
  final ValueChanged<int?> onBoardLaneChanged;
  final void Function(String rowId, String label) onLabelChanged;
  final void Function(String rowId, String color) onColorChanged;
  final void Function(String rowId, int heroId) onHeroAdded;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final poolWidth = (constraints.maxWidth * 0.34).clamp(220.0, 286.0);
        return Row(
          key: const ValueKey('tier-editor-board'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _TierBoardPanel(
                scheme: scheme,
                heroesById: heroesById,
                boundaryKey: boardBoundaryKey,
                labelControllers: labelControllers,
                showLaneBoard: showLaneBoard,
                lanePosition: boardLanePosition,
                onLaneChanged: onBoardLaneChanged,
                onLabelChanged: onLabelChanged,
                onColorChanged: onColorChanged,
                onHeroAdded: onHeroAdded,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: poolWidth,
              child: _HeroPoolPanel(value: heroesValue, heroes: heroes),
            ),
          ],
        );
      },
    );
  }
}

class _TierBoardPanel extends StatelessWidget {
  const _TierBoardPanel({
    required this.scheme,
    required this.heroesById,
    required this.boundaryKey,
    required this.labelControllers,
    required this.showLaneBoard,
    required this.lanePosition,
    required this.onLaneChanged,
    required this.onLabelChanged,
    required this.onColorChanged,
    required this.onHeroAdded,
  });

  final TierListSchemeSummary scheme;
  final Map<int, HeroSummary> heroesById;
  final GlobalKey boundaryKey;
  final Map<String, TextEditingController> labelControllers;
  final bool showLaneBoard;
  final int? lanePosition;
  final ValueChanged<int?> onLaneChanged;
  final void Function(String rowId, String label) onLabelChanged;
  final void Function(String rowId, String color) onColorChanged;
  final void Function(String rowId, int heroId) onHeroAdded;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: boundaryKey,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.24),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Column(
            children: [
              if (showLaneBoard) ...[
                _LaneIconFilterBar(
                  keyPrefix: 'tier-board-lane-filter',
                  lanePosition: lanePosition,
                  onChanged: onLaneChanged,
                ),
                const SizedBox(height: 6),
              ],
              for (final row in scheme.rows) ...[
                Expanded(
                  child: _TierRowDetail(
                    row: _rowFilteredByLane(row),
                    heroesById: heroesById,
                    isEditMode: true,
                    exposeDropKey: true,
                    labelController: labelControllers[row.id],
                    onLabelChanged: (label) => onLabelChanged(row.id, label),
                    onColorChanged: (color) => onColorChanged(row.id, color),
                    onHeroAdded: (heroId) => onHeroAdded(row.id, heroId),
                  ),
                ),
                if (row != scheme.rows.last) const SizedBox(height: 6),
              ],
            ],
          ),
        ),
      ),
    );
  }

  TierListSchemeRowSummary _rowFilteredByLane(TierListSchemeRowSummary row) {
    if (!showLaneBoard || lanePosition == null) {
      return row;
    }
    final heroIds = row.heroIds
        .where((heroId) => heroesById[heroId]?.position == lanePosition)
        .toList(growable: false);
    return row.copyWith(heroIds: heroIds, heroCount: heroIds.length);
  }
}

class _HeroPoolPanel extends StatefulWidget {
  const _HeroPoolPanel({required this.value, required this.heroes});

  final AsyncValue<List<HeroSummary>> value;
  final List<HeroSummary> heroes;

  @override
  State<_HeroPoolPanel> createState() => _HeroPoolPanelState();
}

class _HeroPoolPanelState extends State<_HeroPoolPanel> {
  int? _lanePosition;

  @override
  Widget build(BuildContext context) {
    final filteredHeroes = widget.heroes
        .where((hero) {
          if (_lanePosition == null) {
            return true;
          }
          return hero.position == _lanePosition;
        })
        .toList(growable: false);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.refresh_rounded,
                      color: AppTheme.gold,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Hero Pool',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppTheme.text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _LaneIconFilterBar(
                  lanePosition: _lanePosition,
                  onChanged: (value) {
                    setState(() {
                      _lanePosition = value;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: widget.value.when(
              data: (_) => GridView.builder(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                ),
                itemCount: filteredHeroes.length,
                itemBuilder: (context, index) {
                  return _HeroPoolDraggable(hero: filteredHeroes[index]);
                },
              ),
              loading: () => Center(
                child: Text(
                  'Loading heroes...',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                ),
              ),
              error: (_, _) => Center(
                child: Text(
                  'Failed to load heroes',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Text(
              'DRAG FROM HERE',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.muted,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LaneIconFilterBar extends StatelessWidget {
  const _LaneIconFilterBar({
    this.keyPrefix = 'lane-filter',
    required this.lanePosition,
    required this.onChanged,
  });

  final String keyPrefix;
  final int? lanePosition;
  final ValueChanged<int?> onChanged;

  static const _options = [
    _LaneFilterOption(label: 'All', assetName: null, value: null),
    _LaneFilterOption(label: 'Clash', assetName: 'clash', value: 0),
    _LaneFilterOption(label: 'Mid', assetName: 'mid', value: 1),
    _LaneFilterOption(label: 'Farm', assetName: 'adc', value: 2),
    _LaneFilterOption(label: 'Jungle', assetName: 'jungle', value: 3),
    _LaneFilterOption(label: 'Support', assetName: 'support', value: 4),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 5,
      runSpacing: 5,
      children: [
        for (final option in _options)
          Tooltip(
            message: option.label,
            child: InkWell(
              key: ValueKey(
                option.value == null
                    ? '$keyPrefix-all'
                    : '$keyPrefix-${option.value}',
              ),
              onTap: () => onChanged(option.value),
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: 29,
                height: 29,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: lanePosition == option.value
                      ? AppTheme.gold
                      : Colors.black.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: lanePosition == option.value
                        ? AppTheme.gold
                        : Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: option.assetName == null
                    ? const Icon(Icons.grid_view_rounded, size: 15)
                    : Image.asset(
                        'assets/lane-icons/${option.assetName}.png',
                        width: 17,
                        height: 17,
                      ),
              ),
            ),
          ),
      ],
    );
  }
}

class _LaneFilterOption {
  const _LaneFilterOption({
    required this.label,
    required this.assetName,
    required this.value,
  });

  final String label;
  final String? assetName;
  final int? value;
}

class _HeroPoolDraggable extends StatelessWidget {
  const _HeroPoolDraggable({required this.hero});

  final HeroSummary hero;

  @override
  Widget build(BuildContext context) {
    final heroId = int.tryParse(hero.heroId) ?? int.tryParse(hero.id) ?? 0;
    final token = _TierHeroToken(heroId: heroId, hero: hero, size: 28);
    return LongPressDraggable<int>(
      key: ValueKey('hero-pool-draggable-$heroId'),
      data: heroId,
      delay: const Duration(milliseconds: 240),
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(scale: 1.08, child: token),
      ),
      childWhenDragging: Opacity(opacity: 0.36, child: token),
      child: token,
    );
  }
}

class _EditorModeBanner extends StatelessWidget {
  const _EditorModeBanner({required this.isSaving, required this.onSave});

  final bool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.edit_note_outlined, color: AppTheme.gold),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Editor mode',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.text,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (isSaving)
              const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              IconButton.filledTonal(
                key: const ValueKey('tier-list-save-changes-top'),
                tooltip: 'Save changes',
                onPressed: onSave,
                icon: const Icon(Icons.save_outlined),
              ),
          ],
        ),
      ),
    );
  }
}

class _TierListDetailCard extends StatelessWidget {
  const _TierListDetailCard({
    required this.scheme,
    required this.heroesById,
    required this.isEditMode,
    required this.isSaving,
    required this.nameController,
    required this.labelControllers,
    required this.heroIdControllers,
    required this.onLabelChanged,
    required this.onColorChanged,
    required this.onHeroAdded,
    required this.onHeroRemoved,
    required this.onMoveRow,
    required this.onSave,
  });

  final TierListSchemeSummary scheme;
  final Map<int, HeroSummary> heroesById;
  final bool isEditMode;
  final bool isSaving;
  final TextEditingController nameController;
  final Map<String, TextEditingController> labelControllers;
  final Map<String, TextEditingController> heroIdControllers;
  final void Function(String rowId, String label) onLabelChanged;
  final void Function(String rowId, String color) onColorChanged;
  final void Function(String rowId, int heroId) onHeroAdded;
  final void Function(String rowId, int heroId) onHeroRemoved;
  final void Function(String rowId, int offset) onMoveRow;
  final VoidCallback onSave;

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.format_list_numbered_outlined,
                  color: AppTheme.gold,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isEditMode)
                        TextFormField(
                          key: const ValueKey('tier-list-name-field'),
                          controller: nameController,
                          decoration: InputDecoration(
                            labelText: 'Tier list name',
                            prefixIcon: const Icon(Icons.edit_outlined),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppTheme.gold,
                              ),
                            ),
                          ),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppTheme.text,
                                fontWeight: FontWeight.w900,
                              ),
                        )
                      else
                        Text(
                          scheme.name,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: AppTheme.text,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      const SizedBox(height: 6),
                      Text(
                        'Updated ${scheme.updatedDateText}',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _DetailBadge(label: scheme.heroCountText, isPrimary: true),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _shareTierList(context, scheme),
                  icon: const Icon(Icons.ios_share_outlined, size: 18),
                  label: const Text('Share'),
                ),
                if (isEditMode)
                  FilledButton.icon(
                    key: const ValueKey('tier-list-save-changes'),
                    onPressed: isSaving ? null : onSave,
                    icon: const Icon(Icons.save_outlined, size: 18),
                    label: const Text('Save changes'),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            for (final (index, row) in scheme.rows.indexed) ...[
              if (isEditMode) ...[
                _TierRowEditor(
                  row: row,
                  controller: labelControllers[row.id],
                  heroIdController: heroIdControllers[row.id],
                  index: index,
                  canMoveUp: index > 0,
                  canMoveDown: index < scheme.rows.length - 1,
                  onChanged: (value) => onLabelChanged(row.id, value),
                  onColorChanged: (color) => onColorChanged(row.id, color),
                  onHeroAdded: (heroId) => onHeroAdded(row.id, heroId),
                  onHeroRemoved: (heroId) => onHeroRemoved(row.id, heroId),
                  onMoveUp: () => onMoveRow(row.id, -1),
                  onMoveDown: () => onMoveRow(row.id, 1),
                ),
                const SizedBox(height: 8),
              ],
              _TierRowDetail(
                row: row,
                heroesById: heroesById,
                isEditMode: false,
                exposeDropKey: false,
                onHeroAdded: (heroId) => onHeroAdded(row.id, heroId),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _shareTierList(
    BuildContext context,
    TierListSchemeSummary scheme,
  ) async {
    await Clipboard.setData(
      ClipboardData(text: '/tools/tier-list/${scheme.id}'),
    );
    if (!context.mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(content: Text('Tier list link copied')),
    );
  }
}

class _TierRowEditor extends StatelessWidget {
  const _TierRowEditor({
    required this.row,
    required this.controller,
    required this.heroIdController,
    required this.index,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onChanged,
    required this.onColorChanged,
    required this.onHeroAdded,
    required this.onHeroRemoved,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final TierListSchemeRowSummary row;
  final TextEditingController? controller;
  final TextEditingController? heroIdController;
  final int index;
  final bool canMoveUp;
  final bool canMoveDown;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onColorChanged;
  final ValueChanged<int> onHeroAdded;
  final ValueChanged<int> onHeroRemoved;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  key: ValueKey('tier-row-move-up-${row.id}'),
                  tooltip: 'Move up',
                  onPressed: canMoveUp ? onMoveUp : null,
                  icon: const Icon(Icons.keyboard_arrow_up_rounded),
                ),
                IconButton(
                  key: ValueKey('tier-row-move-down-${row.id}'),
                  tooltip: 'Move down',
                  onPressed: canMoveDown ? onMoveDown : null,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: TextFormField(
                    key: ValueKey('tier-row-label-${row.id}'),
                    controller: controller,
                    onChanged: onChanged,
                    decoration: InputDecoration(
                      labelText: index == 0
                          ? 'Row label'
                          : 'Row label ${index + 1}',
                      prefixIcon: const Icon(Icons.drive_file_rename_outline),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.gold),
                      ),
                    ),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final color in _tierListEditorColors)
                    _TierColorButton(
                      key: ValueKey('tier-row-color-${row.id}-$color'),
                      colorToken: color,
                      isSelected: row.color == color,
                      onTap: () => onColorChanged(color),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _TierHeroIdEditor(
              row: row,
              heroIdController: heroIdController,
              onHeroAdded: onHeroAdded,
              onHeroRemoved: onHeroRemoved,
            ),
          ],
        ),
      ),
    );
  }
}

class _TierHeroIdEditor extends StatelessWidget {
  const _TierHeroIdEditor({
    required this.row,
    required this.heroIdController,
    required this.onHeroAdded,
    required this.onHeroRemoved,
  });

  final TierListSchemeRowSummary row;
  final TextEditingController? heroIdController;
  final ValueChanged<int> onHeroAdded;
  final ValueChanged<int> onHeroRemoved;

  @override
  Widget build(BuildContext context) {
    final chips = row.heroIds.isEmpty
        ? <Widget>[
            Text(
              'No heroes assigned',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
            ),
          ]
        : [
            for (final heroId in row.heroIds)
              InputChip(
                key: ValueKey('tier-row-remove-hero-${row.id}-$heroId'),
                label: Text('Hero #$heroId'),
                avatar: const Icon(Icons.sports_esports_outlined, size: 18),
                onPressed: () => onHeroRemoved(heroId),
                onDeleted: () => onHeroRemoved(heroId),
                deleteIcon: const Icon(Icons.close_rounded, size: 18),
                visualDensity: VisualDensity.compact,
              ),
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(spacing: 8, runSpacing: 8, children: chips),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: ValueKey('tier-row-add-hero-${row.id}'),
                controller: heroIdController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Add hero ID',
                  prefixIcon: const Icon(Icons.person_add_alt_1_outlined),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.gold),
                  ),
                ),
                style: const TextStyle(color: AppTheme.text),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              key: ValueKey('tier-row-add-hero-button-${row.id}'),
              tooltip: 'Add hero',
              onPressed: () {
                final value = int.tryParse(heroIdController?.text ?? '');
                if (value != null) {
                  onHeroAdded(value);
                }
              },
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ],
    );
  }
}

class _TierColorButton extends StatelessWidget {
  const _TierColorButton({
    super.key,
    required this.colorToken,
    required this.isSelected,
    required this.onTap,
  });

  final String colorToken;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _tierColorToken(colorToken);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.2),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.42),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}

class _TierRowDetail extends StatelessWidget {
  const _TierRowDetail({
    required this.row,
    required this.heroesById,
    required this.isEditMode,
    required this.exposeDropKey,
    this.labelController,
    this.onLabelChanged,
    this.onColorChanged,
    required this.onHeroAdded,
  });

  final TierListSchemeRowSummary row;
  final Map<int, HeroSummary> heroesById;
  final bool isEditMode;
  final bool exposeDropKey;
  final TextEditingController? labelController;
  final ValueChanged<String>? onLabelChanged;
  final ValueChanged<String>? onColorChanged;
  final ValueChanged<int> onHeroAdded;

  @override
  Widget build(BuildContext context) {
    final color = _tierColorToken(row.color, fallbackLabel: row.label);
    final content = DecoratedBox(
      key: exposeDropKey ? ValueKey('tier-row-drop-${row.id}') : null,
      decoration: BoxDecoration(
        color: const Color(0xFF071027),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: SizedBox(
        height: isEditMode ? double.infinity : 92,
        child: Row(
          children: [
            Container(
              key: ValueKey('tier-row-color-strip-${row.id}'),
              width: isEditMode ? 68 : 94,
              height: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(7),
                ),
              ),
              child: isEditMode
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: Center(
                            child: SizedBox(
                              width: 50,
                              height: 30,
                              child: TextField(
                                key: ValueKey('tier-row-label-${row.id}'),
                                controller: labelController,
                                onChanged: onLabelChanged,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontStyle: FontStyle.italic,
                                      fontWeight: FontWeight.w900,
                                    ),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (onColorChanged != null)
                          Positioned(
                            right: 1,
                            bottom: 1,
                            child: _TierRowColorMenu(
                              rowId: row.id,
                              selectedColor: row.color,
                              onColorChanged: onColorChanged!,
                            ),
                          ),
                      ],
                    )
                  : Text(
                      row.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isEditMode ? 8 : 14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isEditMode) ...[
                      Text(
                        row.heroCount == 1
                            ? '1 hero'
                            : '${row.heroCount} heroes',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppTheme.text,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (row.heroIds.isEmpty)
                      Text(
                        isEditMode ? 'Drag heroes here' : 'No heroes assigned',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final heroId in row.heroIds) ...[
                              _TierHeroToken(
                                key: ValueKey('tier-board-token-$heroId'),
                                heroId: heroId,
                                hero: heroesById[heroId],
                                size: isEditMode ? 30 : 44,
                              ),
                              SizedBox(width: isEditMode ? 6 : 10),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (!isEditMode) {
      return content;
    }

    return DragTarget<int>(
      onAcceptWithDetails: (details) => onHeroAdded(details.data),
      builder: (context, candidateData, rejectedData) {
        if (candidateData.isEmpty) {
          return content;
        }
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.34),
                blurRadius: 18,
                spreadRadius: 1,
              ),
            ],
          ),
          child: content,
        );
      },
    );
  }
}

class _TierRowColorMenu extends StatelessWidget {
  const _TierRowColorMenu({
    required this.rowId,
    required this.selectedColor,
    required this.onColorChanged,
  });

  final String rowId;
  final String selectedColor;
  final ValueChanged<String> onColorChanged;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: ValueKey('tier-row-color-menu-$rowId'),
      tooltip: 'Tier color',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 22, height: 22),
      iconSize: 15,
      color: Colors.white,
      onPressed: () => _showColorDialog(context),
      icon: const Icon(Icons.palette_outlined),
    );
  }

  Future<void> _showColorDialog(BuildContext context) async {
    final color = await showDialog<String>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppTheme.panel,
          insetPadding: const EdgeInsets.all(18),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final color in _tierListEditorColors)
                  InkWell(
                    key: ValueKey('tier-row-color-$rowId-$color'),
                    onTap: () => Navigator.of(context).pop(color),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: _tierColorToken(color),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: color == selectedColor
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.18),
                          width: color == selectedColor ? 3 : 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (color != null) {
      onColorChanged(color);
    }
  }
}

class _TierHeroToken extends StatelessWidget {
  const _TierHeroToken({
    super.key,
    required this.heroId,
    required this.size,
    this.hero,
  });

  final int heroId;
  final double size;
  final HeroSummary? hero;

  @override
  Widget build(BuildContext context) {
    final label = hero?.name.trim().isNotEmpty == true
        ? hero!.name
        : 'Hero #$heroId';
    return Tooltip(
      message: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size <= 30 ? 7 : 11),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.24),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: AppImage(
          url: hero?.avatar,
          width: size,
          height: size,
          borderRadius: size <= 30 ? 6 : 10,
          semanticLabel: label,
        ),
      ),
    );
  }
}

Color _tierColorToken(String token, {String fallbackLabel = ''}) {
  return switch (token) {
    'bg-red-600' => const Color(0xFFDC2626),
    'bg-orange-500' => const Color(0xFFF97316),
    'bg-yellow-500' => const Color(0xFFEAB308),
    'bg-green-500' => const Color(0xFF22C55E),
    'bg-teal-500' => const Color(0xFF14B8A6),
    'bg-blue-500' => const Color(0xFF3B82F6),
    'bg-indigo-500' => const Color(0xFF6366F1),
    'bg-purple-500' => const Color(0xFFA855F7),
    'bg-pink-500' => const Color(0xFFEC4899),
    'bg-slate-500' => const Color(0xFF64748B),
    _ => tierListColor(fallbackLabel),
  };
}

class _DetailBadge extends StatelessWidget {
  const _DetailBadge({required this.label, this.isPrimary = false});

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
