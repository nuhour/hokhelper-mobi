import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hok_helper_mobile/src/app/global_edge_back_gesture.dart';

void main() {
  testWidgets('edge swipe pops the current route', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('Home')),
        ),
        GoRoute(
          path: '/detail',
          builder: (context, state) => const Scaffold(body: Text('Detail')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        builder: (context, child) => GlobalEdgeBackGesture(
          router: router,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    router.push('/detail');
    await tester.pumpAndSettle();

    await tester.dragFrom(const Offset(4, 300), const Offset(100, 0));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Detail'), findsNothing);
  });

  testWidgets('first root edge swipe arms exit without closing', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('Home')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        builder: (context, child) => GlobalEdgeBackGesture(
          router: router,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.dragFrom(const Offset(4, 300), const Offset(100, 0));
    await tester.pump();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Swipe right again to exit'), findsOneWidget);
  });
}
