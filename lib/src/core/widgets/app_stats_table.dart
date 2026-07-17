import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppStatsTableColumn {
  const AppStatsTableColumn({
    required this.label,
    required this.cells,
    this.width = 86,
    this.onHeaderTap,
    this.selected = false,
    this.sortAscending,
    this.groupLabel = '',
  });

  final String label;
  final List<Widget> cells;
  final double width;
  final VoidCallback? onHeaderTap;
  final bool selected;
  final bool? sortAscending;
  final String groupLabel;
}

class AppStatsTable extends StatefulWidget {
  const AppStatsTable({
    required this.fixedHeader,
    required this.fixedCells,
    required this.columns,
    this.fixedColumnWidth = 148,
    this.rowHeight = 62,
    super.key,
  });

  final Widget fixedHeader;
  final List<Widget> fixedCells;
  final List<AppStatsTableColumn> columns;
  final double fixedColumnWidth;
  final double rowHeight;

  @override
  State<AppStatsTable> createState() => _AppStatsTableState();
}

class _AppStatsTableState extends State<AppStatsTable> {
  final _headerController = ScrollController();
  final _bodyController = ScrollController();
  final _verticalController = ScrollController();
  var _syncing = false;

  @override
  void initState() {
    super.initState();
    _headerController.addListener(_syncHeaderToBody);
    _bodyController.addListener(_syncBodyToHeader);
  }

  @override
  void dispose() {
    _headerController
      ..removeListener(_syncHeaderToBody)
      ..dispose();
    _bodyController
      ..removeListener(_syncBodyToHeader)
      ..dispose();
    _verticalController.dispose();
    super.dispose();
  }

  void _syncHeaderToBody() => _sync(_headerController, _bodyController);

  void _syncBodyToHeader() => _sync(_bodyController, _headerController);

  void _sync(ScrollController source, ScrollController target) {
    if (_syncing || !source.hasClients || !target.hasClients) {
      return;
    }
    _syncing = true;
    final offset = source.offset.clamp(
      target.position.minScrollExtent,
      target.position.maxScrollExtent,
    );
    if ((target.offset - offset).abs() > 0.5) {
      target.jumpTo(offset);
    }
    _syncing = false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<HokThemeColors>();
    final panel = colors?.surfaceSlate ?? AppTheme.panel;
    final panelAlt = colors?.surfaceMuted ?? AppTheme.panelAlt;
    final outline = colors?.outlineSoft ?? AppTheme.outline;
    final hasGroupedHeader = widget.columns.any(
      (column) => column.groupLabel.isNotEmpty,
    );
    final headerHeight = hasGroupedHeader ? 64.0 : 44.0;
    final totalScrollableWidth = widget.columns.fold<double>(
      0,
      (total, column) => total + column.width,
    );
    final groupSpans = hasGroupedHeader
        ? _buildGroupSpans(widget.columns)
        : const <_ColumnGroupSpan>[];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: panel,
        border: Border.all(color: outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Column(
          children: [
            SizedBox(
              height: headerHeight,
              child: ColoredBox(
                color: panelAlt,
                child: Row(
                  children: [
                    _FixedCell(
                      width: widget.fixedColumnWidth,
                      borderColor: outline,
                      child: hasGroupedHeader
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 24),
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: widget.fixedHeader,
                                  ),
                                ),
                              ],
                            )
                          : widget.fixedHeader,
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _headerController,
                        scrollDirection: Axis.horizontal,
                        physics: const ClampingScrollPhysics(),
                        child: SizedBox(
                          width: totalScrollableWidth,
                          child: hasGroupedHeader
                              ? Column(
                                  children: [
                                    SizedBox(
                                      height: 24,
                                      child: Row(
                                        children: [
                                          for (final span in groupSpans)
                                            _GroupHeaderCell(
                                              span: span,
                                              borderColor: outline,
                                            ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      height: 40,
                                      child: Row(
                                        children: [
                                          for (
                                            var index = 0;
                                            index < widget.columns.length;
                                            index++
                                          )
                                            _HeaderCell(
                                              column: widget.columns[index],
                                              height: 40,
                                              trailingBorder: _isGroupBoundary(
                                                widget.columns,
                                                index,
                                              ),
                                              borderColor: outline,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    for (final column in widget.columns)
                                      _HeaderCell(column: column),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Scrollbar(
                controller: _verticalController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _verticalController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: widget.fixedColumnWidth,
                        child: Column(
                          children: [
                            for (
                              var index = 0;
                              index < widget.fixedCells.length;
                              index++
                            )
                              _BodyCell(
                                height: widget.rowHeight,
                                borderColor: outline,
                                trailingBorder: true,
                                child: widget.fixedCells[index],
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Scrollbar(
                          controller: _bodyController,
                          thumbVisibility: true,
                          notificationPredicate: (notification) =>
                              notification.metrics.axis == Axis.horizontal,
                          child: SingleChildScrollView(
                            controller: _bodyController,
                            scrollDirection: Axis.horizontal,
                            physics: const ClampingScrollPhysics(),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (
                                  var columnIndex = 0;
                                  columnIndex < widget.columns.length;
                                  columnIndex++
                                )
                                  SizedBox(
                                    width: widget.columns[columnIndex].width,
                                    child: Column(
                                      children: [
                                        for (final cell
                                            in widget
                                                .columns[columnIndex]
                                                .cells)
                                          _BodyCell(
                                            height: widget.rowHeight,
                                            borderColor: outline,
                                            trailingBorder:
                                                hasGroupedHeader &&
                                                _isGroupBoundary(
                                                  widget.columns,
                                                  columnIndex,
                                                ),
                                            child: cell,
                                          ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FixedCell extends StatelessWidget {
  const _FixedCell({
    required this.width,
    required this.borderColor,
    required this.child,
  });

  final double width;
  final Color borderColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: borderColor)),
      ),
      child: child,
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({
    required this.column,
    this.height = 44,
    this.trailingBorder = false,
    this.borderColor,
  });

  final AppStatsTableColumn column;
  final double height;
  final bool trailingBorder;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final muted =
        Theme.of(context).extension<HokThemeColors>()?.onSurfaceMuted ??
        AppTheme.muted;
    final color = column.selected
        ? Theme.of(context).colorScheme.primary
        : muted;
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              column.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (column.selected) ...[
            const SizedBox(width: 3),
            Icon(
              column.sortAscending == true
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              size: 13,
              color: color,
            ),
          ],
        ],
      ),
    );

    return Container(
      width: column.width,
      height: height,
      decoration: BoxDecoration(
        border: trailingBorder && borderColor != null
            ? Border(right: BorderSide(color: borderColor!))
            : null,
      ),
      child: column.onHeaderTap == null
          ? content
          : InkWell(onTap: column.onHeaderTap, child: content),
    );
  }
}

class _ColumnGroupSpan {
  const _ColumnGroupSpan({required this.label, required this.width});

  final String label;
  final double width;
}

List<_ColumnGroupSpan> _buildGroupSpans(List<AppStatsTableColumn> columns) {
  final spans = <_ColumnGroupSpan>[];
  for (final column in columns) {
    final label = column.groupLabel.isEmpty ? 'Metrics' : column.groupLabel;
    if (spans.isNotEmpty && spans.last.label == label) {
      final previous = spans.removeLast();
      spans.add(
        _ColumnGroupSpan(label: label, width: previous.width + column.width),
      );
    } else {
      spans.add(_ColumnGroupSpan(label: label, width: column.width));
    }
  }
  return spans;
}

bool _isGroupBoundary(List<AppStatsTableColumn> columns, int index) {
  if (index >= columns.length - 1) return true;
  return columns[index].groupLabel != columns[index + 1].groupLabel;
}

class _GroupHeaderCell extends StatelessWidget {
  const _GroupHeaderCell({required this.span, required this.borderColor});

  final _ColumnGroupSpan span;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final muted =
        Theme.of(context).extension<HokThemeColors>()?.onSurfaceMuted ??
        AppTheme.muted;
    return Container(
      width: span.width,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: borderColor)),
      ),
      child: Text(
        span.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: muted,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _BodyCell extends StatelessWidget {
  const _BodyCell({
    required this.height,
    required this.borderColor,
    required this.child,
    this.trailingBorder = false,
  });

  final double height;
  final Color borderColor;
  final Widget child;
  final bool trailingBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: borderColor.withValues(alpha: 0.72)),
          right: trailingBorder
              ? BorderSide(color: borderColor)
              : BorderSide.none,
        ),
      ),
      child: child,
    );
  }
}
