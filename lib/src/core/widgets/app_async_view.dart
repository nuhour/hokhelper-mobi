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
    this.loadingStyle = AppAsyncLoadingStyle.list,
    super.key,
  });

  final AsyncValue<T> value;
  final Widget Function(T value) data;
  final VoidCallback? retry;
  final T? previousData;
  final AppAsyncLoadingStyle loadingStyle;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () {
        final previous = previousData;
        if (previous == null) {
          return _AppAsyncLoadingSurface(style: loadingStyle);
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

enum AppAsyncLoadingStyle { list, gallery, dashboard, detail }

class _AppAsyncLoadingSurface extends StatelessWidget {
  const _AppAsyncLoadingSurface({required this.style});

  final AppAsyncLoadingStyle style;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      key: const ValueKey('app-async-loading-surface'),
      color: AppTheme.bg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: switch (style) {
          AppAsyncLoadingStyle.gallery => const _GalleryLoadingSkeleton(),
          AppAsyncLoadingStyle.dashboard => const _DashboardLoadingSkeleton(),
          AppAsyncLoadingStyle.detail => const _DetailLoadingSkeleton(),
          AppAsyncLoadingStyle.list => const _ListLoadingSkeleton(),
        },
      ),
    );
  }
}

class _ListLoadingSkeleton extends StatelessWidget {
  const _ListLoadingSkeleton();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _AppAsyncLoadingBar(width: 150, height: 28),
      SizedBox(height: 16),
      _AppAsyncLoadingBar(width: double.infinity, height: 46),
      SizedBox(height: 16),
      _LoadingListCard(),
      SizedBox(height: 12),
      _LoadingListCard(),
      SizedBox(height: 12),
      _LoadingListCard(),
    ],
  );
}

class _GalleryLoadingSkeleton extends StatelessWidget {
  const _GalleryLoadingSkeleton();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _AppAsyncLoadingBar(width: 122, height: 28),
      const SizedBox(height: 16),
      const _AppAsyncLoadingBar(width: double.infinity, height: 48),
      const SizedBox(height: 12),
      const _AppAsyncLoadingBar(width: double.infinity, height: 40),
      const SizedBox(height: 16),
      GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: .68,
        children: [
          const _LoadingGalleryCard(),
          const _LoadingGalleryCard(),
          const _LoadingGalleryCard(),
          const _LoadingGalleryCard(),
          const _LoadingGalleryCard(),
          const _LoadingGalleryCard(),
        ],
      ),
    ],
  );
}

class _DashboardLoadingSkeleton extends StatelessWidget {
  const _DashboardLoadingSkeleton();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _AppAsyncLoadingBar(width: 132, height: 28),
      SizedBox(height: 16),
      Row(
        children: [
          Expanded(child: _LoadingMetricCard()),
          SizedBox(width: 12),
          Expanded(child: _LoadingMetricCard()),
        ],
      ),
      SizedBox(height: 16),
      _LoadingListCard(height: 146),
      SizedBox(height: 12),
      _LoadingListCard(height: 114),
    ],
  );
}

class _DetailLoadingSkeleton extends StatelessWidget {
  const _DetailLoadingSkeleton();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _AppAsyncLoadingBar(width: 96, height: 20),
      SizedBox(height: 18),
      _LoadingListCard(height: 196),
      SizedBox(height: 18),
      _AppAsyncLoadingBar(width: 168, height: 24),
      SizedBox(height: 12),
      _LoadingListCard(),
      SizedBox(height: 12),
      _LoadingListCard(),
    ],
  );
}

class _LoadingListCard extends StatelessWidget {
  const _LoadingListCard({this.height = 88});
  final double height;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.panel,
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _AppAsyncLoadingBar(width: 156, height: 14),
        SizedBox(height: 10),
        _AppAsyncLoadingBar(width: 220, height: 11),
      ],
    ),
  );
}

class _LoadingMetricCard extends StatelessWidget {
  const _LoadingMetricCard();

  @override
  Widget build(BuildContext context) => Container(
    height: 96,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTheme.panel,
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _AppAsyncLoadingBar(width: 62, height: 10),
        SizedBox(height: 12),
        _AppAsyncLoadingBar(width: 84, height: 22),
      ],
    ),
  );
}

class _LoadingGalleryCard extends StatelessWidget {
  const _LoadingGalleryCard();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppTheme.panel,
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Padding(
      padding: EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppTheme.panelAlt,
                borderRadius: BorderRadius.all(Radius.circular(9)),
              ),
            ),
          ),
          SizedBox(height: 9),
          _AppAsyncLoadingBar(width: 62, height: 10),
          SizedBox(height: 6),
          _AppAsyncLoadingBar(width: 42, height: 8),
        ],
      ),
    ),
  );
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
