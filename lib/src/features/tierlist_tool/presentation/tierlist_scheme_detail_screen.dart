import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_section_header.dart';
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
  final Map<String, TextEditingController> _labelControllers = {};
  final Map<String, String> _editedLabels = {};
  List<TierListSchemeRowSummary> _editedRows = const [];
  String? _hydratedSchemeId;
  TierListSchemeSummary? _savedScheme;
  bool _isSaving = false;

  @override
  void dispose() {
    for (final controller in _labelControllers.values) {
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
        return RefreshIndicator(
          onRefresh: () =>
              ref.refresh(tierListSchemeDetailProvider(widget.schemeId).future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
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
                _EditorModeBanner(isSaving: _isSaving),
                const SizedBox(height: 12),
              ],
              _TierListDetailCard(
                scheme: displayScheme,
                isEditMode: widget.initialEditMode,
                isSaving: _isSaving,
                labelControllers: _labelControllers,
                onLabelChanged: _updateRowLabel,
                onColorChanged: _updateRowColor,
                onMoveRow: _moveRow,
                onSave: () => _saveScheme(_schemeWithEditedRows(displayScheme)),
              ),
            ],
          ),
        );
      },
    );
  }

  TierListSchemeSummary _displaySchemeFor(TierListSchemeSummary loadedScheme) {
    final baseScheme =
        _savedScheme != null && _savedScheme!.id == loadedScheme.id
        ? _savedScheme!
        : loadedScheme;
    if (_hydratedSchemeId != baseScheme.id) {
      _hydratedSchemeId = baseScheme.id;
      _editedLabels
        ..clear()
        ..addEntries(baseScheme.rows.map((row) => MapEntry(row.id, row.label)));
      _editedRows = baseScheme.rows;
      final rowIds = baseScheme.rows.map((row) => row.id).toSet();
      final removedIds = _labelControllers.keys
          .where((rowId) => !rowIds.contains(rowId))
          .toList(growable: false);
      for (final rowId in removedIds) {
        _labelControllers.remove(rowId)?.dispose();
      }
      for (final row in baseScheme.rows) {
        final controller = _labelControllers.putIfAbsent(
          row.id,
          () => TextEditingController(),
        );
        controller.text = row.label;
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
    return scheme.copyWith(
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
}

class _EditorModeBanner extends StatelessWidget {
  const _EditorModeBanner({required this.isSaving});

  final bool isSaving;

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
    required this.isEditMode,
    required this.isSaving,
    required this.labelControllers,
    required this.onLabelChanged,
    required this.onColorChanged,
    required this.onMoveRow,
    required this.onSave,
  });

  final TierListSchemeSummary scheme;
  final bool isEditMode;
  final bool isSaving;
  final Map<String, TextEditingController> labelControllers;
  final void Function(String rowId, String label) onLabelChanged;
  final void Function(String rowId, String color) onColorChanged;
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
                      Text(
                        scheme.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
                  index: index,
                  canMoveUp: index > 0,
                  canMoveDown: index < scheme.rows.length - 1,
                  onChanged: (value) => onLabelChanged(row.id, value),
                  onColorChanged: (color) => onColorChanged(row.id, color),
                  onMoveUp: () => onMoveRow(row.id, -1),
                  onMoveDown: () => onMoveRow(row.id, 1),
                ),
                const SizedBox(height: 8),
              ],
              _TierRowDetail(row: row),
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
    required this.index,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onChanged,
    required this.onColorChanged,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final TierListSchemeRowSummary row;
  final TextEditingController? controller;
  final int index;
  final bool canMoveUp;
  final bool canMoveDown;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onColorChanged;
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
          ],
        ),
      ),
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
  const _TierRowDetail({required this.row});

  final TierListSchemeRowSummary row;

  @override
  Widget build(BuildContext context) {
    final heroText = row.heroCount == 1 ? '1 hero' : '${row.heroCount} heroes';
    final color = _tierColorToken(row.color, fallbackLabel: row.label);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.36)),
              ),
              child: Text(
                row.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    heroText,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 6,
                      value: row.heroCount <= 0 ? 0.04 : row.heroCount / 8,
                      color: color,
                      backgroundColor: Colors.white.withValues(alpha: 0.06),
                    ),
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
