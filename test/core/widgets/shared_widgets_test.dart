import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/widgets/app_async_view.dart';
import 'package:hok_helper_mobile/src/core/widgets/app_empty_state.dart';
import 'package:hok_helper_mobile/src/core/widgets/app_error_state.dart';
import 'package:hok_helper_mobile/src/core/widgets/app_image.dart';
import 'package:hok_helper_mobile/src/core/widgets/app_section_header.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('AppAsyncView', () {
    testWidgets('renders data builder for data values', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AppAsyncView<String>(
            value: const AsyncValue.data('Arthur'),
            data: (value) => Text(value),
          ),
        ),
      );

      expect(find.text('Arthur'), findsOneWidget);
    });

    testWidgets('renders a static loading surface while loading', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          AppAsyncView<String>(
            value: const AsyncValue.loading(),
            data: Text.new,
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('app-async-loading-surface')),
        findsOneWidget,
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('gallery skeleton remains overflow-free in a short viewport', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _wrap(
          AppAsyncView<String>(
            value: const AsyncValue.loading(),
            loadingStyle: AppAsyncLoadingStyle.gallery,
            data: Text.new,
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('app-async-loading-surface')),
        findsOneWidget,
      );
      expect(
        tester
            .getSize(find.byKey(const ValueKey('app-async-loading-surface')))
            .height,
        480,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps the previous data visible while refreshing', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          AppAsyncView<String>(
            value: const AsyncValue.loading(),
            previousData: 'Existing prompts',
            data: Text.new,
          ),
        ),
      );

      expect(find.text('Existing prompts'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('renders an error state with retry action on failures', (
      tester,
    ) async {
      var retryCount = 0;

      await tester.pumpWidget(
        _wrap(
          AppAsyncView<String>(
            value: AsyncValue.error(Exception('failed'), StackTrace.empty),
            data: Text.new,
            retry: () => retryCount++,
          ),
        ),
      );

      expect(find.byType(AppErrorState), findsOneWidget);
      expect(find.textContaining('Exception: failed'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      expect(retryCount, 1);
    });
  });

  testWidgets('AppEmptyState renders centered icon, title, and message', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const AppEmptyState(
          icon: Icons.search_off,
          title: 'No heroes',
          message: 'Try another lane.',
        ),
      ),
    );

    expect(find.byIcon(Icons.search_off), findsOneWidget);
    expect(find.text('No heroes'), findsOneWidget);
    expect(find.text('Try another lane.'), findsOneWidget);
  });

  testWidgets('AppErrorState renders message and optional retry button', (
    tester,
  ) async {
    var retryCount = 0;

    await tester.pumpWidget(
      _wrap(
        AppErrorState(
          message: 'Could not load builds',
          retry: () => retryCount++,
        ),
      ),
    );

    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.text('Could not load builds'), findsOneWidget);
    expect(find.byType(OutlinedButton), findsOneWidget);

    await tester.tap(find.text('Retry'));
    expect(retryCount, 1);
  });

  testWidgets('AppImage renders a dark placeholder for empty URLs', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const AppImage(url: null)));

    final container = tester.widget<Container>(find.byType(Container).first);
    final decoration = container.decoration as BoxDecoration;

    expect(decoration.borderRadius, BorderRadius.circular(8));
    expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
  });

  testWidgets('AppImage uses a bounded default size inside vertical lists', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        ListView(
          children: const [
            Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: AppImage(url: null),
              ),
            ),
          ],
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(AppImage), findsOneWidget);
  });

  testWidgets('AppImage derives width from height inside horizontal lists', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const [AppImage(url: null, height: 80, aspectRatio: 1.5)],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
    expect(
      sizedBoxes.any((box) => box.width == 120 && box.height == 80),
      isTrue,
    );
  });

  testWidgets('AppImage exposes and excludes placeholder semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      _wrap(const AppImage(url: null, semanticLabel: 'Hero portrait')),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('Hero portrait')),
      matchesSemantics(label: 'Hero portrait', isImage: true),
    );

    await tester.pumpWidget(
      _wrap(
        const AppImage(
          url: null,
          semanticLabel: 'Hidden hero portrait',
          excludeFromSemantics: true,
        ),
      ),
    );

    expect(find.bySemanticsLabel('Hidden hero portrait'), findsNothing);
    semantics.dispose();
  });

  testWidgets('AppSectionHeader renders expanded title and optional action', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        AppSectionHeader(
          title: 'Popular Builds',
          action: TextButton(onPressed: () {}, child: const Text('See all')),
        ),
      ),
    );

    expect(find.byType(Row), findsOneWidget);
    expect(find.widgetWithText(Expanded, 'Popular Builds'), findsOneWidget);
    expect(find.text('See all'), findsOneWidget);
  });
}
