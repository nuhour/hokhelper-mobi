import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_error_state.dart';

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
          return const Center(child: CircularProgressIndicator());
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
