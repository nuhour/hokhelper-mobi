import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hok_helper_mobile/src/app/hok_helper_app.dart';
import 'package:hok_helper_mobile/src/app/router.dart';

void main() {
  testWidgets('shows app shell with tab destinations', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(child: HokHelperApp(router: createAppRouter())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsAtLeastNWidgets(1));
    expect(find.text('Heroes'), findsOneWidget);
    expect(find.text('Content'), findsOneWidget);
    expect(find.text('Tools'), findsOneWidget);
    expect(find.text('Me'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
