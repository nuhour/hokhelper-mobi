import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_error_state.dart';

class AppAsyncView<T> extends StatelessWidget {
  const AppAsyncView({
    required this.value,
    required this.data,
    this.retry,
    super.key,
  });

  final AsyncValue<T> value;
  final Widget Function(T value) data;
  final VoidCallback? retry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) =>
          AppErrorState(message: error.toString(), retry: retry),
    );
  }
}
