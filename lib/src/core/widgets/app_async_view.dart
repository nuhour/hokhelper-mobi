import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_error_state.dart';
import '../theme/app_theme.dart';

class AppAsyncView<T> extends StatelessWidget {
  const AppAsyncView({
    required this.value,
    required this.data,
    this.retry,
    this.previousData,
    super.key,
  });

  final AsyncValue<T> value;
  final Widget Function(T value) data;
  final VoidCallback? retry;
  final T? previousData;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () {
        final previous = previousData;
        if (previous == null) {
          return const _AppAsyncLoadingSurface();
        }
        return Stack(
          children: [
            data(previous),
            const Align(
              alignment: Alignment.topCenter,
              child: LinearProgressIndicator(minHeight: 2),
            ),
          ],
        );
      },
      error: (error, stackTrace) =>
          AppErrorState(message: error.toString(), retry: retry),
    );
  }
}

class _AppAsyncLoadingSurface extends StatelessWidget {
  const _AppAsyncLoadingSurface();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('app-async-loading-surface'),
      constraints: const BoxConstraints(minHeight: 156),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AppAsyncLoadingBar(width: 132, height: 18),
          SizedBox(height: 14),
          _AppAsyncLoadingBar(width: double.infinity, height: 12),
          SizedBox(height: 8),
          _AppAsyncLoadingBar(width: 196, height: 12),
        ],
      ),
    );
  }
}

class _AppAsyncLoadingBar extends StatelessWidget {
  const _AppAsyncLoadingBar({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: AppTheme.panelAlt,
      borderRadius: BorderRadius.circular(999),
    ),
  );
}
