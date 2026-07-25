import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class GlobalEdgeBackGesture extends StatefulWidget {
  const GlobalEdgeBackGesture({
    required this.router,
    required this.child,
    super.key,
  });

  final GoRouter router;
  final Widget child;

  @override
  State<GlobalEdgeBackGesture> createState() => _GlobalEdgeBackGestureState();
}

class _GlobalEdgeBackGestureState extends State<GlobalEdgeBackGesture> {
  static const _edgeWidth = 28.0;
  static const _triggerDistance = 72.0;
  static const _exitWindow = Duration(seconds: 2);

  int? _pointer;
  Offset? _start;
  DateTime? _exitArmedAt;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        if (_pointer != null || event.position.dx > _edgeWidth) return;
        _pointer = event.pointer;
        _start = event.position;
      },
      onPointerCancel: (event) => _resetPointer(event.pointer),
      onPointerUp: (event) {
        if (event.pointer != _pointer || _start == null) return;
        final delta = event.position - _start!;
        _resetPointer(event.pointer);
        if (delta.dx < _triggerDistance || delta.dx < delta.dy.abs() * 1.25) {
          return;
        }
        _handleBackSwipe();
      },
      child: widget.child,
    );
  }

  void _resetPointer(int pointer) {
    if (_pointer != pointer) return;
    _pointer = null;
    _start = null;
  }

  void _handleBackSwipe() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (widget.router.canPop()) {
      _exitArmedAt = null;
      widget.router.pop();
      return;
    }

    final now = DateTime.now();
    final armedAt = _exitArmedAt;
    if (armedAt != null && now.difference(armedAt) <= _exitWindow) {
      SystemNavigator.pop();
      return;
    }

    _exitArmedAt = now;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Swipe right again to exit'),
          duration: _exitWindow,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
