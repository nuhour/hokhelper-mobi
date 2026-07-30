import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../theme/app_theme.dart';

/// 列表底部统一页脚：滚动接近底部时自动触发 [onLoadMore]，
/// [hasMore] 为 false 时显示「没有更多」提示。
///
/// 放在任意可滚动内容的末尾即可（ListView/GridView 的最后一项、
/// SingleChildScrollView 内 Column 的最后一个 child、sliver 列表尾等）。
/// 内存分页场景：父级用 setState 增大可见条数即可；
/// 远端分页场景：传 [loading] 反映请求中状态。
class AppListFooter extends StatefulWidget {
  const AppListFooter({
    required this.hasMore,
    this.loading = false,
    this.onLoadMore,
    this.endLabel = 'No more content',
    this.prefetchExtent = 320,
    super.key,
  });

  final bool hasMore;
  final bool loading;
  final VoidCallback? onLoadMore;
  final String endLabel;

  /// 页脚距进入视口还有多少像素时就提前触发加载。
  final double prefetchExtent;

  @override
  State<AppListFooter> createState() => _AppListFooterState();
}

class _AppListFooterState extends State<AppListFooter> {
  ScrollPosition? _position;
  // 每个加载周期只触发一次；父级更新（列表增长/loading 变化）后重置。
  bool _requested = false;
  // 防死循环：同一位置（列表没长高）不重复触发。
  double? _lastFiredReveal;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final position = Scrollable.maybeOf(context)?.position;
    if (!identical(position, _position)) {
      _position?.removeListener(_maybeLoadMore);
      _position = position;
      _position?.addListener(_maybeLoadMore);
    }
    _scheduleCheck();
  }

  @override
  void didUpdateWidget(AppListFooter oldWidget) {
    super.didUpdateWidget(oldWidget);
    _requested = false;
    _scheduleCheck();
  }

  @override
  void dispose() {
    _position?.removeListener(_maybeLoadMore);
    super.dispose();
  }

  void _scheduleCheck() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeLoadMore());
  }

  void _maybeLoadMore() {
    if (!mounted ||
        _requested ||
        widget.loading ||
        !widget.hasMore ||
        widget.onLoadMore == null) {
      return;
    }
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return;
    final position = _position;
    if (position == null || !position.hasPixels) {
      // 懒构建列表里页脚被 build 即意味着滚到了末尾，直接触发。
      _requested = true;
      widget.onLoadMore!();
      return;
    }
    final viewport = RenderAbstractViewport.maybeOf(box);
    if (viewport == null) return;
    final reveal = viewport.getOffsetToReveal(box, 0).offset;
    if (_lastFiredReveal == reveal) return;
    final visibleEdge = position.pixels + position.viewportDimension;
    if (visibleEdge + widget.prefetchExtent >= reveal) {
      _requested = true;
      _lastFiredReveal = reveal;
      widget.onLoadMore!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<HokThemeColors>();
    final muted = colors?.onSurfaceMuted ?? context.hokTheme.onSurfaceMuted;
    if (widget.hasMore) {
      // 仅远端请求中显示转圈；内存分页靠滚动自动追加，页脚保持安静占位。
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Center(
          child: widget.loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const SizedBox(height: 4),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 1,
            color: muted.withValues(alpha: 0.4),
            margin: const EdgeInsets.only(right: 10),
          ),
          Text(
            widget.endLabel,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: muted,
            ),
          ),
          Container(
            width: 28,
            height: 1,
            color: muted.withValues(alpha: 0.4),
            margin: const EdgeInsets.only(left: 10),
          ),
        ],
      ),
    );
  }
}
