import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppStatsTableColumn {
  const AppStatsTableColumn({
    required this.label,
    required this.cells,
    this.width = 86,
    this.onHeaderTap,
    this.selected = false,
  });

  final String label;
  final List<Widget> cells;
  final double width;
  final VoidCallback? onHeaderTap;
  final bool selected;
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
              height: 44,
              child: ColoredBox(
                color: panelAlt,
                child: Row(
                  children: [
                    _FixedCell(
                      width: widget.fixedColumnWidth,
                      borderColor: outline,
                      child: widget.fixedHeader,
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _headerController,
                        scrollDirection: Axis.horizontal,
                        physics: const ClampingScrollPhysics(),
                        child: Row(
                          children: [
                            for (final column in widget.columns)
                              _HeaderCell(column: column),
                          ],
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
                                for (final column in widget.columns)
                                  SizedBox(
                                    width: column.width,
                                    child: Column(
                                      children: [
                                        for (final cell in column.cells)
                                          _BodyCell(
                                            height: widget.rowHeight,
                                            borderColor: outline,
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
  const _HeaderCell({required this.column});

  final AppStatsTableColumn column;

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
            Icon(Icons.arrow_downward_rounded, size: 13, color: color),
          ],
        ],
      ),
    );

    return SizedBox(
      width: column.width,
      height: 44,
      child: column.onHeaderTap == null
          ? content
          : InkWell(onTap: column.onHeaderTap, child: content),
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
